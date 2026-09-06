// @ts-ignore
import JZZModule from "jzz";
// @ts-ignore
import synthTiny from "jzz-synth-tiny";
// @ts-ignore
import smf from "jzz-midi-smf";

const JZZ: any = JZZModule;

export interface TMDPlayerCallbacks {
  onStart?: (title: string, durationSec: number) => void;
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
        this.isPausedState = false;
        this.currentPlayer = null;
        if (this.callbacks.onEnd) {
          this.callbacks.onEnd();
        }
      };

      const durationMs = player.durationMS() || 0;
      this.currentPlayer = player;
      player.play();

      if (this.callbacks.onStart) {
        this.callbacks.onStart(title, durationMs / 1000);
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
