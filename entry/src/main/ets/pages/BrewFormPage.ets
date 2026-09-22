import { BusinessError } from '@kit.BasicServicesKit';
import { BrewRecord, BrewMethod, BrewFieldConfig, GrindSize, CoffeeBean } from '../model/Models';
import { FormParams } from '../model/RouteParams';
import { CoffeeDb } from '../data/CoffeeDb';
import { SettingsStore } from '../data/SettingsStore';
import { DateUtil } from '../common/DateUtil';
import { OptionItem, OptionSheet } from '../components/OptionSheet';
import { ThemePalette } from '../common/Theme';

@Entry
@Component
struct BrewFormPage {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @State method: string = '';
  @State fieldConfig: BrewFieldConfig = new BrewFieldConfig();
  @State beanId: number = -1;
  @State beanName: string = '';
  @State dose: string = '';
  @State waterAmount: string = '';
  @State waterTemp: string = '';
  @State grindSize: string = '';
  @State brewDuration: string = '';
  @State rating: number = 0;
  @State notes: string = '';
  @State brewDate: number = Date.now();
  @State errorText: string = '';
  @State showMethodSheet: boolean = false;
  @State showBeanSheet: boolean = false;
  @State showGrindSheet: boolean = false;
  private editId: number = -1;
  private methodOptions: OptionItem[] = [];
  private grindOptions: OptionItem[] = [];
  private beanOptions: OptionItem[] = [];
  private beans: CoffeeBean[] = [];

  aboutToAppear(): void {
    this.methodOptions = BrewMethod.ALL.map((m: string): OptionItem => {
      const it = new OptionItem();
      it.icon = '☕';
      it.label = m;
      it.action = (): void => {
        this.setMethod(m);
      };
      return it;
    });
    this.grindOptions = GrindSize.ALL.map((g: string): OptionItem => {
      const it = new OptionItem();
      it.icon = '⚙';
      it.label = g;
      it.action = (): void => {
        this.grindSize = g;
      };
      return it;
    });
    if (this.method.length === 0) {
      this.setMethod(SettingsStore.getInstance().getDefaultBrewMethod());
    }
    CoffeeDb.getInstance().queryBeans().then((list: CoffeeBean[]) => {
      this.beans = list;
      this.beanOptions = this.buildBeanOptions(list);
    }).catch((e: BusinessError) => {
      console.error(`load beans failed: ${e.code}`);
    });
    const params = this.getUIContext().getRouter().getParams() as FormParams;
    const id: number = params?.id ?? -1;
    if (id > 0) {
      this.editId = id;
      CoffeeDb.getInstance().queryBrews().then((list: BrewRecord[]) => {
        const found: BrewRecord | undefined = list.find((r: BrewRecord): boolean => r.id === id);
        if (found !== undefined) {
          this.setMethod(found.method);
          this.beanId = found.beanId;
          this.beanName = found.beanName;
          this.dose = found.dose > 0 ? `${found.dose}` : '';
          this.waterAmount = found.waterAmount > 0 ? `${found.waterAmount}` : '';
          this.waterTemp = found.waterTemp > 0 ? `${found.waterTemp}` : '';
          this.grindSize = found.grindSize;
          this.brewDuration = found.brewDuration > 0 ? `${found.brewDuration}` : '';
          this.rating = found.rating;
          this.notes = found.notes;
          this.brewDate = found.brewDate > 0 ? found.brewDate : Date.now();
        }
      }).catch((e: BusinessError) => {
        console.error(`load brew failed: ${e.code}`);
      });
    }
  }

  private buildBeanOptions(list: CoffeeBean[]): OptionItem[] {
    const options: OptionItem[] = [];
    const none: OptionItem = new OptionItem();
    none.icon = '🚫';
    none.label = '不关联咖啡豆';
    none.action = (): void => {
      this.beanId = -1;
      this.beanName = '';
    };
    options.push(none);
    for (let i = 0; i < list.length; i++) {
      const b: CoffeeBean = list[i];
      const it: OptionItem = new OptionItem();
      it.icon = '🫘';
      it.label = b.name.length > 0 ? `${b.name}（${b.variety}）` : b.variety;
      const capturedId: number = b.id;
      const capturedName: string = it.label;
      it.action = (): void => {
        this.beanId = capturedId;
        this.beanName = capturedName;
      };
      options.push(it);
    }
    return options;
  }

