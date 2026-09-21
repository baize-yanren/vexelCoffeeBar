import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class LinkFetcher {
  private static readonly TITLE_RE: RegExp = new RegExp('<title[^>]*>([^<]+)</title>');
  private static readonly DIRTY_RE: RegExp =
    new RegExp('登录|验证|滑动|访问受限|安全验证|403|404|防火墙|机器人');
  private static readonly UA: string =
    'Mozilla/5.0 (Linux; Android 14; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) ' +
    'Chrome/120.0.0.0 Mobile Safari/537.36';

  static async fetchTitle(url: string): Promise<string> {
    if (url.length === 0 || url.indexOf('http') !== 0) {
      return '';
    }
    let req: http.HttpRequest | undefined = undefined;
    try {
      req = http.createHttp();
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
        header: {
          'User-Agent': LinkFetcher.UA,
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'zh-CN,zh;q=0.9'
        }
      };
      const resp: http.HttpResponse = await req.request(url, options);
      const body: string = `${resp.result}`;
      const titleMatch: RegExpMatchArray | null = body.match(LinkFetcher.TITLE_RE);
      if (titleMatch !== null && titleMatch.length > 1) {
        let title: string = titleMatch[1].trim();
        title = title.replace(new RegExp('&amp;', 'g'), '&');
        title = title.replace(new RegExp('&nbsp;', 'g'), ' ');
        if (title.length > 0 && !LinkFetcher.DIRTY_RE.test(title)) {
          return title;
        }
      }
      return '';
    } catch (e) {
      console.info(`LinkFetcher fetch failed (expected for some sites): ${(e as BusinessError).code}`);
      return '';
    } finally {
      if (req !== undefined) {
        req.destroy();
      }
    }
  }
}
