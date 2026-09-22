import { BusinessError } from '@kit.BasicServicesKit';
import { BrewRecord, BrewMethod, BrewFieldConfig, GrindSize, HeatLevel, CoffeeBean, PourPlan } from '../model/Models';
import { FormParams } from '../model/RouteParams';
import { CoffeeDb } from '../data/CoffeeDb';
import { SettingsStore } from '../data/SettingsStore';
import { DateUtil } from '../common/DateUtil';
import { OptionItem, OptionSheet } from '../components/OptionSheet';
import { ThemePalette } from '../common/Theme';

interface InputRowOptions {
  label: string;
  placeholder: string;
  text: string;
  onChange: (v: string) => void;
}

interface SelectRowOptions {
  label: string;
  value: string;
  placeholder: string;
  onTap: () => void;
}

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
  @State yieldAmount: string = '';
  @State heatLevel: string = '';
  @State pourCount: string = '';
  @State pourWaters: string[] = ['', '', '', '', ''];
  @State pourTimes: string[] = ['', '', '', '', ''];
  @State bloomWater: string = '';
  @State bloomTime: string = '';
  @State pressure: string = '';
  @State steepValue: string = '';
  @State pressSeconds: string = '';
  @State rating: number = 0;
  @State notes: string = '';
  @State brewDate: number = Date.now();
  @State errorText: string = '';
  @State showMethodSheet: boolean = false;
  @State showBeanSheet: boolean = false;
  @State showGrindSheet: boolean = false;
  @State showHeatSheet: boolean = false;
  private editId: number = -1;
  private methodOptions: OptionItem[] = [];
  private grindOptions: OptionItem[] = [];
  private heatOptions: OptionItem[] = [];
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
    this.heatOptions = HeatLevel.ALL.map((h: string): OptionItem => {
      const it = new OptionItem();
      it.icon = '🔥';
      it.label = h;
      it.action = (): void => {
        this.heatLevel = h;
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
          this.yieldAmount = found.yieldAmount > 0 ? `${found.yieldAmount}` : '';
          this.heatLevel = found.heatLevel;
          this.pourCount = found.pourCount > 0 ? `${found.pourCount}` : '';
          this.pourWaters = [
            found.pour1Water > 0 ? `${found.pour1Water}` : '',
            found.pour2Water > 0 ? `${found.pour2Water}` : '',
            found.pour3Water > 0 ? `${found.pour3Water}` : '',
            found.pour4Water > 0 ? `${found.pour4Water}` : '',
            found.pour5Water > 0 ? `${found.pour5Water}` : ''
          ];
          this.pourTimes = [
            found.pour1Time > 0 ? `${found.pour1Time}` : '',
            found.pour2Time > 0 ? `${found.pour2Time}` : '',
            found.pour3Time > 0 ? `${found.pour3Time}` : '',
            found.pour4Time > 0 ? `${found.pour4Time}` : '',
            found.pour5Time > 0 ? `${found.pour5Time}` : ''
          ];
          this.bloomWater = found.bloomWater > 0 ? `${found.bloomWater}` : '';
          this.bloomTime = found.bloomTime > 0 ? `${found.bloomTime}` : '';
          this.pressure = found.pressure > 0 ? `${found.pressure}` : '';
          this.steepValue = found.steepHours > 0 ? `${found.steepHours}` :
            (found.steepMinutes > 0 ? `${found.steepMinutes}` : '');
          this.pressSeconds = found.pressSeconds > 0 ? `${found.pressSeconds}` : '';
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
      } else if (key === 'heat') {
        this.showHeatSheet = true;
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
      } else if (key === 'heat') {
        this.showHeatSheet = false;
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
    if (!this.fieldConfig.showDuration) {
      return '';
    }
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

  private pourRowCount(): number {
    const t: string = this.pourCount.trim();
    if (t.length === 0) {
      return 0;
    }
    const n: number = Number(t);
    if (Number.isNaN(n) || n < 1) {
      return 0;
    }
    return Math.min(Math.floor(n), PourPlan.MAX);
  }

  private pourRowIndices(): number[] {
    const indices: number[] = [];
    const n: number = this.pourRowCount();
    for (let i: number = 1; i <= n; i++) {
      indices.push(i);
    }
    return indices;
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

  private save(): void {
    if (this.method.length === 0) {
      this.errorText = '请选择冲煮方式';
      return;
    }
    const cfg: BrewFieldConfig = this.fieldConfig;
    let doseNum: number = 0;
    let waterNum: number = 0;
    let tempNum: number = 0;
    let durationNum: number = 0;
    let yieldNum: number = 0;
    let pourCountNum: number = 0;
    const pourWaterNums: number[] = [0, 0, 0, 0, 0];
    const pourTimeNums: number[] = [0, 0, 0, 0, 0];
    let bloomWaterNum: number = 0;
    let bloomTimeNum: number = 0;
    let pressureNum: number = 0;
    let steepNum: number = 0;
    let pressNum: number = 0;
    doseNum = this.parseNum(this.dose, '粉量');
    if (doseNum < 0) {
      return;
    }
    if (cfg.showWater) {
      waterNum = this.parseNum(this.waterAmount, '水量');
      if (waterNum < 0) {
        return;
      }
    }
    if (cfg.showTemp) {
      tempNum = this.parseNum(this.waterTemp, '水温');
      if (tempNum < 0) {
        return;
      }
    }
    if (cfg.showDuration) {
      durationNum = this.parseNum(this.brewDuration, cfg.durationLabel);
      if (durationNum < 0) {
        return;
      }
    }
    if (cfg.showYield) {
      yieldNum = this.parseNum(this.yieldAmount, cfg.yieldLabel);
      if (yieldNum < 0) {
        return;
      }
    }
    if (cfg.showPourPlan) {
      pourCountNum = this.parseNum(this.pourCount, '注水次数');
      if (pourCountNum < 0) {
        return;
      }
      if (pourCountNum > PourPlan.MAX) {
        this.errorText = `注水次数最多 ${PourPlan.MAX} 次`;
        return;
      }
      for (let i: number = 1; i <= pourCountNum; i++) {
        const cn: string = PourPlan.CN[i - 1];
        const wNum: number = this.parseNum(this.pourWaters[i - 1], `第${cn}次注水量`);
        if (wNum < 0) {
          return;
        }
        pourWaterNums[i - 1] = wNum;
        const tNum: number = this.parseNum(this.pourTimes[i - 1], `第${cn}次注水时间`);
        if (tNum < 0) {
          return;
        }
        pourTimeNums[i - 1] = tNum;
      }
    }
    if (cfg.showBloom) {
      bloomWaterNum = this.parseNum(this.bloomWater, '闷蒸水量');
      if (bloomWaterNum < 0) {
        return;
      }
      bloomTimeNum = this.parseNum(this.bloomTime, '闷蒸时长');
      if (bloomTimeNum < 0) {
        return;
      }
    }
    if (cfg.showPressure) {
      pressureNum = this.parseNum(this.pressure, '压力');
      if (pressureNum < 0) {
        return;
      }
    }
    if (cfg.showSteep) {
      steepNum = this.parseNum(this.steepValue, cfg.steepLabel);
      if (steepNum < 0) {
        return;
      }
    }
    if (cfg.showPressTime) {
      pressNum = this.parseNum(this.pressSeconds, '压下时长');
      if (pressNum < 0) {
        return;
      }
    }
    const r: BrewRecord = BrewRecord.of(this.brewDate, this.method);
    r.beanId = this.beanId;
    r.beanName = this.beanName.trim();
    r.dose = doseNum;
    r.waterAmount = waterNum;
    r.waterTemp = tempNum;
    r.grindSize = this.grindSize;
    r.brewDuration = durationNum;
    r.yieldAmount = yieldNum;
    r.heatLevel = this.heatLevel;
    r.pourCount = pourCountNum;
    for (let i: number = 1; i <= PourPlan.MAX; i++) {
      r.setPourWaterAt(i, i <= pourCountNum ? pourWaterNums[i - 1] : 0);
      r.setPourTimeAt(i, i <= pourCountNum ? pourTimeNums[i - 1] : 0);
    }
    r.bloomWater = bloomWaterNum;
    r.bloomTime = bloomTimeNum;
    r.pressure = pressureNum;
    if (this.method === BrewMethod.COLD_BREW) {
      r.steepHours = steepNum;
    } else {
      r.steepMinutes = steepNum;
    }
    r.pressSeconds = pressNum;
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

  @Builder
  fieldLabel(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor($r('app.color.text_secondary'))
      .constraintSize({ minWidth: 88 })
  }

  @Builder
  inputRow($$: InputRowOptions) {
    Row({ space: 10 }) {
      this.fieldLabel($$.label)
      TextInput({ placeholder: $$.placeholder, text: $$.text })
        .layoutWeight(1)
        .backgroundColor($r('app.color.input_background'))
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_hint'))
        .caretColor(this.themeColor)
        .borderRadius(12)
        .onChange((value: string) => {
          $$.onChange(value);
        })
    }
    .width('100%')
  }

  @Builder
  selectRow($$: SelectRowOptions) {
    Row({ space: 10 }) {
      this.fieldLabel($$.label)
      Text($$.value.length > 0 ? $$.value : $$.placeholder)
        .fontSize(15)
        .fontColor($$.value.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_hint'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .backgroundColor($r('app.color.input_background'))
        .borderRadius(12)
        .onClick(() => {
          $$.onTap();
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

            this.selectRow({ label: '冲煮方式 *', value: this.method, placeholder: '点击选择',
              onTap: (): void => {
                this.openSheet('method');
              } })

            this.selectRow({ label: '咖啡豆', value: this.beanName, placeholder: '不关联',
              onTap: (): void => {
                this.openSheet('bean');
              } })

            this.inputRow({ label: '粉量（g）', placeholder: '如：15（选填）', text: this.dose,
              onChange: (v: string): void => {
                this.dose = v;
              } })

            if (this.fieldConfig.showPourPlan) {
              this.inputRow({ label: '注水次数', placeholder: `1-${PourPlan.MAX} 次（选填）`, text: this.pourCount,
                onChange: (v: string): void => {
                  this.pourCount = v;
                } })

              ForEach(this.pourRowIndices(), (i: number) => {
                Column({ space: 12 }) {
                  Row({ space: 10 }) {
                    this.fieldLabel(`第${PourPlan.CN[i - 1]}次水量（g）`)
                    TextInput({ placeholder: '如：30（选填）', text: this.pourWaters[i - 1] })
                      .layoutWeight(1)
                      .backgroundColor($r('app.color.input_background'))
                      .fontColor($r('app.color.text_primary'))
                      .placeholderColor($r('app.color.text_hint'))
                      .caretColor(this.themeColor)
                      .borderRadius(12)
                      .onChange((value: string) => {
                        this.pourWaters[i - 1] = value;
                      })
                  }
                  .width('100%')

                  Row({ space: 10 }) {
                    this.fieldLabel(`第${PourPlan.CN[i - 1]}次时间（秒）`)
                    TextInput({ placeholder: '如：10（选填）', text: this.pourTimes[i - 1] })
                      .layoutWeight(1)
                      .backgroundColor($r('app.color.input_background'))
                      .fontColor($r('app.color.text_primary'))
                      .placeholderColor($r('app.color.text_hint'))
                      .caretColor(this.themeColor)
                      .borderRadius(12)
                      .onChange((value: string) => {
                        this.pourTimes[i - 1] = value;
                      })
                  }
                  .width('100%')
                }
                .width('100%')
              }, (i: number): string => `pour_${i}`)
            }

            if (this.fieldConfig.showBloom) {
              this.inputRow({ label: '闷蒸水量（g）', placeholder: '如：30（选填）', text: this.bloomWater,
                onChange: (v: string): void => {
                  this.bloomWater = v;
                } })
              this.inputRow({ label: '闷蒸时长（秒）', placeholder: '如：30（选填）', text: this.bloomTime,
                onChange: (v: string): void => {
                  this.bloomTime = v;
                } })
            }

            if (this.fieldConfig.showWater) {
              this.inputRow({ label: this.fieldConfig.waterLabel, placeholder: '如：225（选填）',
                text: this.waterAmount,
                onChange: (v: string): void => {
                  this.waterAmount = v;
                } })
            }

            if (this.fieldConfig.showTemp) {
              this.inputRow({ label: '水温（℃）', placeholder: '如：92（选填）', text: this.waterTemp,
                onChange: (v: string): void => {
                  this.waterTemp = v;
                } })
            }

            if (this.fieldConfig.showSteep) {
              this.inputRow({ label: this.fieldConfig.steepLabel, placeholder: '如：12（选填）',
                text: this.steepValue,
                onChange: (v: string): void => {
                  this.steepValue = v;
                } })
            }

            if (this.fieldConfig.showPressTime) {
              this.inputRow({ label: '压下时长（秒）', placeholder: '如：30（选填）', text: this.pressSeconds,
                onChange: (v: string): void => {
                  this.pressSeconds = v;
                } })
            }

            if (this.fieldConfig.showPressure) {
              this.inputRow({ label: '压力（bar）', placeholder: '如：9（选填）', text: this.pressure,
                onChange: (v: string): void => {
                  this.pressure = v;
                } })
            }

            if (this.fieldConfig.showGrind) {
              this.selectRow({ label: '研磨度', value: this.grindSize, placeholder: '点击选择（选填）',
                onTap: (): void => {
                  this.openSheet('grind');
                } })
            }

            if (this.fieldConfig.showDuration) {
              this.inputRow({ label: `${this.fieldConfig.durationLabel}（秒）`, placeholder: '如：150（选填）',
                text: this.brewDuration,
                onChange: (v: string): void => {
                  this.brewDuration = v;
                } })
            }

            if (this.durationHint().length > 0) {
              Text(this.durationHint())
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .padding({ left: 98 })
            }

            if (this.fieldConfig.showYield) {
              this.inputRow({ label: this.fieldConfig.yieldLabel, placeholder: '如：200（选填）',
                text: this.yieldAmount,
                onChange: (v: string): void => {
                  this.yieldAmount = v;
                } })
            }

            if (this.fieldConfig.showHeat) {
              this.selectRow({ label: '火候', value: this.heatLevel, placeholder: '点击选择（选填）',
                onTap: (): void => {
                  this.openSheet('heat');
                } })
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
              Text('口感备注')
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

      if (this.showHeatSheet) {
        OptionSheet({
          title: '火候',
          options: this.heatOptions,
          onClose: (): void => {
            this.closeSheet('heat');
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemePalette.page(this.themeColor, this.isDarkMode))
  }
}
