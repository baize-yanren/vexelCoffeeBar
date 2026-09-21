export class CoffeeBean {
  id: number = -1;
  name: string = '';
  variety: string = '';
  purchaseDate: number = 0;
  price: number = 0;
  vendor: string = '';
  flavorTags: string = '';
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

export class Equipment {
  id: number = -1;
  type: string = '';
  brand: string = '';
  model: string = '';
  purchaseDate: number = 0;
  price: number = 0;
  notes: string = '';
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

  static of(brewDate: number, method: string): BrewRecord {
    const r = new BrewRecord();
    r.brewDate = brewDate;
    r.method = method;
    return r;
  }
}

export class BrewMethod {
  static readonly POUR_OVER: string = '手冲';
  static readonly MOKA_POT: string = '摩卡壶';
  static readonly ESPRESSO: string = '半自动咖啡机';
  static readonly FRENCH_PRESS: string = '法压壶';
  static readonly SIPHON: string = '虹吸壶';
  static readonly AERO_PRESS: string = '爱乐压';
  static readonly COLD_BREW: string = '冷萃';
  static readonly OTHER: string = '其他';
  static readonly ALL: string[] = [
    BrewMethod.POUR_OVER,
    BrewMethod.MOKA_POT,
    BrewMethod.ESPRESSO,
    BrewMethod.FRENCH_PRESS,
    BrewMethod.SIPHON,
    BrewMethod.AERO_PRESS,
    BrewMethod.COLD_BREW,
    BrewMethod.OTHER
  ];
}

export class EquipmentType {
  static readonly ALL: string[] = [
    '手冲壶', '磨豆机', '滤杯', '滤纸', '分享壶', '电子秤', '温度计',
    '摩卡壶', '咖啡机', '法压壶', '其他'
  ];
}

export class GrindSize {
  static readonly ALL: string[] = ['细', '中细', '中', '中粗', '粗'];
}

export class BrewFieldConfig {
  showWater: boolean = true;
  showTemp: boolean = true;
  durationLabel: string = '冲煮时长';

  static of(method: string): BrewFieldConfig {
    const c = new BrewFieldConfig();
    if (method === BrewMethod.MOKA_POT) {
      c.showWater = true;
      c.showTemp = false;
      c.durationLabel = '加热时长';
    } else if (method === BrewMethod.ESPRESSO) {
      c.showWater = false;
      c.showTemp = true;
      c.durationLabel = '萃取时长';
    } else if (method === BrewMethod.COLD_BREW) {
      c.showWater = true;
      c.showTemp = false;
      c.durationLabel = '萃取时长';
    }
    return c;
  }
}
