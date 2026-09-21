import { OcrParseResult, CategoryKeywords } from '../model/ImportDraft';

export class OcrParser {
  private static readonly PRICE_RE: RegExp = new RegExp('[¥￥]\\s*([0-9]+(?:\\.[0-9]{1,2})?)');
  private static readonly DATE_RE: RegExp =
    new RegExp('([0-9]{4})[-/年.]([0-9]{1,2})[-/月.]([0-9]{1,2})');
  private static readonly SHOP_RE: RegExp =
    new RegExp('[\\u4e00-\\u9fa5A-Za-z0-9]{2,20}(旗舰店|专营店|专卖店|自营店)');
  private static readonly MODEL_RE: RegExp = new RegExp('[A-Za-z]+[-]?[0-9][A-Za-z0-9-]*');

  static parseOrderText(fullText: string): OcrParseResult {
    const result: OcrParseResult = new OcrParseResult();
    let matched: number = 0;
    const lines: string[] = fullText.split('\n');

    // 价格：全文第一个 ¥ 匹配
    const priceMatch: RegExpMatchArray | null = fullText.match(OcrParser.PRICE_RE);
    if (priceMatch !== null && priceMatch.length > 1) {
      const n: number = Number(priceMatch[1]);
      if (!Number.isNaN(n) && n > 0) {
        result.price = n;
        matched++;
      }
    }

    // 日期：第一个 yyyy-M-d 匹配
    const dateMatch: RegExpMatchArray | null = fullText.match(OcrParser.DATE_RE);
    if (dateMatch !== null && dateMatch.length > 3) {
      const y: number = Number(dateMatch[1]);
      const m: number = Number(dateMatch[2]);
      const d: number = Number(dateMatch[3]);
      if (!Number.isNaN(y) && !Number.isNaN(m) && !Number.isNaN(d) && y >= 2000 && y <= 2100) {
        result.purchaseDate = new Date(y, m - 1, d, 12, 0, 0).getTime();
        result.dateFound = true;
        matched++;
      }
    }

    // 商家：优先"xx旗舰店"样式，其次含店铺关键词的整行
    const shopMatch: RegExpMatchArray | null = fullText.match(OcrParser.SHOP_RE);
    if (shopMatch !== null && shopMatch.length > 0) {
      result.vendor = shopMatch[0].trim();
      matched++;
    } else {
      for (let i = 0; i < lines.length; i++) {
        const line: string = lines[i].trim();
        if (line.length > 0 && line.length <= 20 &&
          (line.indexOf('店铺') >= 0 || line.indexOf('京东自营') >= 0)) {
          result.vendor = line;
          matched++;
          break;
        }
      }
    }

    // 标题：含咖啡豆/器具关键词的最长行（剥除价格与日期片段）
    let beanTitle: string = '';
    let equipTitle: string = '';
    for (let i = 0; i < lines.length; i++) {
      let line: string = lines[i].trim();
      if (line.length === 0 || line.length > 40) {
        continue;
      }
      line = line.replace(OcrParser.PRICE_RE, ' ').replace(OcrParser.DATE_RE, ' ').trim();
      if (line.length < 3) {
        continue;
      }
      if (CategoryKeywords.containsAny(line, CategoryKeywords.BEAN) && line.length > beanTitle.length) {
        beanTitle = line;
      }
      if (CategoryKeywords.containsAny(line, CategoryKeywords.EQUIPMENT) && line.length > equipTitle.length) {
        equipTitle = line;
      }
    }

    // 咖啡豆字段
    if (beanTitle.length > 0) {
      result.variety = beanTitle;
      result.name = '';
      matched++;
    }

    // 器具字段：标题 + 品牌 + 型号
    if (equipTitle.length > 0) {
      matched++;
      result.type = OcrParser.matchEquipmentType(equipTitle);
      for (let i = 0; i < CategoryKeywords.BRANDS.length; i++) {
        const brand: string = CategoryKeywords.BRANDS[i];
        if (equipTitle.toLowerCase().indexOf(brand.toLowerCase()) >= 0) {
          result.brand = brand;
          matched++;
          break;
        }
      }
      const modelMatch: RegExpMatchArray | null = equipTitle.match(OcrParser.MODEL_RE);
      if (modelMatch !== null && modelMatch.length > 0) {
        result.model = modelMatch[0];
        matched++;
      }
      if (result.type.length === 0) {
        result.type = equipTitle;
      }
    }

    // 兜底：没有专属标题时，取最长的非价格非日期行作为名称参考
    if (result.variety.length === 0 && result.type.length === 0) {
      let longest: string = '';
      for (let i = 0; i < lines.length; i++) {
        let line: string = lines[i].trim();
        if (line.length === 0 || line.length > 40) {
          continue;
        }
        line = line.replace(OcrParser.PRICE_RE, ' ').replace(OcrParser.DATE_RE, ' ').trim();
        if (line.length > longest.length && line.length >= 4) {
          longest = line;
        }
      }
      if (longest.length > 0) {
        result.name = longest;
        matched++;
      }
    }

    result.matchedCount = matched;
    return result;
  }

  private static matchEquipmentType(title: string): string {
    const candidates: string[] = ['磨豆机', '咖啡机', '手冲壶', '法压壶', '摩卡壶', '滤杯', '滤纸',
      '电子秤', '温度计', '粉锤', '拉花缸', '分享壶', '虹吸壶', '手冲'];
    for (let i = 0; i < candidates.length; i++) {
      if (title.indexOf(candidates[i]) >= 0) {
        if (candidates[i] === '手冲' && title.indexOf('手冲壶') < 0) {
          continue;
        }
        return candidates[i];
      }
    }
    if (title.indexOf('壶') >= 0) {
      return '其他';
    }
    return '';
  }
}
