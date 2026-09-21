import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ThemeColors } from '../common/Theme';
import { BrewMethod } from '../model/Models';
import { CoffeeDb } from '../data/CoffeeDb';
import { SettingsStore } from '../data/SettingsStore';
import { OptionItem, OptionSheet } from '../components/OptionSheet';

@Component
export struct MineView {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @State defaultMethod: string = '';
  @State version: string = '1.0.0';
  @State showMethodSheet: boolean = false;
  @State autoClipboard: boolean = true;
  private methodOptions: OptionItem[] = [];

  aboutToAppear(): void {
    this.defaultMethod = SettingsStore.getInstance().getDefaultBrewMethod();
    this.autoClipboard = SettingsStore.getInstance().isAutoClipboard();
    this.methodOptions = BrewMethod.ALL.map((m: string): OptionItem => {
      const it = new OptionItem();
      it.icon = '☕';
      it.label = m;
      it.action = (): void => {
        SettingsStore.getInstance().setDefaultBrewMethod(m);
        this.defaultMethod = m;
        this.getUIContext().getPromptAction().showToast({ message: `默认冲煮方式已设为「${m}」` });
      };
      return it;
    });
    try {
      const info: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      this.version = info.versionName;
    } catch (e) {
      console.error(`get version failed: ${(e as BusinessError).code}`);
    }
  }

  private openMethodSheet(): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showMethodSheet = true;
    });
  }

  private closeMethodSheet(): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showMethodSheet = false;
    });
  }

  private confirmClear(): void {
    this.getUIContext().showAlertDialog({
      title: '清空数据',
      message: '将删除全部咖啡豆、器具与冲煮记录，且不可恢复。确定继续吗？',
      primaryButton: {
        value: '清空',
        action: (): void => {
          CoffeeDb.getInstance().clearAll().then(() => {
            AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
            this.getUIContext().getPromptAction().showToast({ message: '已清空全部数据' });
          }).catch((e: BusinessError) => {
            console.error(`clear failed: ${e.code}`);
          });
        }
      },
      secondaryButton: {
        value: '取消',
        action: (): void => {}
      }
    });
  }

  @Builder
  groupRow(label: string, value: string, danger: boolean, onRowTap: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(danger ? '#D9480F' : '#333333')
        .layoutWeight(1)
      if (value.length > 0) {
        Text(value)
          .fontSize(14)
          .fontColor('#999999')
      }
      Text('›')
        .fontSize(16)
        .fontColor('#CCCCCC')
        .margin({ left: 6 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 15, bottom: 15 })
    .onClick(() => {
      onRowTap();
    })
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 6 }) {
            Text('☕')
              .fontSize(52)
            Text('咖啡志')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text('记录每一杯咖啡的美好')
              .fontSize(13)
              .fontColor('#999999')
          }
          .width('100%')
          .margin({ top: 28, bottom: 8 })

          Column() {
            Column({ space: 12 }) {
              Text('主题色')
                .fontSize(15)
                .fontColor('#333333')
              Row({ space: 12 }) {
                ForEach(ThemeColors.PRESETS, (c: string) => {
                  Text(c === this.themeColor ? '✓' : '')
                    .fontSize(13)
                    .fontColor('#FFFFFF')
                    .textAlign(TextAlign.Center)
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .backgroundColor(c)
                    .shadow(this.themeColor === c ?
                      { radius: 6, color: 'rgba(0,0,0,0.25)' } :
                      { radius: 0, color: 'rgba(0,0,0,0)' })
                    .onClick(() => {
                      SettingsStore.getInstance().setThemeColor(c);
                    })
                }, (c: string): string => `color_${c}`)
              }
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding(16)
            .alignItems(HorizontalAlign.Start)

            Divider()
              .color('#F0ECE6')
              .margin({ left: 16, right: 16 })

            this.groupRow('默认冲煮方式', this.defaultMethod, false, (): void => {
              this.openMethodSheet();
            })

            Divider()
              .color('#F0ECE6')
              .margin({ left: 16, right: 16 })

            Row() {
              Column({ space: 4 }) {
                Text('自动检测剪贴板')
                  .fontSize(15)
                  .fontColor('#333333')
                Text('复制商品链接后打开咖啡志，自动识别并预填')
                  .fontSize(11)
                  .fontColor('#AAAAAA')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.autoClipboard })
                .onChange((value: boolean) => {
                  this.autoClipboard = value;
                  SettingsStore.getInstance().setAutoClipboard(value);
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 15, bottom: 15 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .color('#F0ECE6')
              .margin({ left: 16, right: 16 })

            this.groupRow('清空数据', '', true, (): void => {
              this.confirmClear();
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)

          Column() {
            this.groupRow('版本信息', `v${this.version}`, false, (): void => {})
            Divider()
              .color('#F0ECE6')
              .margin({ left: 16, right: 16 })
            this.groupRow('用户协议', '', false, (): void => {
              this.getUIContext().getPromptAction().showToast({ message: '开发中，敬请期待' });
            })
            Divider()
              .color('#F0ECE6')
              .margin({ left: 16, right: 16 })
            this.groupRow('隐私政策', '', false, (): void => {
              this.getUIContext().getPromptAction().showToast({ message: '开发中，敬请期待' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)

          Text('深色模式跟随系统设置')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 6 })
        }
        .width('100%')
        .padding({ bottom: 110 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)

      if (this.showMethodSheet) {
        OptionSheet({
          title: '默认冲煮方式',
          options: this.methodOptions,
          onClose: (): void => {
            this.closeMethodSheet();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