  private setMethod(m: string): void {
    this.method = m;
    this.fieldConfig = BrewFieldConfig.of(m);
  }

  private openSheet(key: string): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      if (key === 'method') {
        this.showMethodSheet = true;
      } else if (key === 'bean') {
        this.showBeanSheet = true;
      } else if (key === 'grind') {
        this.showGrindSheet = true;
      }
    });
  }

  private closeSheet(key: string): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      if (key === 'method') {
        this.showMethodSheet = false;
      } else if (key === 'bean') {
        this.showBeanSheet = false;
      } else if (key === 'grind') {
        this.showGrindSheet = false;
      }
    });
  }

  private pickDate(): void {
    this.getUIContext().showDatePickerDialog({
      selected: new Date(this.brewDate),
      onAccept: (value: DatePickerResult) => {
        const current: Date = new Date(this.brewDate);
        const y: number = value.year ?? current.getFullYear();
        const m: number = value.month ?? (current.getMonth() + 1);
        const d: number = value.day ?? current.getDate();
        this.brewDate = new Date(y, m - 1, d, 12, 0, 0).getTime();
      }
    });
  }

  private durationHint(): string {
    const t: string = this.brewDuration.trim();
    if (t.length === 0) {
      return '';
    }
    const n: number = Number(t);
    if (Number.isNaN(n) || n <= 0) {
      return '';
    }
    return `= ${DateUtil.formatDuration(n)}`;
  }

  private save(): void {
    if (this.method.length === 0) {
      this.errorText = '请选择冲煮方式';
      return;
    }
    let doseNum: number = 0;
    let waterNum: number = 0;
    let tempNum: number = 0;
    let durationNum: number = 0;
    doseNum = this.parseNum(this.dose, '粉量');
    if (doseNum < 0) {
      return;
    }
    waterNum = this.parseNum(this.waterAmount, '水量');
    if (waterNum < 0) {
      return;
    }
    tempNum = this.parseNum(this.waterTemp, '水温');
    if (tempNum < 0) {
      return;
    }
    durationNum = this.parseNum(this.brewDuration, this.fieldConfig.durationLabel);
    if (durationNum < 0) {
      return;
    }
    const r: BrewRecord = BrewRecord.of(this.brewDate, this.method);
    r.beanId = this.beanId;
    r.beanName = this.beanName.trim();
    r.dose = doseNum;
    r.waterAmount = waterNum;
    r.waterTemp = tempNum;
    r.grindSize = this.grindSize;
    r.brewDuration = durationNum;
    r.rating = this.rating;
    r.notes = this.notes.trim();
    r.id = this.editId;
    const task: Promise<number> = this.editId > 0 ?
      CoffeeDb.getInstance().updateBrew(r) :
      CoffeeDb.getInstance().addBrew(r);
    task.then(() => {
      AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
      this.getUIContext().getPromptAction().showToast({ message: '已保存' });
      this.getUIContext().getRouter().back();
    }).catch((e: BusinessError) => {
      this.errorText = '保存失败，请重试';
      console.error(`save brew failed: ${e.code}`);
    });
  }

  private parseNum(s: string, label: string): number {
    const t: string = s.trim();
    if (t.length === 0) {
      return 0;
    }
    const n: number = Number(t);
    if (Number.isNaN(n) || n < 0) {
      this.errorText = `${label}格式不正确`;
      return -1;
    }
    return n;
  }

  @Builder
  fieldLabel(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor($r('app.color.text_secondary'))
      .width(80)
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
          Text(this.editId > 0 ? '编辑冲煮' : '记录冲煮')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 10 })

        Scroll() {
          Column({ space: 12 }) {
            Row({ space: 10 }) {
              this.fieldLabel('冲煮时间')
              Text(DateUtil.formatDate(this.brewDate))
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
              this.fieldLabel('冲煮方式 *')
              Text(this.method.length > 0 ? this.method : '点击选择')
                .fontSize(15)
                .fontColor(this.method.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_hint'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .padding({ left: 12, right: 12, top: 12, bottom: 12 })
                .backgroundColor($r('app.color.input_background'))
                .borderRadius(12)
                .onClick(() => {
                  this.openSheet('method');
                })
            }
            .width('100%')

            Row({ space: 10 }) {
              this.fieldLabel('咖啡豆')
              Text(this.beanName.length > 0 ? this.beanName : '不关联')
                .fontSize(15)
                .fontColor(this.beanName.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_hint'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 12, right: 12, top: 12, bottom: 12 })
                .backgroundColor($r('app.color.input_background'))
                .borderRadius(12)
                .onClick(() => {
                  this.openSheet('bean');
                })
            }
            .width('100%')

            Row({ space: 10 }) {
              this.fieldLabel('粉量（g）')
              TextInput({ placeholder: '如：15（选填）', text: this.dose })
                .layoutWeight(1)
                .backgroundColor($r('app.color.input_background'))
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_hint'))
                .caretColor(this.themeColor)
                .borderRadius(12)
                .onChange((value: string) => {
                  this.dose = value;
                })
            }
            .width('100%')

            if (this.fieldConfig.showWater) {
              Row({ space: 10 }) {
                this.fieldLabel('水量（g）')
                TextInput({ placeholder: '如：225（选填）', text: this.waterAmount })
                  .layoutWeight(1)
                  .backgroundColor($r('app.color.input_background'))
                  .fontColor($r('app.color.text_primary'))
                  .placeholderColor($r('app.color.text_hint'))
                  .caretColor(this.themeColor)
                  .borderRadius(12)
                  .onChange((value: string) => {
                    this.waterAmount = value;
                  })
              }
              .width('100%')
            }

            if (this.fieldConfig.showTemp) {
              Row({ space: 10 }) {
                this.fieldLabel('水温（℃）')
                TextInput({ placeholder: '如：92（选填）', text: this.waterTemp })
                  .layoutWeight(1)
                  .backgroundColor($r('app.color.input_background'))
                  .fontColor($r('app.color.text_primary'))
                  .placeholderColor($r('app.color.text_hint'))
                  .caretColor(this.themeColor)
                  .borderRadius(12)
                  .onChange((value: string) => {
                    this.waterTemp = value;
                  })
              }
              .width('100%')
            }

            Row({ space: 10 }) {
              this.fieldLabel('研磨度')
              Text(this.grindSize.length > 0 ? this.grindSize : '点击选择')
                .fontSize(15)
                .fontColor(this.grindSize.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_hint'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .padding({ left: 12, right: 12, top: 12, bottom: 12 })
                .backgroundColor($r('app.color.input_background'))
                .borderRadius(12)
                .onClick(() => {
                  this.openSheet('grind');
                })
            }
            .width('100%')

            Row({ space: 10 }) {
              this.fieldLabel(`${this.fieldConfig.durationLabel}（秒）`)
              TextInput({ placeholder: '如：150（选填）', text: this.brewDuration })
                .layoutWeight(1)
                .backgroundColor($r('app.color.input_background'))
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_hint'))
                .caretColor(this.themeColor)
                .borderRadius(12)
                .onChange((value: string) => {
                  this.brewDuration = value;
                })
            }
            .width('100%')

            if (this.durationHint().length > 0) {
              Text(this.durationHint())
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .padding({ left: 90 })
            }

            Row({ space: 10 }) {
              this.fieldLabel('评分')
              Row({ space: 6 }) {
                ForEach([1, 2, 3, 4, 5], (n: number) => {
                  Text(n <= this.rating ? '★' : '☆')
                    .fontSize(26)
                    .fontColor(n <= this.rating ? this.themeColor : $r('app.color.text_disabled'))
                    .onClick(() => {
                      this.rating = n === this.rating ? 0 : n;
                    })
                }, (n: number): string => `star_${n}`)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.End)
            }
            .width('100%')

            Column({ space: 8 }) {
              Text('备注')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              TextArea({ placeholder: '今天这杯的感受…（选填）', text: this.notes })
                .width('100%')
                .height(90)
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

      if (this.showMethodSheet) {
        OptionSheet({
          title: '冲煮方式',
          options: this.methodOptions,
          onClose: (): void => {
            this.closeSheet('method');
          }
        })
      }

      if (this.showBeanSheet) {
        OptionSheet({
          title: '选择咖啡豆',
          options: this.beanOptions,
          onClose: (): void => {
            this.closeSheet('bean');
          }
        })
      }

      if (this.showGrindSheet) {
        OptionSheet({
          title: '研磨度',
          options: this.grindOptions,
          onClose: (): void => {
            this.closeSheet('grind');
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemePalette.page(this.themeColor, this.isDarkMode))
  }
}
