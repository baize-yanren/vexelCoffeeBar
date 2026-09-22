export class CoffeeBean {
  id: number = -1;
  name: string = '';
  variety: string = '';
  purchaseDate: number = 0;
  price: number = 0;
  vendor: string = '';
  flavorTags: string = '';
  origin: string = '';
  weight: number = 0;
  roastLevel: string = '';
  roastDate: number = 0;
  processMethod: string = '';
  shelfLife: number = 0;
  createdAt: number = 0;

  static of(variety: string, purchaseDate: number, price: number, vendor: string,
    flavorTags: string, name: string): CoffeeBean {
    const b = new CoffeeBean();
    b.variety = variety;
    b.purchaseDate = purchaseDate;
    b.price = price;
    b.vendor = vendor;
    b.flavorTags = flavorTags;
    b.name = name;
    return b;
  }

  flavorTagList(): string[] {
    if (this.flavorTags.length === 0) {
      return [];
    }
    return this.flavorTags.split(',').map((t: string): string => t.trim()).filter((t: string): boolean => t.length > 0);
  }
}

export class RoastLevel {
  static readonly ALL: string[] = ['浅焙', '中浅焙', '中焙', '中深焙', '深焙'];
}

export class ProcessMethod {
  static readonly ALL: string[] = ['日晒', '水洗', '蜜处理', '湿刨法', '厌氧发酵', '其他'];
}

export class Equipment {
  id: number = -1;
  type: string = '';
  brand: string = '';
  model: string = '';
  purchaseDate: number = 0;
  price: number = 0;
  notes: string = '';
  accessories: string = '';
  conditionState: string = '';
  createdAt: number = 0;

  static of(type: string, brand: string, model: string, purchaseDate: number,
    price: number, notes: string): Equipment {
    const e = new Equipment();
    e.type = type;
    e.brand = brand;
    e.model = model;
    e.purchaseDate = purchaseDate;
    e.price = price;
    e.notes = notes;
    return e;
  }
}

export class ItemCondition {
  static readonly ALL: string[] = ['全新', '二手'];
}

export class PourPlan {
  static readonly MAX: number = 5;
  static readonly CN: string[] = ['一', '二', '三', '四', '五'];
}

export class BrewRecord {
  id: number = -1;
  brewDate: number = 0;
  method: string = '';
  beanId: number = -1;
  beanName: string = '';
  dose: number = 0;
  waterAmount: number = 0;
  waterTemp: number = 0;
  grindSize: string = '';
  brewDuration: number = 0;
  rating: number = 0;
  notes: string = '';
  createdAt: number = 0;
  // 按冲煮方式区分的扩展参数（存储于 extra 列）
  yieldAmount: number = 0;      // 摩卡壶出品量 / 意式浓缩重量（g）
  heatLevel: string = '';       // 摩卡壶火候
  pourCount: number = 0;        // 手冲注水次数
  pour1Water: number = 0;       // 第一次注水量（g）
  pour1Time: number = 0;        // 第一次注水时间（秒）
  pour2Water: number = 0;       // 第二次注水量（g）
  pour2Time: number = 0;        // 第二次注水时间（秒）
  pour3Water: number = 0;       // 第三次注水量（g）
  pour3Time: number = 0;        // 第三次注水时间（秒）
  pour4Water: number = 0;       // 第四次注水量（g）
  pour4Time: number = 0;        // 第四次注水时间（秒）
  pour5Water: number = 0;       // 第五次注水量（g）
  pour5Time: number = 0;        // 第五次注水时间（秒）
  bloomWater: number = 0;       // 闷蒸水量（g）
  bloomTime: number = 0;        // 闷蒸时长（秒）
  pressure: number = 0;         // 意式压力（bar）
  steepHours: number = 0;       // 冷萃冷藏时长（小时）
  steepMinutes: number = 0;     // 爱乐压浸泡时间（分）
  pressSeconds: number = 0;     // 爱乐压压下时长（秒）
  beanCost: number = 0;         // 本次冲煮耗豆成本（元，按豆价/克重×粉量）

  static of(brewDate: number, method: string): BrewRecord {
    const r = new BrewRecord();
    r.brewDate = brewDate;
    r.method = method;
    return r;
  }

