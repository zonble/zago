// @ts-ignore
import JZZModule from "jzz";
// @ts-ignore
import synthTiny from "jzz-synth-tiny";
// @ts-ignore
import smf from "jzz-midi-smf";
// @ts-ignore
import Soundfont from "soundfont-player";

const JZZ: any = JZZModule;

export type TMDMidiSynthType = "piano" | "tiny" | "webmidi";

export interface TMDPlayerCallbacks {
  onStart?: (title: string, durationSec: number) => void;
  onProgress?: (currentSec: number, totalSec: number) => void;
  onPause?: () => void;
  onResume?: () => void;
  onStop?: () => void;
  onEnd?: () => void;
  onLoadingStatus?: (statusText: string | null) => void;
}

export class TMDMidiPlayer {
  private tinySynth: any = null;
  private pianoInstrument: any = null;
  private pianoLoadingPromise: Promise<any> | null = null;
  private soundfontWidget: any = null;
  private webMidiPort: any = null;
  private audioContext: AudioContext | null = null;

  private currentSynthType: TMDMidiSynthType = "piano";
  private currentPlayer: any = null;
  private currentTitle: string = "";
  private currentBytes: Uint8Array | null = null;
  private callbacks: TMDPlayerCallbacks = {};
  private isPausedState: boolean = false;
  private progressTimer: any = null;

  // Track active notes for soundfont note-off
  private activeNotes: Map<number, any> = new Map();

  constructor() {
    try {
      synthTiny(JZZ);
      smf(JZZ);
      JZZ();
      this.tinySynth = JZZ.synth.Tiny();
    } catch (err) {
      console.warn("[TMDMidiPlayer] JZZ initialization error:", err);
    }

    // Load saved synth preference
    const savedSynth = localStorage.getItem("zago-tmd-synth") as TMDMidiSynthType | null;
    if (savedSynth && ["piano", "tiny", "webmidi"].includes(savedSynth)) {
      this.currentSynthType = savedSynth;
    }
  }

  private getAudioContext(): AudioContext | null {
    if (!this.audioContext) {
      try {
        if (typeof JZZ.lib?.getAudioContext === "function") {
          this.audioContext = JZZ.lib.getAudioContext();
        }
      } catch (_) {}
      if (!this.audioContext && typeof AudioContext !== "undefined") {
        this.audioContext = new AudioContext();
      }
    }
    return this.audioContext;
  }

  public getSynthType(): TMDMidiSynthType {
    return this.currentSynthType;
  }

  public async setSynthType(type: TMDMidiSynthType): Promise<void> {
    if (this.currentSynthType === type) return;
    this.currentSynthType = type;
    localStorage.setItem("zago-tmd-synth", type);

    // If currently playing, restart playback at current position with new synth
    if (this.isPlaying() && this.currentBytes) {
      const currentPos = this.getPosition();
      const title = this.currentTitle;
      const bytes = this.currentBytes;
      const cbs = { ...this.callbacks };
      const wasPaused = this.isPausedState;

      this.stop(false);
      this.play(bytes, title, cbs);
      if (currentPos > 0) {
        this.seek(currentPos);
      }
      if (wasPaused) {
        this.pause();
      }
    }
  }

  public isPlaying(): boolean {
    return !!(this.currentPlayer && (this.currentPlayer.playing || this.isPausedState));
  }

  public isPaused(): boolean {
    return this.isPausedState;
  }

  public getTitle(): string {
    return this.currentTitle;
  }

  public getDuration(): number {
    if (!this.currentPlayer) return 0;
    try {
      return (this.currentPlayer.durationMS() || 0) / 1000;
    } catch {
      return 0;
    }
  }

  public getPosition(): number {
    if (!this.currentPlayer) return 0;
    try {
      return (this.currentPlayer.positionMS() || 0) / 1000;
    } catch {
      return 0;
    }
  }

  public seek(seconds: number) {
    if (!this.currentPlayer) return;
    try {
      this.stopActiveNotes();
      const ms = Math.max(0, seconds * 1000);
      this.currentPlayer.jumpMS(ms);
      if (this.callbacks.onProgress) {
        this.callbacks.onProgress(this.getPosition(), this.getDuration());
      }
    } catch (err) {
      console.warn("[TMDMidiPlayer] Seek failed:", err);
    }
  }

  private startProgressTimer() {
    this.stopProgressTimer();
    this.progressTimer = setInterval(() => {
      if (this.currentPlayer && !this.isPausedState && this.callbacks.onProgress) {
        this.callbacks.onProgress(this.getPosition(), this.getDuration());
      }
    }, 150);
  }

  private stopProgressTimer() {
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }

  private stopActiveNotes() {
    for (const [_, node] of this.activeNotes) {
      try {
        if (node && typeof node.stop === "function") {
          node.stop();
        }
      } catch (_) {}
    }
    this.activeNotes.clear();
  }

  private async loadPianoInstrument(): Promise<any> {
    if (this.pianoInstrument) return this.pianoInstrument;
    if (this.pianoLoadingPromise) return this.pianoLoadingPromise;

    const ctx = this.getAudioContext();
    if (!ctx) throw new Error("AudioContext not available");

    this.callbacks.onLoadingStatus?.("Loading Piano SoundFont...");
    this.pianoLoadingPromise = (async () => {
      try {
        const inst = await Soundfont.instrument(ctx, "acoustic_grand_piano", {
          soundfont: "FluidR3_GM",
          format: "mp3",
        });
        this.pianoInstrument = inst;
        this.callbacks.onLoadingStatus?.(null);
        return inst;
      } catch (err) {
        console.warn("[TMDMidiPlayer] Soundfont load error, falling back to Tiny:", err);
        this.callbacks.onLoadingStatus?.(null);
        return null;
      } finally {
        this.pianoLoadingPromise = null;
      }
    })();

    return this.pianoLoadingPromise;
  }

