import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ImportDraft, ShareParseResult } from '../model/ImportDraft';
import { ShareParser } from './ShareParser';
import { LinkFetcher } from './LinkFetcher';
import { AppKeys } from '../common/Theme';

export class ClipboardCheckResult {
  found: boolean = false;
  draft: ImportDraft = new ImportDraft();
  parse: ShareParseResult = new ShareParseResult();
}

export class ClipboardImport {
  static async check(): Promise<ClipboardCheckResult> {
    const result: ClipboardCheckResult = new ClipboardCheckResult();
    let text: string = '';
    try {
      const data: pasteboard.PasteData = await pasteboard.getSystemPasteboard().getData();
      text = data.getPrimaryText();
    } catch (e) {
      console.info(`clipboard read skipped: ${(e as BusinessError).code}`);
      return result;
    }
    if (text.length === 0 || text.length > 500) {
      return result;
    }
    const last: string = AppStorage.get<string>(AppKeys.LAST_IMPORTED) ?? '';
    if (last.length > 0 && last === text) {
      return result;
    }
    if (!ShareParser.isEcommerceText(text)) {
      return result;
    }
    const parse: ShareParseResult = ShareParser.parseShareText(text);
    if (parse.url.length === 0) {
      return result;
    }
    let title: string = parse.title;
    if (title.length === 0) {
      title = await LinkFetcher.fetchTitle(parse.url);
    }
    if (title.length === 0) {
      title = parse.platform.length > 0 ? `来自${parse.platform}的商品` : '未命名商品';
    }
    const draft: ImportDraft = new ImportDraft();
    draft.title = title;
    draft.price = parse.price;
    draft.vendor = parse.platform;
    draft.purchaseDate = Date.now();
    draft.sourceUrl = parse.url;
    parse.title = title;
    result.found = true;
    result.draft = draft;
    result.parse = parse;
    AppStorage.setOrCreate(AppKeys.LAST_IMPORTED, text);
    return result;
  }
}
