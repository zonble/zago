/**
 * SharedArrayBuffer ring buffer for synchronous, zero-CPU blocking stdin in Web Worker.
 */

const HEADER_INTS = 4; // [0: writePos, 1: readPos, 2: availableBytes, 3: lock]
const BUFFER_SIZE = 64 * 1024; // 64KB capacity

export class SharedStdin {
  public readonly sharedBuffer: SharedArrayBuffer;
  private readonly control: Int32Array;
  private readonly data: Uint8Array;

  constructor(sharedBuffer?: SharedArrayBuffer) {
    if (sharedBuffer) {
      this.sharedBuffer = sharedBuffer;
    } else {
      this.sharedBuffer = new SharedArrayBuffer(
        HEADER_INTS * 4 + BUFFER_SIZE
      );
    }

    this.control = new Int32Array(this.sharedBuffer, 0, HEADER_INTS);
    this.data = new Uint8Array(
      this.sharedBuffer,
      HEADER_INTS * 4,
      BUFFER_SIZE
    );
  }

  private lock() {
    while (Atomics.compareExchange(this.control, 3, 0, 1) !== 0) {
      Atomics.wait(this.control, 3, 1, 5);
    }
  }

  private unlock() {
    Atomics.store(this.control, 3, 0);
    Atomics.notify(this.control, 3, 1);
  }

  /**
   * Main thread: push text or raw bytes into the stdin ring buffer and wake worker.
   */
  public write(input: string | Uint8Array): number {
    const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
    if (bytes.length === 0) return 0;

    let written = 0;

    this.lock();
    try {
      const available = Math.max(0, Math.min(BUFFER_SIZE, this.control[2]));
      const capacity = BUFFER_SIZE - available;
      written = Math.min(bytes.length, capacity);
      if (written === 0) return 0;

      let writePos = this.control[0];
      for (let i = 0; i < written; i++) {
        this.data[writePos] = bytes[i];
        writePos = (writePos + 1) % BUFFER_SIZE;
      }
      this.control[0] = writePos;
      this.control[2] = available + written;
    } finally {
      this.unlock();
    }

    // Wake up Worker
    Atomics.notify(this.control, 2);
    return written;
  }

  /**
   * Reset ring buffer positions and byte count to 0.
   */
  public clear() {
    this.lock();
    try {
      this.control[0] = 0;
      this.control[1] = 0;
      this.control[2] = 0;
    } finally {
      this.unlock();
    }
  }

  /**
   * Worker thread: read stdin bytes with 50ms timeout to distinguish standalone ESC from escape sequences.
   */
  public read(maxBytes: number): Uint8Array {
    this.lock();
    try {
      const available = this.control[2];
      if (available > 0) {
        const toRead = Math.min(maxBytes, available);
        const result = new Uint8Array(toRead);
        let readPos = this.control[1];
        for (let i = 0; i < toRead; i++) {
          result[i] = this.data[readPos];
          readPos = (readPos + 1) % BUFFER_SIZE;
        }
        this.control[1] = readPos;
        this.control[2] -= toRead;
        return result;
      }
    } finally {
      this.unlock();
    }

    // Wait up to 50ms for new bytes
    Atomics.wait(this.control, 2, 0, 50);

    this.lock();
    try {
      const available = this.control[2];
      if (available > 0) {
        const toRead = Math.min(maxBytes, available);
        const result = new Uint8Array(toRead);
        let readPos = this.control[1];
        for (let i = 0; i < toRead; i++) {
          result[i] = this.data[readPos];
          readPos = (readPos + 1) % BUFFER_SIZE;
        }
        this.control[1] = readPos;
        this.control[2] -= toRead;
        return result;
      }
    } finally {
      this.unlock();
    }

    return new Uint8Array(0);
  }
}

/**
 * SharedArrayBuffer out-of-band channel for passing dropped files from main thread into worker VFS without polluting stdin.
 */
const FILE_CHANNEL_SIZE = 16 * 1024 * 1024; // 16MB buffer
const FILE_HEADER_INTS = 4; // [0: status (0=idle, 1=hasFile), 1: pathLength, 2: contentLength, 3: lock]

export class SharedFileChannel {
  public readonly sharedBuffer: SharedArrayBuffer;
  private readonly control: Int32Array;
  private readonly data: Uint8Array;

  constructor(sharedBuffer?: SharedArrayBuffer) {
    if (sharedBuffer) {
      this.sharedBuffer = sharedBuffer;
    } else {
      this.sharedBuffer = new SharedArrayBuffer(
        FILE_HEADER_INTS * 4 + FILE_CHANNEL_SIZE
      );
    }
    this.control = new Int32Array(this.sharedBuffer, 0, FILE_HEADER_INTS);
    this.data = new Uint8Array(
      this.sharedBuffer,
      FILE_HEADER_INTS * 4,
      FILE_CHANNEL_SIZE
    );
  }

  private lock() {
    while (Atomics.compareExchange(this.control, 3, 0, 1) !== 0) {
      Atomics.wait(this.control, 3, 1, 5);
    }
  }

  private unlock() {
    Atomics.store(this.control, 3, 0);
    Atomics.notify(this.control, 3, 1);
  }

  /**
   * Main thread: pushes a file to the channel.
   */
  public sendFile(path: string, content: Uint8Array): boolean {
    const pathBytes = new TextEncoder().encode(path);
    const totalNeeded = pathBytes.length + content.length;
    if (totalNeeded > FILE_CHANNEL_SIZE) {
      console.error("[SharedFileChannel] File too large for channel buffer");
      return false;
    }

    this.lock();
    try {
      this.control[1] = pathBytes.length;
      this.control[2] = content.length;

      this.data.set(pathBytes, 0);
      this.data.set(content, pathBytes.length);

      Atomics.store(this.control, 0, 1); // status = 1 (hasFile)
    } finally {
      this.unlock();
    }
    return true;
  }

  /**
   * Worker thread: pulls pending file if available.
   */
  public pullFile(): { path: string; content: Uint8Array } | null {
    if (Atomics.load(this.control, 0) !== 1) {
      return null;
    }

    this.lock();
    try {
      if (this.control[0] !== 1) return null;

      const pathLength = this.control[1];
      const contentLength = this.control[2];

      const pathBytes = new Uint8Array(pathLength);
      pathBytes.set(this.data.subarray(0, pathLength));
      const path = new TextDecoder("utf-8").decode(pathBytes);

      const content = new Uint8Array(contentLength);
      content.set(this.data.subarray(pathLength, pathLength + contentLength));

      this.control[0] = 0; // status = 0 (idle)
      this.control[1] = 0;
      this.control[2] = 0;

      return { path, content };
    } finally {
      this.unlock();
    }
  }
}
