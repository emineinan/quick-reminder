import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import Logger from './Logger';

/**
 * Manager for RDB persistence to store pet status and app settings.
 */
export class DatabaseManager {
  private static instance: DatabaseManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'QuickReminder.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };

  private constructor() {}

  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /**
   * Initializes the RDB store and creates tables if they don't exist.
   */
  async init(context: common.Context): Promise<void> {
    if (this.rdbStore) return;

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, this.STORE_CONFIG);
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS PET_STATUS (' +
        'id INTEGER PRIMARY KEY, ' +
        'happiness INTEGER, ' +
        'energy INTEGER, ' +
        'last_updated INTEGER)'
      );
      Logger.info('Database initialized successfully');
    } catch (err) {
      Logger.error(`Failed to initialize database: ${JSON.stringify(err)}`);
    }
  }

  /**
   * Saves or updates the pet status.
   */
  async savePetStatus(happiness: number, energy: number): Promise<void> {
    if (!this.rdbStore) return;

    const valueBucket: relationalStore.ValuesBucket = {
      id: 1,
      happiness: happiness,
      energy: energy,
      last_updated: Date.now()
    };

    try {
      await this.rdbStore.insert('PET_STATUS', valueBucket, relationalStore.ConflictResolution.REPLACE);
      Logger.info('Pet status saved');
    } catch (err) {
      Logger.error(`Failed to save pet status: ${JSON.stringify(err)}`);
    }
  }

  /**
   * Retrieves the pet status.
   */
  async getPetStatus(): Promise<{ happiness: number, energy: number } | null> {
    if (!this.rdbStore) return null;

    let predicates = new relationalStore.RdbPredicates('PET_STATUS');
    predicates.equalTo('id', 1);

    try {
      const resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        const happiness = resultSet.getLong(resultSet.getColumnIndex('happiness'));
        const energy = resultSet.getLong(resultSet.getColumnIndex('energy'));
        resultSet.close();
        return { happiness, energy };
      }
      resultSet.close();
    } catch (err) {
      Logger.error(`Failed to get pet status: ${JSON.stringify(err)}`);
    }
    return null;
  }
}

export default DatabaseManager.getInstance();
