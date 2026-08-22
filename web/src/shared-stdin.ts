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
  public write(input: string | Uint8Array) {
    const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
    if (bytes.length === 0) return;

    this.lock();
    try {
      let writePos = this.control[0];
      for (let i = 0; i < bytes.length; i++) {
        this.data[writePos] = bytes[i];
        writePos = (writePos + 1) % BUFFER_SIZE;
      }
      this.control[0] = writePos;
      this.control[2] += bytes.length;
    } finally {
      this.unlock();
    }

    // Wake up Worker
    Atomics.notify(this.control, 2);
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
