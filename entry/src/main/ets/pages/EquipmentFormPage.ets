import { BusinessError } from '@kit.BasicServicesKit';
import { Equipment, EquipmentType, ItemCondition } from '../model/Models';
import { FormParams } from '../model/RouteParams';
import { ImportDraft, OcrParseResult, CategoryKeywords } from '../model/ImportDraft';
import { AppKeys, ThemePalette } from '../common/Theme';
import { CoffeeDb } from '../data/CoffeeDb';
import { DateUtil } from '../common/DateUtil';
import { OptionItem, OptionSheet } from '../components/OptionSheet';
import { OcrImport, OcrImportResult } from '../service/OcrImport';

@Entry
@Component
struct EquipmentFormPage {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @State type: string = '';
  @State brand: string = '';
  @State model: string = '';
  @State price: string = '';
  @State notes: string = '';
  @State accessories: string = '';
  @State conditionState: string = '';
  @State purchaseDate: number = Date.now();
  @State errorText: string = '';
  @State showTypeSheet: boolean = false;
  @State showConditionSheet: boolean = false;
  @State importing: boolean = false;
  @State importedTip: string = '';
  private editId: number = -1;
  private typeOptions: OptionItem[] = [];
  private conditionOptions: OptionItem[] = [];
  private static readonly MODEL_RE: RegExp = new RegExp('[A-Za-z]+[-]?[0-9][A-Za-z0-9-]*');

  aboutToAppear(): void {
    this.typeOptions = EquipmentType.ALL.map((t: string): OptionItem => {
      const it = new OptionItem();
      it.icon = '⚗️';
      it.label = t;
      it.action = (): void => {
        this.type = t;
      };
      return it;
    });
    this.conditionOptions = ItemCondition.ALL.map((t: string): OptionItem => {
      const it = new OptionItem();
      it.icon = t === '全新' ? '✨' : '♻️';
      it.label = t;
      it.action = (): void => {
        this.conditionState = t;
      };
      return it;
    });
    const params = this.getUIContext().getRouter().getParams() as FormParams;
    const id: number = params?.id ?? -1;
    if (id > 0) {
      this.editId = id;
      CoffeeDb.getInstance().queryEquipments().then((list: Equipment[]) => {
        const found: Equipment | undefined = list.find((e: Equipment): boolean => e.id === id);
        if (found !== undefined) {
          this.type = found.type;
          this.brand = found.brand;
          this.model = found.model;
          this.price = found.price > 0 ? `${found.price}` : '';
          this.notes = found.notes;
          this.accessories = found.accessories;
          this.conditionState = found.conditionState;
          this.purchaseDate = found.purchaseDate > 0 ? found.purchaseDate : Date.now();
        }
      }).catch((e: BusinessError) => {
        console.error(`load equipment failed: ${e.code}`);
      });
    } else {
      this.consumeDraft();
    }
  }

  private consumeDraft(): void {
    const d: ImportDraft = AppStorage.get<ImportDraft>(AppKeys.IMPORT_DRAFT) ?? new ImportDraft();
    if (d.target === 'equipment' && d.title.length > 0) {
      const title: string = d.title;
      for (let i = 0; i < CategoryKeywords.BRANDS.length; i++) {
        if (title.toLowerCase().indexOf(CategoryKeywords.BRANDS[i].toLowerCase()) >= 0) {
          this.brand = CategoryKeywords.BRANDS[i];
          break;
        }
      }
      const modelMatch: RegExpMatchArray | null = title.match(EquipmentFormPage.MODEL_RE);
      if (modelMatch !== null && modelMatch.length > 0) {
        this.model = modelMatch[0];
      }
      for (let i = 0; i < EquipmentType.ALL.length; i++) {
        if (title.indexOf(EquipmentType.ALL[i]) >= 0) {
          this.type = EquipmentType.ALL[i];
          break;
        }
      }
      if (this.type.length === 0 && title.indexOf('手冲') >= 0) {
        this.type = '手冲壶';
      }
      if (this.brand.length === 0 && this.model.length === 0 && this.type.length === 0) {
        this.notes = `来源商品：${title}`;
      }
      if (d.price > 0) {
        this.price = `${d.price}`;
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
    if (p.type.length > 0 && p.type.length <= 12) {
      this.type = p.type;
      count++;
    }
    if (p.brand.length > 0) {
      this.brand = p.brand;
      count++;
    }
    if (p.model.length > 0) {
      this.model = p.model;
      count++;
    }
    if (p.price > 0) {
      this.price = `${p.price}`;
      count++;
    }
    if (p.dateFound) {
      this.purchaseDate = p.purchaseDate;
      count++;
    }
    if (p.type.length > 12 && this.notes.length === 0) {
      this.notes = `识别参考：${p.type}`;
    }
    return count;
  }

  private toggleSheet(key: string, show: boolean): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      if (key === 'type') {
        this.showTypeSheet = show;
      } else if (key === 'condition') {
        this.showConditionSheet = show;
      }
    });
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
    if (this.type.length === 0) {
      this.errorText = '请选择种类';
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
    const e: Equipment = Equipment.of(this.type, this.brand.trim(), this.model.trim(),
      this.purchaseDate, priceNum, this.notes.trim());
    e.accessories = this.accessories.trim();
    e.conditionState = this.conditionState;
    e.id = this.editId;
    const task: Promise<number> = this.editId > 0 ?
      CoffeeDb.getInstance().updateEquipment(e) :
      CoffeeDb.getInstance().addEquipment(e);
    task.then(() => {
      AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
      this.getUIContext().getPromptAction().showToast({ message: '已保存' });
      this.getUIContext().getRouter().back();
    }).catch((err: BusinessError) => {
      this.errorText = '保存失败，请重试';
      console.error(`save equipment failed: ${err.code}`);
    });
  }

