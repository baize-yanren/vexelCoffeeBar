import { BusinessError } from '@kit.BasicServicesKit';
import { CoffeeBean } from '../model/Models';
import { FormParams } from '../model/RouteParams';
import { ImportDraft, OcrParseResult, CategoryKeywords } from '../model/ImportDraft';
import { AppKeys, ThemePalette } from '../common/Theme';
import { CoffeeDb } from '../data/CoffeeDb';
import { DateUtil } from '../common/DateUtil';
import { OcrImport, OcrImportResult } from '../service/OcrImport';

@Entry
@Component
struct BeanFormPage {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @State variety: string = '';
  @State name: string = '';
  @State vendor: string = '';
  @State price: string = '';
  @State flavorTags: string = '';
  @State purchaseDate: number = Date.now();
  @State errorText: string = '';
  @State importing: boolean = false;
  @State importedTip: string = '';
  private editId: number = -1;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as FormParams;
    const id: number = params?.id ?? -1;
    if (id > 0) {
      this.editId = id;
      CoffeeDb.getInstance().queryBeans().then((list: CoffeeBean[]) => {
        const found: CoffeeBean | undefined = list.find((b: CoffeeBean): boolean => b.id === id);
        if (found !== undefined) {
          this.variety = found.variety;
          this.name = found.name;
          this.vendor = found.vendor;
          this.price = found.price > 0 ? `${found.price}` : '';
          this.flavorTags = found.flavorTags;
          this.purchaseDate = found.purchaseDate > 0 ? found.purchaseDate : Date.now();
        }
      }).catch((e: BusinessError) => {
        console.error(`load bean failed: ${e.code}`);
      });
    } else {
      this.consumeDraft();
    }
  }

  private consumeDraft(): void {
    const d: ImportDraft = AppStorage.get<ImportDraft>(AppKeys.IMPORT_DRAFT) ?? new ImportDraft();
    if (d.target === 'bean' && d.title.length > 0) {
      if (CategoryKeywords.containsAny(d.title, CategoryKeywords.BEAN)) {
        this.variety = d.title;
      } else {
        this.name = d.title;
      }
      if (d.price > 0) {
        this.price = `${d.price}`;
      }
      if (d.vendor.length > 0) {
        this.vendor = d.vendor;
      }
      if (d.purchaseDate > 0) {
        this.purchaseDate = d.purchaseDate;
      }
      AppStorage.setOrCreate(AppKeys.IMPORT_DRAFT, new ImportDraft());
      this.importedTip = '已从链接导入信息，请核对后保存';
    }
  }

  private importFromScreenshot(): void {
    if (this.importing) {
      return;
    }
    this.importing = true;
    OcrImport.pickAndRecognize().then((r: OcrImportResult) => {
      this.importing = false;
      if (r.status === 'ok' && r.parsed !== undefined) {
        const count: number = this.applyOcr(r.parsed);
        this.getUIContext().getPromptAction().showToast({ message: `已识别填入 ${count} 项，请核对` });
      } else if (r.status === 'empty') {
        this.getUIContext().getPromptAction().showToast({ message: '未识别到订单信息' });
      } else if (r.status === 'failed') {
        this.getUIContext().getPromptAction().showToast({ message: '识别失败，请重试' });
      }
    }).catch((e: BusinessError) => {
      this.importing = false;
      console.error(`ocr import error: ${e.code}`);
    });
  }

  private applyOcr(p: OcrParseResult): number {
    let count: number = 0;
    if (p.variety.length > 0) {
      this.variety = p.variety;
      count++;
    } else if (p.name.length > 0) {
      this.name = p.name;
      count++;
    }
    if (p.price > 0) {
      this.price = `${p.price}`;
      count++;
    }
    if (p.vendor.length > 0) {
      this.vendor = p.vendor;
      count++;
    }
    if (p.dateFound) {
      this.purchaseDate = p.purchaseDate;
      count++;
    }
    return count;
  }

  private pickDate(): void {
    this.getUIContext().showDatePickerDialog({
      selected: new Date(this.purchaseDate),
      onAccept: (value: DatePickerResult) => {
        const current: Date = new Date(this.purchaseDate);
        const y: number = value.year ?? current.getFullYear();
        const m: number = value.month ?? (current.getMonth() + 1);
        const d: number = value.day ?? current.getDate();
        this.purchaseDate = new Date(y, m - 1, d, 12, 0, 0).getTime();
      }
    });
  }

  private save(): void {
    if (this.variety.trim().length === 0) {
      this.errorText = '请填写品种';
      return;
    }
    let priceNum: number = 0;
    const priceTrim: string = this.price.trim();
    if (priceTrim.length > 0) {
      priceNum = Number(priceTrim);
      if (Number.isNaN(priceNum) || priceNum < 0) {
        this.errorText = '价格格式不正确';
        return;
      }
    }
    const b: CoffeeBean = CoffeeBean.of(this.variety.trim(), this.purchaseDate, priceNum,
      this.vendor.trim(), this.flavorTags.trim(), this.name.trim());
    b.id = this.editId;
    const task: Promise<number> = this.editId > 0 ?
      CoffeeDb.getInstance().updateBean(b) :
      CoffeeDb.getInstance().addBean(b);
    task.then(() => {
      AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
      this.getUIContext().getPromptAction().showToast({ message: '已保存' });
      this.getUIContext().getRouter().back();
    }).catch((e: BusinessError) => {
      this.errorText = '保存失败，请重试';
      console.error(`save bean failed: ${e.code}`);
    });
  }

  @Builder
  fieldLabel(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor($r('app.color.text_secondary'))
      .width(80)
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ left: 4, right: 8 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text(this.editId > 0 ? '编辑咖啡豆' : '记录咖啡豆')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.importedTip.length > 0) {
            Text(`✅ ${this.importedTip}`)
              .fontSize(12)
              .fontColor(this.themeColor)
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(ThemePalette.alpha(this.themeColor, 0.10))
              .borderRadius(12)
          }

          Row({ space: 8 }) {
            Text('📷')
              .fontSize(16)
            Text(this.importing ? '正在识别截图…' : '从订单截图导入（自动识别）')
              .fontSize(14)
              .fontColor(this.themeColor)
              .layoutWeight(1)
          }
          .width('100%')
          .height(44)
          .padding({ left: 14, right: 14 })
          .borderRadius(12)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: ThemePalette.alpha(this.themeColor, 0.35) })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.importFromScreenshot();
          })

          Row({ space: 10 }) {
            this.fieldLabel('品种 *')
            TextInput({ placeholder: '如：埃塞俄比亚·耶加雪菲·日晒', text: this.variety })
              .layoutWeight(1)
              .backgroundColor($r('app.color.input_background'))
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_hint'))
              .caretColor(this.themeColor)
              .borderRadius(12)
              .onChange((value: string) => {
                this.variety = value;
              })
          }
          .width('100%')

          Row({ space: 10 }) {
            this.fieldLabel('名称')
            TextInput({ placeholder: '如：花魁7.0（选填）', text: this.name })
              .layoutWeight(1)
              .backgroundColor($r('app.color.input_background'))
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_hint'))
              .caretColor(this.themeColor)
              .borderRadius(12)
              .onChange((value: string) => {
                this.name = value;
              })
          }
          .width('100%')

          Row({ space: 10 }) {
            this.fieldLabel('购买时间')
            Text(DateUtil.formatDate(this.purchaseDate))
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .padding({ left: 12, right: 12, top: 12, bottom: 12 })
              .backgroundColor($r('app.color.input_background'))
              .borderRadius(12)
              .onClick(() => {
                this.pickDate();
              })
          }
          .width('100%')

          Row({ space: 10 }) {
            this.fieldLabel('价格（元）')
            TextInput({ placeholder: '如：98（选填）', text: this.price })
              .layoutWeight(1)
              .backgroundColor($r('app.color.input_background'))
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_hint'))
              .caretColor(this.themeColor)
              .borderRadius(12)
              .onChange((value: string) => {
                this.price = value;
              })
          }
          .width('100%')

          Row({ space: 10 }) {
            this.fieldLabel('商家')
            TextInput({ placeholder: '如：某宝·某某咖啡旗舰店（选填）', text: this.vendor })
              .layoutWeight(1)
              .backgroundColor($r('app.color.input_background'))
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_hint'))
              .caretColor(this.themeColor)
              .borderRadius(12)
              .onChange((value: string) => {
                this.vendor = value;
              })
          }
          .width('100%')

          Column({ space: 8 }) {
            Text('风味描述词')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            TextInput({ placeholder: '用逗号分隔，如：花香,柑橘,红茶', text: this.flavorTags })
              .width('100%')
              .backgroundColor($r('app.color.input_background'))
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_hint'))
              .caretColor(this.themeColor)
              .borderRadius(12)
              .onChange((value: string) => {
                this.flavorTags = value;
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor($r('app.color.danger_color'))
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          Button() {
            Text(this.editId > 0 ? '保存修改' : '保存')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .height(48)
          .backgroundColor(this.themeColor)
          .borderRadius(24)
          .margin({ top: 12 })
          .onClick(() => {
            this.save();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 40 })
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemePalette.page(this.themeColor, this.isDarkMode))
  }
}
