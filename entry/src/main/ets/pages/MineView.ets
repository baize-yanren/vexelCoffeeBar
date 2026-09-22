import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ThemeColors, ThemePalette } from '../common/Theme';
import { AppInfo, AppInfoData } from '../common/AppInfo';
import { BrewMethod } from '../model/Models';
import { CoffeeDb } from '../data/CoffeeDb';
import { SettingsStore } from '../data/SettingsStore';
import { OptionItem, OptionSheet } from '../components/OptionSheet';
import { DataBackup, BackupData } from '../service/DataBackup';

interface GroupRowOptions {
  label: string;
  value: string;
  danger: boolean;
  onRowTap: () => void;
}

@Component
export struct MineView {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @State defaultMethod: string = '';
  @State appInfo: AppInfoData = new AppInfoData();
  @State showMethodSheet: boolean = false;
  @State autoClipboard: boolean = true;
  private methodOptions: OptionItem[] = [];

  aboutToAppear(): void {
    this.defaultMethod = SettingsStore.getInstance().getDefaultBrewMethod();
    this.autoClipboard = SettingsStore.getInstance().isAutoClipboard();
    const context = getContext(this) as common.UIAbilityContext;
    this.appInfo = AppInfo.load(context);
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

  private exportData(): void {
    const context = getContext(this) as common.UIAbilityContext;
    DataBackup.exportToFile(context).then((status: string) => {
      if (status === 'ok') {
        this.getUIContext().getPromptAction().showToast({ message: '已导出备份文件' });
      } else if (status === 'failed') {
        this.getUIContext().getPromptAction().showToast({ message: '导出失败，请重试' });
      }
    }).catch((e: BusinessError) => {
      console.error(`export failed: ${e.code}`);
      this.getUIContext().getPromptAction().showToast({ message: '导出失败，请重试' });
    });
  }

  private importData(): void {
    const context = getContext(this) as common.UIAbilityContext;
    DataBackup.importFromFile(context).then((data: BackupData | undefined) => {
      if (data === undefined) {
        return;
      }
      this.confirmImport(data);
    }).catch((e: BusinessError) => {
      console.error(`import read failed: ${e.code}`);
      this.getUIContext().getPromptAction().showToast({ message: '文件读取失败或格式不正确' });
    });
  }

  private confirmImport(data: BackupData): void {
    this.getUIContext().showAlertDialog({
      title: '导入数据',
      message: `备份包含 ${data.beans.length} 条咖啡豆、${data.equipments.length} 条器具、` +
        `${data.brews.length} 条冲煮记录，导入后将覆盖当前全部数据。确定继续吗？`,
      primaryButton: {
        value: '导入',
        action: (): void => {
          CoffeeDb.getInstance().restoreAll(data.beans, data.equipments, data.brews).then(() => {
            AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
            this.getUIContext().getPromptAction().showToast({ message: '导入成功' });
          }).catch((e: BusinessError) => {
            console.error(`restore failed: ${e.code}`);
            this.getUIContext().getPromptAction().showToast({ message: '导入失败，请重试' });
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
  groupRow($$: GroupRowOptions) {
    Row() {
      Text($$.label)
        .fontSize(15)
        .fontColor($$.danger ? $r('app.color.danger_color') : $r('app.color.text_primary'))
        .layoutWeight(1)
      if ($$.value.length > 0) {
        Text($$.value)
          .fontSize(14)
          .fontColor($r('app.color.text_tertiary'))
      }
      Text('›')
        .fontSize(16)
        .fontColor($r('app.color.text_disabled'))
        .margin({ left: 6 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 15, bottom: 15 })
    .onClick(() => {
      $$.onRowTap();
    })
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 6 }) {
            Text('☕')
              .fontSize(52)
            Text(this.appInfo.name)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(this.appInfo.slogan)
              .fontSize(13)
              .fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .margin({ top: 28, bottom: 8 })

          Column() {
            Column({ space: 12 }) {
              Text('主题色')
                .fontSize(15)
                .fontColor($r('app.color.text_primary'))
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
                      { radius: 6, color: ThemePalette.alpha(c, 0.5) } :
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
              .color($r('app.color.divider_color'))
              .margin({ left: 16, right: 16 })

            this.groupRow({ label: '默认冲煮方式', value: this.defaultMethod, danger: false,
              onRowTap: (): void => {
                this.openMethodSheet();
              } })

            Divider()
              .color($r('app.color.divider_color'))
              .margin({ left: 16, right: 16 })

            Row() {
              Column({ space: 4 }) {
                Text('自动检测剪贴板')
                  .fontSize(15)
                  .fontColor($r('app.color.text_primary'))
                Text('复制商品链接后打开咖啡志，自动识别并预填')
                  .fontSize(11)
                  .fontColor($r('app.color.text_hint'))
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.autoClipboard })
                .selectedColor(this.themeColor)
                .switchPointColor('#FFFFFF')
                .onChange((value: boolean) => {
                  this.autoClipboard = value;
                  SettingsStore.getInstance().setAutoClipboard(value);
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 15, bottom: 15 })
            .alignItems(VerticalAlign.Center)

            Divider()
              .color($r('app.color.divider_color'))
              .margin({ left: 16, right: 16 })

            this.groupRow({ label: '清空数据', value: '', danger: true, onRowTap: (): void => {
              this.confirmClear();
            } })
          }
          .width('100%')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(16)
          .margin({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)

          Column() {
            this.groupRow({ label: '导出数据', value: '备份为 JSON 文件', danger: false, onRowTap: (): void => {
              this.exportData();
            } })
            Divider()
              .color($r('app.color.divider_color'))
              .margin({ left: 16, right: 16 })
            this.groupRow({ label: '导入数据', value: '从备份文件恢复', danger: false, onRowTap: (): void => {
              this.importData();
            } })
          }
          .width('100%')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(16)
          .margin({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)

          Text('导入将覆盖当前全部数据，请先导出备份')
            .fontSize(12)
            .fontColor($r('app.color.text_disabled'))
            .margin({ top: -8 })

          Column() {
            this.groupRow({ label: '版本信息', value: `v${this.appInfo.versionName}`, danger: false,
              onRowTap: (): void => {} })
            Divider()
              .color($r('app.color.divider_color'))
              .margin({ left: 16, right: 16 })
            this.groupRow({ label: '用户协议', value: '', danger: false, onRowTap: (): void => {
              this.getUIContext().getPromptAction().showToast({ message: this.appInfo.userAgreement });
            } })
            Divider()
              .color($r('app.color.divider_color'))
              .margin({ left: 16, right: 16 })
            this.groupRow({ label: '隐私政策', value: '', danger: false, onRowTap: (): void => {
              this.getUIContext().getPromptAction().showToast({ message: this.appInfo.privacyPolicy });
            } })
          }
          .width('100%')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(16)
          .margin({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)

          Text('深色模式跟随系统设置')
            .fontSize(12)
            .fontColor($r('app.color.text_disabled'))
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
