// @ts-ignore
import JZZModule from "jzz";
// @ts-ignore
import synthTiny from "jzz-synth-tiny";
// @ts-ignore
import smf from "jzz-midi-smf";

const JZZ: any = JZZModule;

export interface TMDPlayerCallbacks {
  onStart?: (title: string, durationSec: number) => void;
  onProgress?: (currentSec: number, totalSec: number) => void;
  onPause?: () => void;
  onResume?: () => void;
  onStop?: () => void;
  onEnd?: () => void;
}

export class TMDMidiPlayer {
  private synth: any = null;
  private currentPlayer: any = null;
  private currentTitle: string = "";
  private callbacks: TMDPlayerCallbacks = {};
  private isPausedState: boolean = false;
  private progressTimer: any = null;

  constructor() {
    try {
      synthTiny(JZZ);
      smf(JZZ);
      JZZ();
      this.synth = JZZ.synth.Tiny();
    } catch (err) {
      console.warn("[TMDMidiPlayer] Initialization error:", err);
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

  public play(bytes: Uint8Array, title: string, callbacks?: TMDPlayerCallbacks) {
    this.stop();
    this.callbacks = callbacks || {};
    this.currentTitle = title;
    this.isPausedState = false;

    try {
      if (this.synth && typeof this.synth.resume === "function") {
        this.synth.resume();
      }

      const smfData = new JZZ.MIDI.SMF(bytes);
      const player = smfData.player();
      player.connect(this.synth);

      player.onEnd = () => {
        this.stopProgressTimer();
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

  public stop() {
    this.stopProgressTimer();
    if (this.currentPlayer) {
      try {
        this.currentPlayer.stop();
      } catch (_) {}
      this.currentPlayer = null;
    }
    this.isPausedState = false;
    if (this.callbacks.onStop) {
      this.callbacks.onStop();
    }
  }
}

export const tmdPlayer = new TMDMidiPlayer();
