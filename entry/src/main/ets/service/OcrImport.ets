import { picker, fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { textRecognition } from '@kit.CoreVisionKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { OcrParseResult } from '../model/ImportDraft';
import { OcrParser } from './OcrParser';

export class OcrImportResult {
  status: string = 'cancelled';
  parsed: OcrParseResult | undefined = undefined;
}

export class OcrImport {
  static async pickAndRecognize(): Promise<OcrImportResult> {
    const outcome: OcrImportResult = new OcrImportResult();
    const options: picker.PhotoSelectOptions = new picker.PhotoSelectOptions();
    options.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const photoPicker: picker.PhotoViewPicker = new picker.PhotoViewPicker();
    let uris: Array<string> = [];
    try {
      const sel: picker.PhotoSelectResult = await photoPicker.select(options);
      uris = sel.photoUris;
    } catch (e) {
      console.info(`photo picker cancelled: ${(e as BusinessError).code}`);
      return outcome;
    }
    if (uris.length === 0) {
      return outcome;
    }

    let pm: image.PixelMap | undefined = undefined;
    let source: image.ImageSource | undefined = undefined;
    let file: fs.File | undefined = undefined;
    try {
      file = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
      source = image.createImageSource(file.fd);
      pm = await source.createPixelMap();
      const info: image.ImageInfo = await pm.getImageInfo();
      const longSide: number = Math.max(info.size.width, info.size.height);
      if (longSide > 1280) {
        const scale: number = 1280 / longSide;
        await pm.scale(scale, scale);
      }
      try {
        await textRecognition.init();
      } catch (e) {
        console.warn(`ocr init skipped: ${(e as BusinessError).code}`);
      }
      const visionInfo: textRecognition.VisionInfo = { pixelMap: pm };
      const r: textRecognition.TextRecognitionResult =
        await textRecognition.recognizeText(visionInfo);
      const parsed: OcrParseResult = OcrParser.parseOrderText(r.value);
      if (parsed.matchedCount === 0) {
        outcome.status = 'empty';
      } else {
        outcome.status = 'ok';
        outcome.parsed = parsed;
      }
    } catch (e) {
      console.error(`ocr import failed: ${(e as BusinessError).code} ${(e as BusinessError).message}`);
      outcome.status = 'failed';
    } finally {
      if (pm !== undefined) {
        pm.release();
      }
      if (source !== undefined) {
        source.release();
      }
      if (file !== undefined) {
        fs.closeSync(file);
      }
    }
    return outcome;
  }
}
