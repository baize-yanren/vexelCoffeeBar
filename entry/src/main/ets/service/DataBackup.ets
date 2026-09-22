import { picker, fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CoffeeBean, Equipment, BrewRecord } from '../model/Models';
import { CoffeeDb } from '../data/CoffeeDb';
import { DateUtil } from '../common/DateUtil';

const TAG: string = 'DataBackup';

export class BackupData {
  beans: CoffeeBean[] = [];
  equipments: Equipment[] = [];
  brews: BrewRecord[] = [];
}

export class DataBackup {
  private static numOf(o: Record<string, Object>, key: string): number {
    const v: Object | undefined = o[key];
    return v === undefined ? 0 : Number(`${v}`);
  }

  private static strOf(o: Record<string, Object>, key: string): string {
    const v: Object | undefined = o[key];
    return v === undefined ? '' : `${v}`;
  }

  // ---------- 导出 ----------

  static async exportToFile(context: common.UIAbilityContext): Promise<string> {
    const db: CoffeeDb = CoffeeDb.getInstance();
    const beans: CoffeeBean[] = await db.queryBeans();
    const equipments: Equipment[] = await db.queryEquipments();
    const brews: BrewRecord[] = await db.queryBrews();

    const beanArr: Record<string, Object>[] = [];
    for (let i = 0; i < beans.length; i++) {
      const b: CoffeeBean = beans[i];
      beanArr.push({
        'id': b.id,
        'name': b.name,
        'variety': b.variety,
        'purchaseDate': b.purchaseDate,
        'price': b.price,
        'vendor': b.vendor,
        'flavorTags': b.flavorTags,
        'origin': b.origin,
        'weight': b.weight,
        'roastLevel': b.roastLevel,
        'roastDate': b.roastDate,
        'processMethod': b.processMethod,
        'shelfLife': b.shelfLife,
        'createdAt': b.createdAt
      });
    }

    const equipArr: Record<string, Object>[] = [];
    for (let i = 0; i < equipments.length; i++) {
      const e: Equipment = equipments[i];
      equipArr.push({
        'id': e.id,
        'type': e.type,
        'brand': e.brand,
        'model': e.model,
        'purchaseDate': e.purchaseDate,
        'price': e.price,
        'notes': e.notes,
        'accessories': e.accessories,
        'conditionState': e.conditionState,
        'createdAt': e.createdAt
      });
    }

    const brewArr: Record<string, Object>[] = [];
    for (let i = 0; i < brews.length; i++) {
      const r: BrewRecord = brews[i];
      brewArr.push({
        'id': r.id,
        'brewDate': r.brewDate,
        'method': r.method,
        'beanId': r.beanId,
        'beanName': r.beanName,
        'dose': r.dose,
        'waterAmount': r.waterAmount,
        'waterTemp': r.waterTemp,
        'grindSize': r.grindSize,
        'brewDuration': r.brewDuration,
        'rating': r.rating,
        'notes': r.notes,
        'extra': r.toExtraJson(),
        'createdAt': r.createdAt
      });
    }

    const root: Record<string, Object> = {
      'app': 'Vexel Coffee Bar',
      'format': 1,
      'exportedAt': Date.now(),
      'beans': beanArr,
      'equipments': equipArr,
      'brews': brewArr
    };
    const json: string = JSON.stringify(root);

    const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    options.newFileNames = [`vexel_coffee_backup_${DateUtil.formatDate(Date.now())}.json`];
    const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    let uris: string[] = [];
    try {
      uris = await docPicker.save(options);
    } catch (e) {
      console.info(`${TAG} save picker cancelled: ${(e as BusinessError).code}`);
      return 'cancelled';
    }
    if (uris.length === 0) {
      return 'cancelled';
    }
    let file: fs.File | undefined = undefined;
    try {
      file = fs.openSync(uris[0], fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, json);
      return 'ok';
    } catch (e) {
      console.error(`${TAG} write failed: ${(e as BusinessError).code} ${(e as BusinessError).message}`);
      return 'failed';
    } finally {
      if (file !== undefined) {
        fs.closeSync(file);
      }
    }
  }

  // ---------- 导入 ----------

  static async importFromFile(context: common.UIAbilityContext): Promise<BackupData | undefined> {
    const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    options.fileSuffixFilters = ['json'];
    const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    let uris: string[] = [];
    try {
      uris = await docPicker.select(options);
    } catch (e) {
      console.info(`${TAG} select picker cancelled: ${(e as BusinessError).code}`);
      return undefined;
    }
    if (uris.length === 0) {
      return undefined;
    }
    let file: fs.File | undefined = undefined;
    try {
      file = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
      const stat: fs.Stat = fs.statSync(file.fd);
      const buf: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      const text: string = decoder.decodeToString(new Uint8Array(buf));
      return DataBackup.parse(text);
    } finally {
      if (file !== undefined) {
        fs.closeSync(file);
      }
    }
  }

