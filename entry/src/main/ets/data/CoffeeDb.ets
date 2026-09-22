import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CoffeeBean, Equipment, BrewRecord } from '../model/Models';

const TAG: string = 'CoffeeDb';

export class CoffeeDb {
  private static instance: CoffeeDb | undefined = undefined;
  private db: relationalStore.RdbStore | undefined = undefined;
  private initTask: Promise<void> | undefined = undefined;

  static getInstance(): CoffeeDb {
    if (CoffeeDb.instance === undefined) {
      CoffeeDb.instance = new CoffeeDb();
    }
    return CoffeeDb.instance;
  }

  init(context: common.UIAbilityContext): Promise<void> {
    if (this.initTask !== undefined) {
      return this.initTask;
    }
    this.initTask = new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const config: relationalStore.StoreConfig = {
        name: 'coffee.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
      relationalStore.getRdbStore(context, config).then((store: relationalStore.RdbStore) => {
        this.db = store;
        const ddl: string[] = [
          `CREATE TABLE IF NOT EXISTS coffee_beans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL DEFAULT '',
            variety TEXT NOT NULL DEFAULT '',
            purchase_date INTEGER NOT NULL DEFAULT 0,
            price REAL NOT NULL DEFAULT 0,
            vendor TEXT NOT NULL DEFAULT '',
            flavor_tags TEXT NOT NULL DEFAULT '',
            origin TEXT NOT NULL DEFAULT '',
            weight REAL NOT NULL DEFAULT 0,
            roast_level TEXT NOT NULL DEFAULT '',
            roast_date INTEGER NOT NULL DEFAULT 0,
            process_method TEXT NOT NULL DEFAULT '',
            shelf_life INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL DEFAULT 0)`,
          `CREATE TABLE IF NOT EXISTS equipments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL DEFAULT '',
            brand TEXT NOT NULL DEFAULT '',
            model TEXT NOT NULL DEFAULT '',
            purchase_date INTEGER NOT NULL DEFAULT 0,
            price REAL NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT '',
            accessories TEXT NOT NULL DEFAULT '',
            condition_state TEXT NOT NULL DEFAULT '',
            created_at INTEGER NOT NULL DEFAULT 0)`,
          `CREATE TABLE IF NOT EXISTS brew_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            brew_date INTEGER NOT NULL DEFAULT 0,
            method TEXT NOT NULL DEFAULT '',
            bean_id INTEGER NOT NULL DEFAULT -1,
            bean_name TEXT NOT NULL DEFAULT '',
            dose REAL NOT NULL DEFAULT 0,
            water_amount REAL NOT NULL DEFAULT 0,
            water_temp REAL NOT NULL DEFAULT 0,
            grind_size TEXT NOT NULL DEFAULT '',
            brew_duration INTEGER NOT NULL DEFAULT 0,
            rating INTEGER NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT '',
            extra TEXT NOT NULL DEFAULT '',
            created_at INTEGER NOT NULL DEFAULT 0)`
        ];
        // 旧版本升级迁移：列已存在时 ALTER 会报错，逐条容忍失败
        const migrations: string[] = [
          `ALTER TABLE coffee_beans ADD COLUMN origin TEXT NOT NULL DEFAULT ''`,
          `ALTER TABLE coffee_beans ADD COLUMN weight REAL NOT NULL DEFAULT 0`,
          `ALTER TABLE coffee_beans ADD COLUMN roast_level TEXT NOT NULL DEFAULT ''`,
          `ALTER TABLE coffee_beans ADD COLUMN roast_date INTEGER NOT NULL DEFAULT 0`,
          `ALTER TABLE coffee_beans ADD COLUMN process_method TEXT NOT NULL DEFAULT ''`,
          `ALTER TABLE coffee_beans ADD COLUMN shelf_life INTEGER NOT NULL DEFAULT 0`,
          `ALTER TABLE equipments ADD COLUMN accessories TEXT NOT NULL DEFAULT ''`,
          `ALTER TABLE equipments ADD COLUMN condition_state TEXT NOT NULL DEFAULT ''`,
          `ALTER TABLE brew_records ADD COLUMN extra TEXT NOT NULL DEFAULT ''`
        ];
        const tasks: Array<Promise<void>> = [];
        for (let i = 0; i < ddl.length; i++) {
          tasks.push(store.executeSql(ddl[i]));
        }
        for (let i = 0; i < migrations.length; i++) {
          const m: string = migrations[i];
          tasks.push(store.executeSql(m).then((): void => {
          }).catch((e: BusinessError): void => {
            console.info(`${TAG} migration skipped: ${e.message}`);
          }));
        }
        Promise.all(tasks).then(() => {
          resolve();
        }).catch((e: BusinessError) => {
          console.error(`${TAG} init ddl failed: ${e.code} ${e.message}`);
          reject(new Error(`init ddl failed: ${e.code}`));
        });
      }).catch((e: BusinessError) => {
        console.error(`${TAG} getRdbStore failed: ${e.code} ${e.message}`);
        reject(new Error(`getRdbStore failed: ${e.code}`));
      });
    });
    return this.initTask;
  }

  private async ensureDb(): Promise<relationalStore.RdbStore> {
    if (this.initTask !== undefined) {
      await this.initTask;
    }
    if (this.db === undefined) {
      throw new Error('db not initialized');
    }
    return this.db;
  }

  // ---------- CoffeeBean ----------

  async addBean(b: CoffeeBean): Promise<number> {
    const db = await this.ensureDb();
    const v: relationalStore.ValuesBucket = {
      'name': b.name,
      'variety': b.variety,
      'purchase_date': b.purchaseDate,
      'price': b.price,
      'vendor': b.vendor,
      'flavor_tags': b.flavorTags,
      'origin': b.origin,
      'weight': b.weight,
      'roast_level': b.roastLevel,
      'roast_date': b.roastDate,
      'process_method': b.processMethod,
      'shelf_life': b.shelfLife,
      'created_at': Date.now()
    };
    return db.insert('coffee_beans', v);
  }

  async updateBean(b: CoffeeBean): Promise<number> {
    const db = await this.ensureDb();
    const v: relationalStore.ValuesBucket = {
      'name': b.name,
      'variety': b.variety,
      'purchase_date': b.purchaseDate,
      'price': b.price,
      'vendor': b.vendor,
      'flavor_tags': b.flavorTags,
      'origin': b.origin,
      'weight': b.weight,
      'roast_level': b.roastLevel,
      'roast_date': b.roastDate,
      'process_method': b.processMethod,
      'shelf_life': b.shelfLife
    };
    const pred = new relationalStore.RdbPredicates('coffee_beans').equalTo('id', b.id);
    return db.update(v, pred);
  }

  async deleteBean(id: number): Promise<number> {
    const db = await this.ensureDb();
    const pred = new relationalStore.RdbPredicates('coffee_beans').equalTo('id', id);
    return db.delete(pred);
  }

  async queryBeans(): Promise<CoffeeBean[]> {
    const db = await this.ensureDb();
    const pred = new relationalStore.RdbPredicates('coffee_beans').orderByDesc('purchase_date');
    const rs = await db.query(pred);
    const result: CoffeeBean[] = [];
    while (rs.goToNextRow()) {
      const b = new CoffeeBean();
      b.id = rs.getLong(rs.getColumnIndex('id'));
      b.name = rs.getString(rs.getColumnIndex('name'));
      b.variety = rs.getString(rs.getColumnIndex('variety'));
      b.purchaseDate = rs.getLong(rs.getColumnIndex('purchase_date'));
      b.price = rs.getDouble(rs.getColumnIndex('price'));
      b.vendor = rs.getString(rs.getColumnIndex('vendor'));
      b.flavorTags = rs.getString(rs.getColumnIndex('flavor_tags'));
      b.origin = rs.getString(rs.getColumnIndex('origin'));
      b.weight = rs.getDouble(rs.getColumnIndex('weight'));
      b.roastLevel = rs.getString(rs.getColumnIndex('roast_level'));
      b.roastDate = rs.getLong(rs.getColumnIndex('roast_date'));
      b.processMethod = rs.getString(rs.getColumnIndex('process_method'));
      b.shelfLife = rs.getLong(rs.getColumnIndex('shelf_life'));
      b.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
      result.push(b);
    }
    rs.close();
    return result;
  }

  // ---------- Equipment ----------

  async addEquipment(e: Equipment): Promise<number> {
    const db = await this.ensureDb();
    const v: relationalStore.ValuesBucket = {
      'type': e.type,
      'brand': e.brand,
      'model': e.model,
      'purchase_date': e.purchaseDate,
      'price': e.price,
      'notes': e.notes,
      'accessories': e.accessories,
      'condition_state': e.conditionState,
      'created_at': Date.now()
    };
    return db.insert('equipments', v);
  }

  async updateEquipment(e: Equipment): Promise<number> {
    const db = await this.ensureDb();
    const v: relationalStore.ValuesBucket = {
      'type': e.type,
      'brand': e.brand,
      'model': e.model,
      'purchase_date': e.purchaseDate,
      'price': e.price,
      'notes': e.notes,
      'accessories': e.accessories,
      'condition_state': e.conditionState
    };
    const pred = new relationalStore.RdbPredicates('equipments').equalTo('id', e.id);
    return db.update(v, pred);
  }

  async deleteEquipment(id: number): Promise<number> {
    const db = await this.ensureDb();
    const pred = new relationalStore.RdbPredicates('equipments').equalTo('id', id);
    return db.delete(pred);
  }

  async queryEquipments(): Promise<Equipment[]> {
    const db = await this.ensureDb();
    const pred = new relationalStore.RdbPredicates('equipments').orderByDesc('purchase_date');
    const rs = await db.query(pred);
    const result: Equipment[] = [];
    while (rs.goToNextRow()) {
      const e = new Equipment();
      e.id = rs.getLong(rs.getColumnIndex('id'));
      e.type = rs.getString(rs.getColumnIndex('type'));
      e.brand = rs.getString(rs.getColumnIndex('brand'));
      e.model = rs.getString(rs.getColumnIndex('model'));
      e.purchaseDate = rs.getLong(rs.getColumnIndex('purchase_date'));
      e.price = rs.getDouble(rs.getColumnIndex('price'));
      e.notes = rs.getString(rs.getColumnIndex('notes'));
      e.accessories = rs.getString(rs.getColumnIndex('accessories'));
      e.conditionState = rs.getString(rs.getColumnIndex('condition_state'));
      e.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
      result.push(e);
    }
    rs.close();
    return result;
  }

  // ---------- BrewRecord ----------

  async addBrew(r: BrewRecord): Promise<number> {
    const db = await this.ensureDb();
    const v: relationalStore.ValuesBucket = {
      'brew_date': r.brewDate,
      'method': r.method,
      'bean_id': r.beanId,
      'bean_name': r.beanName,
      'dose': r.dose,
      'water_amount': r.waterAmount,
      'water_temp': r.waterTemp,
      'grind_size': r.grindSize,
      'brew_duration': r.brewDuration,
      'rating': r.rating,
      'notes': r.notes,
      'extra': r.toExtraJson(),
      'created_at': Date.now()
    };
    return db.insert('brew_records', v);
  }

  async updateBrew(r: BrewRecord): Promise<number> {
    const db = await this.ensureDb();
    const v: relationalStore.ValuesBucket = {
      'brew_date': r.brewDate,
      'method': r.method,
      'bean_id': r.beanId,
      'bean_name': r.beanName,
      'dose': r.dose,
      'water_amount': r.waterAmount,
      'water_temp': r.waterTemp,
      'grind_size': r.grindSize,
      'brew_duration': r.brewDuration,
      'rating': r.rating,
      'notes': r.notes,
      'extra': r.toExtraJson()
    };
    const pred = new relationalStore.RdbPredicates('brew_records').equalTo('id', r.id);
    return db.update(v, pred);
  }

  async deleteBrew(id: number): Promise<number> {
    const db = await this.ensureDb();
    const pred = new relationalStore.RdbPredicates('brew_records').equalTo('id', id);
    return db.delete(pred);
  }

  async queryBrews(): Promise<BrewRecord[]> {
    const db = await this.ensureDb();
    const pred = new relationalStore.RdbPredicates('brew_records').orderByDesc('brew_date');
    const rs = await db.query(pred);
    const result: BrewRecord[] = [];
    while (rs.goToNextRow()) {
      const r = new BrewRecord();
      r.id = rs.getLong(rs.getColumnIndex('id'));
      r.brewDate = rs.getLong(rs.getColumnIndex('brew_date'));
      r.method = rs.getString(rs.getColumnIndex('method'));
      r.beanId = rs.getLong(rs.getColumnIndex('bean_id'));
      r.beanName = rs.getString(rs.getColumnIndex('bean_name'));
      r.dose = rs.getDouble(rs.getColumnIndex('dose'));
      r.waterAmount = rs.getDouble(rs.getColumnIndex('water_amount'));
      r.waterTemp = rs.getDouble(rs.getColumnIndex('water_temp'));
      r.grindSize = rs.getString(rs.getColumnIndex('grind_size'));
      r.brewDuration = rs.getLong(rs.getColumnIndex('brew_duration'));
      r.rating = rs.getLong(rs.getColumnIndex('rating'));
      r.notes = rs.getString(rs.getColumnIndex('notes'));
      r.applyExtraJson(rs.getString(rs.getColumnIndex('extra')));
      r.createdAt = rs.getLong(rs.getColumnIndex('created_at'));
      result.push(r);
    }
    rs.close();
    return result;
  }

  // ---------- 清空数据 ----------

  async clearAll(): Promise<void> {
    const db = await this.ensureDb();
    await db.delete(new relationalStore.RdbPredicates('brew_records'));
    await db.delete(new relationalStore.RdbPredicates('equipments'));
    await db.delete(new relationalStore.RdbPredicates('coffee_beans'));
  }

  // ---------- 导入还原（事务：失败自动回滚） ----------

  async restoreAll(beans: CoffeeBean[], equipments: Equipment[], brews: BrewRecord[]): Promise<void> {
    const db = await this.ensureDb();
    db.beginTransaction();
    try {
      await db.delete(new relationalStore.RdbPredicates('brew_records'));
      await db.delete(new relationalStore.RdbPredicates('equipments'));
      await db.delete(new relationalStore.RdbPredicates('coffee_beans'));
      for (let i = 0; i < beans.length; i++) {
        const b: CoffeeBean = beans[i];
        const v: relationalStore.ValuesBucket = {
          'id': b.id,
          'name': b.name,
          'variety': b.variety,
          'purchase_date': b.purchaseDate,
          'price': b.price,
          'vendor': b.vendor,
          'flavor_tags': b.flavorTags,
          'origin': b.origin,
          'weight': b.weight,
          'roast_level': b.roastLevel,
          'roast_date': b.roastDate,
          'process_method': b.processMethod,
          'shelf_life': b.shelfLife,
          'created_at': b.createdAt > 0 ? b.createdAt : Date.now()
        };
        await db.insert('coffee_beans', v);
      }
      for (let i = 0; i < equipments.length; i++) {
        const e: Equipment = equipments[i];
        const v: relationalStore.ValuesBucket = {
          'id': e.id,
          'type': e.type,
          'brand': e.brand,
          'model': e.model,
          'purchase_date': e.purchaseDate,
          'price': e.price,
          'notes': e.notes,
          'accessories': e.accessories,
          'condition_state': e.conditionState,
          'created_at': e.createdAt > 0 ? e.createdAt : Date.now()
        };
        await db.insert('equipments', v);
      }
      for (let i = 0; i < brews.length; i++) {
        const r: BrewRecord = brews[i];
        const v: relationalStore.ValuesBucket = {
          'id': r.id,
          'brew_date': r.brewDate,
          'method': r.method,
          'bean_id': r.beanId,
          'bean_name': r.beanName,
          'dose': r.dose,
          'water_amount': r.waterAmount,
          'water_temp': r.waterTemp,
          'grind_size': r.grindSize,
          'brew_duration': r.brewDuration,
          'rating': r.rating,
          'notes': r.notes,
          'extra': r.toExtraJson(),
          'created_at': r.createdAt > 0 ? r.createdAt : Date.now()
        };
        await db.insert('brew_records', v);
      }
      db.commit();
    } catch (e) {
      db.rollBack();
      console.error(`${TAG} restoreAll failed: ${(e as BusinessError).code} ${(e as BusinessError).message}`);
      throw new Error('restoreAll failed');
    }
  }
}