  @Builder
  fieldLabel(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor($r('app.color.text_secondary'))
      .constraintSize({ minWidth: 88 })
  }

  @Builder
  inputRow(label: string, placeholder: string, text: string, onChange: (v: string) => void) {
    Row({ space: 10 }) {
      this.fieldLabel(label)
      TextInput({ placeholder: placeholder, text: text })
        .layoutWeight(1)
        .backgroundColor($r('app.color.input_background'))
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_hint'))
        .caretColor(this.themeColor)
        .borderRadius(12)
        .onChange((value: string) => {
          onChange(value);
        })
    }
    .width('100%')
  }

  @Builder
  selectRow(label: string, value: string, placeholder: string, onTap: () => void) {
    Row({ space: 10 }) {
      this.fieldLabel(label)
      Text(value.length > 0 ? value : placeholder)
        .fontSize(15)
        .fontColor(value.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_hint'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .backgroundColor($r('app.color.input_background'))
        .borderRadius(12)
        .onClick(() => {
          onTap();
        })
    }
    .width('100%')
  }

  build() {
    Stack() {
      Column() {
        Row({ space: 8 }) {
          Text('‹')
            .fontSize(28)
            .fontColor($r('app.color.text_primary'))
            .padding({ left: 4, right: 8 })
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })
          Text(this.editId > 0 ? '编辑器具' : '记录器具')
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

            this.selectRow('种类 *', this.type, '点击选择', (): void => {
              this.toggleSheet('type', true);
            })

            this.inputRow('品牌', '如：Hario（选填）', this.brand, (v: string): void => {
              this.brand = v;
            })

            this.inputRow('型号', '如：V60 陶瓷 02（选填）', this.model, (v: string): void => {
              this.model = v;
            })

            this.selectRow('新旧', this.conditionState, '点击选择（选填）', (): void => {
              this.toggleSheet('condition', true);
            })

            this.inputRow('配件', '如：原装滤网、量勺（选填）', this.accessories, (v: string): void => {
              this.accessories = v;
            })

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

            this.inputRow('价格（元）', '如：68（选填）', this.price, (v: string): void => {
              this.price = v;
            })

            Column({ space: 8 }) {
              Text('备注')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              TextInput({ placeholder: '其他说明（选填）', text: this.notes })
                .width('100%')
                .backgroundColor($r('app.color.input_background'))
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_hint'))
                .caretColor(this.themeColor)
                .borderRadius(12)
                .onChange((value: string) => {
                  this.notes = value;
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

      if (this.showTypeSheet) {
        OptionSheet({
          title: '器具种类',
          options: this.typeOptions,
          onClose: (): void => {
            this.toggleSheet('type', false);
          }
        })
      }

      if (this.showConditionSheet) {
        OptionSheet({
          title: '新旧',
          options: this.conditionOptions,
          onClose: (): void => {
            this.toggleSheet('condition', false);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemePalette.page(this.themeColor, this.isDarkMode))
  }
}
