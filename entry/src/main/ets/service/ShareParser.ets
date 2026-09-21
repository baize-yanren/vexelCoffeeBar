import { ShareParseResult, CategoryKeywords } from '../model/ImportDraft';

export class ShareParser {
  private static readonly URL_RE: RegExp = new RegExp('https?://[^\\s，,。"】』]+');
  private static readonly PRICE_RE: RegExp = new RegExp('[¥￥]\\s*([0-9]+(?:\\.[0-9]{1,2})?)');
  private static readonly PREFIX_RE: RegExp = new RegExp('【[^】]*】');
  private static readonly SLOGAN_RE: RegExp =
    new RegExp('(复制[^\\s]*|打开(淘宝|京东|拼多多|APP|App)[^\\s]*|点击链接[^\\s]*|￥[^￥￥]*￥)');
  private static readonly ECOMMERCE_RE: RegExp =
    new RegExp('taobao|tb\\.cn|tmall|jd\\.com|pinduoduo|yangkeduo|pdd');

  static isEcommerceText(text: string): boolean {
    return ShareParser.ECOMMERCE_RE.test(text);
  }

  static parseShareText(text: string): ShareParseResult {
    const result: ShareParseResult = new ShareParseResult();
    // 平台识别
    if (text.indexOf('淘宝') >= 0 || text.indexOf('tb.cn') >= 0 || text.indexOf('taobao') >= 0) {
      result.platform = '淘宝';
    } else if (text.indexOf('京东') >= 0 || text.indexOf('jd.com') >= 0) {
      result.platform = '京东';
    } else if (text.indexOf('拼多多') >= 0 || text.indexOf('yangkeduo') >= 0 || text.indexOf('pinduoduo') >= 0) {
      result.platform = '拼多多';
    }
    // URL 提取
    const urlMatch: RegExpMatchArray | null = text.match(ShareParser.URL_RE);
    if (urlMatch !== null && urlMatch.length > 0) {
      result.url = urlMatch[0];
    }
    // 价格提取
    const priceMatch: RegExpMatchArray | null = text.match(ShareParser.PRICE_RE);
    if (priceMatch !== null && priceMatch.length > 1) {
      const n: number = Number(priceMatch[1]);
      if (!Number.isNaN(n) && n > 0) {
        result.price = n;
      }
    }
    // 标题提取：去掉前缀、口号、URL、价格后取最长段
    let cleaned: string = text;
    cleaned = cleaned.replace(ShareParser.PREFIX_RE, ' ');
    cleaned = cleaned.replace(ShareParser.URL_RE, ' ');
    cleaned = cleaned.replace(ShareParser.SLOGAN_RE, ' ');
    cleaned = cleaned.replace(ShareParser.PRICE_RE, ' ');
    const segRe: RegExp = new RegExp('[^\\s，,。！!？?；;、\\u201c\\u201d\\u2018\\u2019()（）]+');
    const segs: RegExpMatchArray | null = cleaned.match(segRe);
    let best: string = '';
    if (segs !== null) {
      for (let i = 0; i < segs.length; i++) {
        const s: string = segs[i];
        if (s.length > best.length && s.length > 3) {
          best = s;
        }
      }
    }
    result.title = best.trim();
    // 分类
    result.category = CategoryKeywords.classify(`${result.title} ${text}`);
    return result;
  }
}
