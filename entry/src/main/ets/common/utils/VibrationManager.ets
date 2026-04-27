import { vibrator } from '@kit.SensorServiceKit';
import Logger from './Logger';

/**
 * Utility for handling haptic feedback and vibrations on wearable devices.
 */
export class VibrationManager {
  private static instance: VibrationManager;

  private constructor() {}

  public static getInstance(): VibrationManager {
    if (!VibrationManager.instance) {
      VibrationManager.instance = new VibrationManager();
    }
    return VibrationManager.instance;
  }

  /**
   * Triggers a short vibration for button clicks.
   */
  public vibrateClick(): void {
    this.startVibration('haptic.clock.timer');
  }

  /**
   * Triggers a vibration for success actions.
   */
  public vibrateSuccess(): void {
    this.startVibration('haptic.success');
  }

  /**
   * Triggers a vibration for errors or warnings.
   */
  public vibrateError(): void {
    this.startVibration('haptic.fail');
  }

  private startVibration(effectId: string): void {
    try {
      vibrator.startVibration({
        type: 'preset',
        effectId: effectId,
        count: 1,
        intensity: 100,
      }, {
        usage: 'alarm'
      }, (error) => {
        if (error) {
          Logger.error(`Vibration failed: ${JSON.stringify(error)}`);
        }
      });
    } catch (err) {
      Logger.error(`Vibration exception: ${JSON.stringify(err)}`);
    }
  }
}

export default VibrationManager.getInstance();
