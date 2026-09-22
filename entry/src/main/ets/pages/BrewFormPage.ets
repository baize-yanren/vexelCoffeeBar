import { BusinessError } from '@kit.BasicServicesKit';
import { BrewRecord, BrewMethod, BrewFieldConfig, GrindSize, HeatLevel, CoffeeBean } from '../model/Models';
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
  @State yieldAmount: string = '';
  @State heatLevel: string = '';
  @State pourCount: string = '';
  @State pour1Water: string = '';
  @State pour1Time: string = '';
  @State pour2Water: string = '';
  @State pour2Time: string = '';
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
          this.pour1Water = found.pour1Water > 0 ? `${found.pour1Water}` : '';
          this.pour1Time = found.pour1Time > 0 ? `${found.pour1Time}` : '';
          this.pour2Water = found.pour2Water > 0 ? `${found.pour2Water}` : '';
          this.pour2Time = found.pour2Time > 0 ? `${found.pour2Time}` : '';
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
    let pour1WaterNum: number = 0;
    let pour1TimeNum: number = 0;
    let pour2WaterNum: number = 0;
    let pour2TimeNum: number = 0;
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
      pour1WaterNum = this.parseNum(this.pour1Water, '第一次注水量');
      if (pour1WaterNum < 0) {
        return;
      }
      pour1TimeNum = this.parseNum(this.pour1Time, '第一次注水时间');
      if (pour1TimeNum < 0) {
        return;
      }
      pour2WaterNum = this.parseNum(this.pour2Water, '第二次注水量');
      if (pour2WaterNum < 0) {
        return;
      }
      pour2TimeNum = this.parseNum(this.pour2Time, '第二次注水时间');
      if (pour2TimeNum < 0) {
        return;
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
    r.pour1Water = pour1WaterNum;
    r.pour1Time = pour1TimeNum;
    r.pour2Water = pour2WaterNum;
    r.pour2Time = pour2TimeNum;
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

            this.selectRow('冲煮方式 *', this.method, '点击选择', (): void => {
              this.openSheet('method');
            })

            this.selectRow('咖啡豆', this.beanName, '不关联', (): void => {
              this.openSheet('bean');
            })

            this.inputRow('粉量（g）', '如：15（选填）', this.dose, (v: string): void => {
              this.dose = v;
            })

            if (this.fieldConfig.showPourPlan) {
              this.inputRow('注水次数', '如：3（选填）', this.pourCount, (v: string): void => {
                this.pourCount = v;
              })
              this.inputRow('第一次水量（g）', '如：30（选填）', this.pour1Water, (v: string): void => {
                this.pour1Water = v;
              })
              this.inputRow('第一次时间（秒）', '如：10（选填）', this.pour1Time, (v: string): void => {
                this.pour1Time = v;
              })
              this.inputRow('第二次水量（g）', '如：60（选填）', this.pour2Water, (v: string): void => {
                this.pour2Water = v;
              })
              this.inputRow('第二次时间（秒）', '如：20（选填）', this.pour2Time, (v: string): void => {
                this.pour2Time = v;
              })
            }

            if (this.fieldConfig.showBloom) {
              this.inputRow('闷蒸水量（g）', '如：30（选填）', this.bloomWater, (v: string): void => {
                this.bloomWater = v;
              })
              this.inputRow('闷蒸时长（秒）', '如：30（选填）', this.bloomTime, (v: string): void => {
                this.bloomTime = v;
              })
            }

            if (this.fieldConfig.showWater) {
              this.inputRow(this.fieldConfig.waterLabel, '如：225（选填）', this.waterAmount, (v: string): void => {
                this.waterAmount = v;
              })
            }

            if (this.fieldConfig.showTemp) {
              this.inputRow('水温（℃）', '如：92（选填）', this.waterTemp, (v: string): void => {
                this.waterTemp = v;
              })
            }

            if (this.fieldConfig.showSteep) {
              this.inputRow(this.fieldConfig.steepLabel, '如：12（选填）', this.steepValue, (v: string): void => {
                this.steepValue = v;
              })
            }

            if (this.fieldConfig.showPressTime) {
              this.inputRow('压下时长（秒）', '如：30（选填）', this.pressSeconds, (v: string): void => {
                this.pressSeconds = v;
              })
            }

            if (this.fieldConfig.showPressure) {
              this.inputRow('压力（bar）', '如：9（选填）', this.pressure, (v: string): void => {
                this.pressure = v;
              })
            }

            if (this.fieldConfig.showGrind) {
              this.selectRow('研磨度', this.grindSize, '点击选择（选填）', (): void => {
                this.openSheet('grind');
              })
            }

            if (this.fieldConfig.showDuration) {
              this.inputRow(`${this.fieldConfig.durationLabel}（秒）`, '如：150（选填）', this.brewDuration,
                (v: string): void => {
                  this.brewDuration = v;
                })
            }

            if (this.durationHint().length > 0) {
              Text(this.durationHint())
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .padding({ left: 98 })
            }

            if (this.fieldConfig.showYield) {
              this.inputRow(this.fieldConfig.yieldLabel, '如：200（选填）', this.yieldAmount, (v: string): void => {
                this.yieldAmount = v;
              })
            }

            if (this.fieldConfig.showHeat) {
              this.selectRow('火候', this.heatLevel, '点击选择（选填）', (): void => {
                this.openSheet('heat');
              })
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