  pourWaterAt(idx: number): number {
    if (idx === 1) {
      return this.pour1Water;
    } else if (idx === 2) {
      return this.pour2Water;
    } else if (idx === 3) {
      return this.pour3Water;
    } else if (idx === 4) {
      return this.pour4Water;
    } else if (idx === 5) {
      return this.pour5Water;
    }
    return 0;
  }

  setPourWaterAt(idx: number, v: number): void {
    if (idx === 1) {
      this.pour1Water = v;
    } else if (idx === 2) {
      this.pour2Water = v;
    } else if (idx === 3) {
      this.pour3Water = v;
    } else if (idx === 4) {
      this.pour4Water = v;
    } else if (idx === 5) {
      this.pour5Water = v;
    }
  }

  pourTimeAt(idx: number): number {
    if (idx === 1) {
      return this.pour1Time;
    } else if (idx === 2) {
      return this.pour2Time;
    } else if (idx === 3) {
      return this.pour3Time;
    } else if (idx === 4) {
      return this.pour4Time;
    } else if (idx === 5) {
      return this.pour5Time;
    }
    return 0;
  }

  setPourTimeAt(idx: number, v: number): void {
    if (idx === 1) {
      this.pour1Time = v;
    } else if (idx === 2) {
      this.pour2Time = v;
    } else if (idx === 3) {
      this.pour3Time = v;
    } else if (idx === 4) {
      this.pour4Time = v;
    } else if (idx === 5) {
      this.pour5Time = v;
    }
  }

  private static strOf(obj: Record<string, Object>, key: string): string {
    const v: Object | undefined = obj[key];
    return v === undefined ? '' : `${v}`;
  }

  private static numOf(obj: Record<string, Object>, key: string): number {
    const v: Object | undefined = obj[key];
    return v === undefined ? 0 : Number(`${v}`);
  }

  toExtraJson(): string {
    const r: Record<string, Object> = {
      'yieldAmount': this.yieldAmount,
      'heatLevel': this.heatLevel,
      'pourCount': this.pourCount,
      'pour1Water': this.pour1Water,
      'pour1Time': this.pour1Time,
      'pour2Water': this.pour2Water,
      'pour2Time': this.pour2Time,
      'pour3Water': this.pour3Water,
      'pour3Time': this.pour3Time,
      'pour4Water': this.pour4Water,
      'pour4Time': this.pour4Time,
      'pour5Water': this.pour5Water,
      'pour5Time': this.pour5Time,
      'bloomWater': this.bloomWater,
      'bloomTime': this.bloomTime,
      'pressure': this.pressure,
      'steepHours': this.steepHours,
      'steepMinutes': this.steepMinutes,
      'pressSeconds': this.pressSeconds,
      'beanCost': this.beanCost
    };
    return JSON.stringify(r);
  }

  applyExtraJson(s: string): void {
    if (s.length === 0) {
      return;
    }
    try {
      const obj: Record<string, Object> = JSON.parse(s) as Record<string, Object>;
      this.yieldAmount = BrewRecord.numOf(obj, 'yieldAmount');
      this.heatLevel = BrewRecord.strOf(obj, 'heatLevel');
      this.pourCount = BrewRecord.numOf(obj, 'pourCount');
      this.pour1Water = BrewRecord.numOf(obj, 'pour1Water');
      this.pour1Time = BrewRecord.numOf(obj, 'pour1Time');
      this.pour2Water = BrewRecord.numOf(obj, 'pour2Water');
      this.pour2Time = BrewRecord.numOf(obj, 'pour2Time');
      this.pour3Water = BrewRecord.numOf(obj, 'pour3Water');
      this.pour3Time = BrewRecord.numOf(obj, 'pour3Time');
      this.pour4Water = BrewRecord.numOf(obj, 'pour4Water');
      this.pour4Time = BrewRecord.numOf(obj, 'pour4Time');
      this.pour5Water = BrewRecord.numOf(obj, 'pour5Water');
      this.pour5Time = BrewRecord.numOf(obj, 'pour5Time');
      this.bloomWater = BrewRecord.numOf(obj, 'bloomWater');
      this.bloomTime = BrewRecord.numOf(obj, 'bloomTime');
      this.pressure = BrewRecord.numOf(obj, 'pressure');
      this.steepHours = BrewRecord.numOf(obj, 'steepHours');
      this.steepMinutes = BrewRecord.numOf(obj, 'steepMinutes');
      this.pressSeconds = BrewRecord.numOf(obj, 'pressSeconds');
      this.beanCost = BrewRecord.numOf(obj, 'beanCost');
    } catch (e) {
      console.error(`applyExtraJson failed: ${e}`);
    }
  }
}

