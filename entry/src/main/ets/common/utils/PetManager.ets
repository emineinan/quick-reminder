import DatabaseManager from './DatabaseManager';
import Logger from './Logger';

/**
 * Logic for the Focus Buddy (Virtual Pet) evolution and state management.
 */
export class PetManager {
  private static instance: PetManager;
  private happiness: number = 100;
  private energy: number = 100;
  private readonly MAX_VALUE = 100;
  private readonly MIN_VALUE = 0;

  private constructor() {}

  public static getInstance(): PetManager {
    if (!PetManager.instance) {
      PetManager.instance = new PetManager();
    }
    return PetManager.instance;
  }

  /**
   * Syncs pet state from the database.
   */
  async syncFromDb(): Promise<void> {
    const status = await DatabaseManager.getPetStatus();
    if (status) {
      this.happiness = status.happiness;
      this.energy = status.energy;
      Logger.info(`Pet synced: happiness=${this.happiness}, energy=${this.energy}`);
    }
  }

  /**
   * Feed/Action that increases pet stats.
   */
  async completeReminder(): Promise<void> {
    this.happiness = Math.min(this.MAX_VALUE, this.happiness + 10);
    this.energy = Math.min(this.MAX_VALUE, this.energy + 5);
    await this.save();
  }

  /**
   * Action that decreases pet stats (e.g., ignoring work or time passing).
   */
  async ignoreReminder(): Promise<void> {
    this.happiness = Math.max(this.MIN_VALUE, this.happiness - 15);
    this.energy = Math.max(this.MIN_VALUE, this.energy - 10);
    await this.save();
  }

  private async save(): Promise<void> {
    await DatabaseManager.savePetStatus(this.happiness, this.energy);
  }

  getHappiness(): number {
    return this.happiness;
  }

  getEnergy(): number {
    return this.energy;
  }

  /**
   * Returns a status string based on the pet's levels.
   */
  getStatusKey(): Resource {
    if (this.happiness > 70 && this.energy > 50) {
      return $r('app.string.pet_happy');
    } else if (this.energy <= 50 && this.energy > 20) {
      return $r('app.string.pet_tired');
    } else {
      return $r('app.string.pet_hungry');
    }
  }
}

export default PetManager.getInstance();