  static parse(text: string): BackupData {
    const trimmed: string = text.trim();
    if (trimmed.length === 0) {
      throw new Error('empty backup file');
    }
    const root: Record<string, Object> = JSON.parse(trimmed) as Record<string, Object>;
    const data: BackupData = new BackupData();
    data.beans = DataBackup.parseBeans(root['beans']);
    data.equipments = DataBackup.parseEquipments(root['equipments']);
    data.brews = DataBackup.parseBrews(root['brews']);
    if (data.beans.length === 0 && data.equipments.length === 0 && data.brews.length === 0) {
      throw new Error('no data in backup file');
    }
    return data;
  }

  private static parseBeans(v: Object | undefined): CoffeeBean[] {
    const result: CoffeeBean[] = [];
    if (v === undefined) {
      return result;
    }
    const arr: Object[] = v as Object[];
    for (let i = 0; i < arr.length; i++) {
      const o: Record<string, Object> = arr[i] as Record<string, Object>;
      const b: CoffeeBean = new CoffeeBean();
      b.id = DataBackup.numOf(o, 'id');
      b.name = DataBackup.strOf(o, 'name');
      b.variety = DataBackup.strOf(o, 'variety');
      b.purchaseDate = DataBackup.numOf(o, 'purchaseDate');
      b.price = DataBackup.numOf(o, 'price');
      b.vendor = DataBackup.strOf(o, 'vendor');
      b.flavorTags = DataBackup.strOf(o, 'flavorTags');
      b.origin = DataBackup.strOf(o, 'origin');
      b.weight = DataBackup.numOf(o, 'weight');
      b.roastLevel = DataBackup.strOf(o, 'roastLevel');
      b.roastDate = DataBackup.numOf(o, 'roastDate');
      b.processMethod = DataBackup.strOf(o, 'processMethod');
      b.shelfLife = DataBackup.numOf(o, 'shelfLife');
      b.createdAt = DataBackup.numOf(o, 'createdAt');
      result.push(b);
    }
    return result;
  }

  private static parseEquipments(v: Object | undefined): Equipment[] {
    const result: Equipment[] = [];
    if (v === undefined) {
      return result;
    }
    const arr: Object[] = v as Object[];
    for (let i = 0; i < arr.length; i++) {
      const o: Record<string, Object> = arr[i] as Record<string, Object>;
      const e: Equipment = new Equipment();
      e.id = DataBackup.numOf(o, 'id');
      e.type = DataBackup.strOf(o, 'type');
      e.brand = DataBackup.strOf(o, 'brand');
      e.model = DataBackup.strOf(o, 'model');
      e.purchaseDate = DataBackup.numOf(o, 'purchaseDate');
      e.price = DataBackup.numOf(o, 'price');
      e.notes = DataBackup.strOf(o, 'notes');
      e.accessories = DataBackup.strOf(o, 'accessories');
      e.conditionState = DataBackup.strOf(o, 'conditionState');
      e.createdAt = DataBackup.numOf(o, 'createdAt');
      result.push(e);
    }
    return result;
  }

  private static parseBrews(v: Object | undefined): BrewRecord[] {
    const result: BrewRecord[] = [];
    if (v === undefined) {
      return result;
    }
    const arr: Object[] = v as Object[];
    for (let i = 0; i < arr.length; i++) {
      const o: Record<string, Object> = arr[i] as Record<string, Object>;
      const r: BrewRecord = new BrewRecord();
      r.id = DataBackup.numOf(o, 'id');
      r.brewDate = DataBackup.numOf(o, 'brewDate');
      r.method = DataBackup.strOf(o, 'method');
      r.beanId = DataBackup.numOf(o, 'beanId');
      r.beanName = DataBackup.strOf(o, 'beanName');
      r.dose = DataBackup.numOf(o, 'dose');
      r.waterAmount = DataBackup.numOf(o, 'waterAmount');
      r.waterTemp = DataBackup.numOf(o, 'waterTemp');
      r.grindSize = DataBackup.strOf(o, 'grindSize');
      r.brewDuration = DataBackup.numOf(o, 'brewDuration');
      r.rating = DataBackup.numOf(o, 'rating');
      r.notes = DataBackup.strOf(o, 'notes');
      r.applyExtraJson(DataBackup.strOf(o, 'extra'));
      r.createdAt = DataBackup.numOf(o, 'createdAt');
      result.push(r);
    }
    return result;
  }
}