export class BrewMethod {
  static readonly POUR_OVER: string = '手冲';
  static readonly MOKA_POT: string = '摩卡壶';
  static readonly ESPRESSO: string = '意式';
  static readonly AERO_PRESS: string = '爱乐压';
  static readonly COLD_BREW: string = '冷萃';
  static readonly FRENCH_PRESS: string = '法压壶';
  static readonly SIPHON: string = '虹吸壶';
  static readonly OTHER: string = '其他';
  static readonly ALL: string[] = [
    BrewMethod.POUR_OVER,
    BrewMethod.MOKA_POT,
    BrewMethod.ESPRESSO,
    BrewMethod.AERO_PRESS,
    BrewMethod.COLD_BREW,
    BrewMethod.FRENCH_PRESS,
    BrewMethod.SIPHON,
    BrewMethod.OTHER
  ];
}

export class HeatLevel {
  static readonly ALL: string[] = ['小火', '中火', '大火'];
}

export class EquipmentType {
  static readonly ALL: string[] = [
    '手冲壶', '磨豆机', '滤杯', '滤纸', '分享壶', '电子秤', '温度计',
    '摩卡壶', '咖啡机', '法压壶', '爱乐压', '其他'
  ];
}

export class GrindSize {
  static readonly ALL: string[] = ['细', '中细', '中', '中粗', '粗'];
}

export class BrewFieldConfig {
  showWater: boolean = false;
  waterLabel: string = '水量（g）';
  showTemp: boolean = false;
  showGrind: boolean = false;
  showDuration: boolean = false;
  durationLabel: string = '萃取时长';
  showYield: boolean = false;
  yieldLabel: string = '出品量（g）';
  showHeat: boolean = false;
  showPourPlan: boolean = false;
  showBloom: boolean = false;
  showPressure: boolean = false;
  showSteep: boolean = false;
  steepLabel: string = '浸泡时间（分）';
  showPressTime: boolean = false;

  static of(method: string): BrewFieldConfig {
    const c = new BrewFieldConfig();
    if (method === BrewMethod.POUR_OVER) {
      c.showWater = true;
      c.waterLabel = '总水量（g）';
      c.showTemp = true;
      c.showGrind = true;
      c.showDuration = true;
      c.durationLabel = '总萃取时长';
      c.showPourPlan = true;
      c.showBloom = true;
    } else if (method === BrewMethod.MOKA_POT) {
      c.showWater = true;
      c.waterLabel = '水量（g）';
      c.showGrind = true;
      c.showDuration = true;
      c.durationLabel = '萃取时长';
      c.showYield = true;
      c.yieldLabel = '出品量（g）';
      c.showHeat = true;
    } else if (method === BrewMethod.ESPRESSO) {
      c.showTemp = true;
      c.showGrind = true;
      c.showDuration = true;
      c.durationLabel = '萃取时长';
      c.showYield = true;
      c.yieldLabel = '浓缩重量（g）';
      c.showPressure = true;
    } else if (method === BrewMethod.COLD_BREW) {
      c.showWater = true;
      c.waterLabel = '总水量（g）';
      c.showGrind = true;
      c.showSteep = true;
      c.steepLabel = '冷藏时长（小时）';
    } else if (method === BrewMethod.AERO_PRESS) {
      c.showWater = true;
      c.waterLabel = '总水量（g）';
      c.showTemp = true;
      c.showGrind = true;
      c.showSteep = true;
      c.steepLabel = '浸泡时间（分）';
      c.showPressTime = true;
    } else {
      // 法压壶 / 虹吸壶 / 其他
      c.showWater = true;
      c.showTemp = true;
      c.showGrind = true;
      c.showDuration = true;
      c.durationLabel = '萃取时长';
    }
    return c;
  }
}