  private createSoundfontWidget(): any {
    if (this.soundfontWidget) return this.soundfontWidget;

    const self = this;
    this.soundfontWidget = JZZ.Widget({
      _receive: function (msg: any) {
        self.handleMidiMessageForSoundfont(msg);
      },
    });
    return this.soundfontWidget;
  }

  private handleMidiMessageForSoundfont(msg: any) {
    if (!msg || msg.length < 1) return;
    const status = msg[0] & 0xf0;
    const channel = msg[0] & 0x0f;
    const note = msg[1];
    const velocity = msg[2] || 0;

    const inst = this.pianoInstrument;
    if (!inst) return;

    if (status === 0x90 && velocity > 0) {
      // Note On
      const key = (channel << 8) | note;
      const oldNode = this.activeNotes.get(key);
      if (oldNode) {
        try { oldNode.stop(); } catch (_) {}
      }

      const gain = Math.max(0.1, Math.min(1.0, velocity / 127));
      try {
        const node = inst.play(note, undefined, { gain });
        if (node) {
          this.activeNotes.set(key, node);
        }
      } catch (err) {
        console.warn("[TMDMidiPlayer] Soundfont play error:", err);
      }
    } else if (status === 0x80 || (status === 0x90 && velocity === 0)) {
      // Note Off
      const key = (channel << 8) | note;
      const node = this.activeNotes.get(key);
      if (node) {
        try {
          if (typeof node.stop === "function") {
            node.stop();
          }
        } catch (_) {}
        this.activeNotes.delete(key);
      }
    } else if (status === 0xb0 && (msg[1] === 120 || msg[1] === 123)) {
      // All Sound Off / All Notes Off
      this.stopActiveNotes();
    }
  }

  public async play(bytes: Uint8Array, title: string, callbacks?: TMDPlayerCallbacks) {
    this.stop(false);
    this.callbacks = callbacks || {};
    this.currentTitle = title;
    this.currentBytes = bytes;
    this.isPausedState = false;

    const ctx = this.getAudioContext();
    if (ctx && typeof ctx.resume === "function" && ctx.state === "suspended") {
      try { await ctx.resume(); } catch (_) {}
    }

    try {
      const smfData = new JZZ.MIDI.SMF(bytes);
      const player = smfData.player();

      // Route to destination synth based on current selection
      if (this.currentSynthType === "piano") {
        const piano = await this.loadPianoInstrument();
        if (piano) {
          const widget = this.createSoundfontWidget();
          player.connect(widget);
        } else {
          // Fallback to Tiny Synth if piano failed to load
          player.connect(this.tinySynth);
        }
      } else if (this.currentSynthType === "webmidi") {
        let connectedToHardware = false;
        try {
          if (!this.webMidiPort) {
            this.webMidiPort = await JZZ().openMidiOut();
          }
          if (this.webMidiPort) {
            player.connect(this.webMidiPort);
            connectedToHardware = true;
          }
        } catch (midiErr) {
          console.warn("[TMDMidiPlayer] Web MIDI open failed, fallback to Tiny Synth:", midiErr);
        }
        if (!connectedToHardware) {
          player.connect(this.tinySynth);
        }
      } else {
        // tiny synth
        if (this.tinySynth && typeof this.tinySynth.resume === "function") {
          this.tinySynth.resume();
        }
        player.connect(this.tinySynth);
      }

      player.onEnd = () => {
        this.stopProgressTimer();
        this.stopActiveNotes();
        this.isPausedState = false;
        this.currentPlayer = null;
        if (this.callbacks.onEnd) {
          this.callbacks.onEnd();
        }
      };

      const durationMs = player.durationMS() || 0;
      this.currentPlayer = player;
      player.play();
      this.startProgressTimer();

      if (this.callbacks.onStart) {
        this.callbacks.onStart(title, durationMs / 1000);
      }
      if (this.callbacks.onProgress) {
        this.callbacks.onProgress(0, durationMs / 1000);
      }
    } catch (err) {
      console.error("[TMDMidiPlayer] Failed to play MIDI:", err);
      this.stop();
    }
  }

  public pause() {
    if (this.currentPlayer && !this.isPausedState) {
      try {
        this.currentPlayer.pause();
        this.isPausedState = true;
        this.stopProgressTimer();
        this.stopActiveNotes();
        if (this.callbacks.onPause) {
          this.callbacks.onPause();
        }
      } catch (err) {
        console.warn("[TMDMidiPlayer] Pause failed:", err);
      }
    }
  }

  public resume() {
    if (this.currentPlayer && this.isPausedState) {
      try {
        this.currentPlayer.resume();
        this.isPausedState = false;
        this.startProgressTimer();
        if (this.callbacks.onResume) {
          this.callbacks.onResume();
        }
      } catch (err) {
        console.warn("[TMDMidiPlayer] Resume failed:", err);
      }
    }
  }

  public togglePause() {
    if (this.isPausedState) {
      this.resume();
    } else {
      this.pause();
    }
  }

  public stop(notifyCallback: boolean = true) {
    this.stopProgressTimer();
    this.stopActiveNotes();
    if (this.currentPlayer) {
      try {
        this.currentPlayer.stop();
      } catch (_) {}
      this.currentPlayer = null;
    }
    this.isPausedState = false;
    if (notifyCallback && this.callbacks.onStop) {
      this.callbacks.onStop();
    }
  }
}

export const tmdPlayer = new TMDMidiPlayer();
