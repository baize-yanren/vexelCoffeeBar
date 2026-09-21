export class ImportDraft {
  target: string = '';
  title: string = '';
  price: number = -1;
  vendor: string = '';
  purchaseDate: number = Date.now();
  sourceUrl: string = '';
}

export class ShareParseResult {
  platform: string = '';
  title: string = '';
  price: number = -1;
  url: string = '';
  category: string = 'unknown';
}

export class OcrParseResult {
  name: string = '';
  variety: string = '';
  price: number = -1;
  vendor: string = '';
  purchaseDate: number = Date.now();
  dateFound: boolean = false;
  type: string = '';
  brand: string = '';
  model: string = '';
  matchedCount: number = 0;
}

export class CategoryKeywords {
  static readonly BEAN: string[] = [
    '咖啡豆', '耶加', '瑰夏', '蓝山', '曼特宁', '哥伦比亚', '埃塞', '危地马拉',
    '云南', '水洗', '日晒', '蜜处理', '意式豆', '单品豆', 'g装', 'geisha', 'sachet'
  ];
  static readonly EQUIPMENT: string[] = [
    '壶', '磨豆机', '滤杯', '咖啡机', '手冲', '法压', '摩卡', '爱乐压',
    '电子秤', '温度计', '滤纸', '粉锤', '拉花缸', '磨豆', '咖啡磨'
  ];
  static readonly BRANDS: string[] = [
    'Hario', 'Timemore', '泰摩', 'Fellow', '比乐蒂', 'Bialetti', '德龙', 'Delonghi',
    'Barsetto', '百胜图', '马克西姆', '东菱', '苏泊尔', 'Hero', 'Brewista', '1Zpresso', 'Mavo'
  ];

  static containsAny(text: string, keywords: string[]): boolean {
    for (let i = 0; i < keywords.length; i++) {
      if (text.toLowerCase().indexOf(keywords[i].toLowerCase()) >= 0) {
        return true;
      }
    }
    return false;
  }

  static classify(text: string): string {
    const beanHit: boolean = CategoryKeywords.containsAny(text, CategoryKeywords.BEAN);
    const equipHit: boolean = CategoryKeywords.containsAny(text, CategoryKeywords.EQUIPMENT);
    if (beanHit && !equipHit) {
      return 'bean';
    }
    if (equipHit && !beanHit) {
      return 'equipment';
    }
    return 'unknown';
  }
}
