import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import Logger from './Logger';

/**
 * Manager for RDB persistence to store application settings and reminder history.
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
      // We keep the table structure for consistency, but focus on general settings/history
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS APP_SETTINGS (' +
        'key TEXT PRIMARY KEY, ' +
        'value TEXT)'
      );
      Logger.info('Database initialized successfully');
    } catch (err) {
      Logger.error(`Failed to initialize database: ${JSON.stringify(err)}`);
    }
  }

  /**
   * Saves a setting to the database.
   */
  async saveSetting(key: string, value: string): Promise<void> {
    if (!this.rdbStore) return;

    const valueBucket: relationalStore.ValuesBucket = {
      key: key,
      value: value
    };

    try {
      // Fixed: Use ON_CONFLICT_REPLACE as per modern HarmonyOS RDB API
      await this.rdbStore.insert('APP_SETTINGS', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      Logger.info(`Setting ${key} saved`);
    } catch (err) {
      Logger.error(`Failed to save setting: ${JSON.stringify(err)}`);
    }
  }

  /**
   * Retrieves a setting from the database.
   */
  async getSetting(key: string): Promise<string | null> {
    if (!this.rdbStore) return null;

    let predicates = new relationalStore.RdbPredicates('APP_SETTINGS');
    predicates.equalTo('key', key);

    try {
      const resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        const value = resultSet.getString(resultSet.getColumnIndex('value'));
        resultSet.close();
        return value;
      }
      resultSet.close();
    } catch (err) {
      Logger.error(`Failed to get setting: ${JSON.stringify(err)}`);
    }
    return null;
  }
}

export default DatabaseManager.getInstance();
