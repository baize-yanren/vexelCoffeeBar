import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { FormParams } from '../model/RouteParams';
import { OptionItem, OptionSheet } from '../components/OptionSheet';
import { ImportPreviewSheet } from '../components/ImportPreviewSheet';
import { ImportDraft } from '../model/ImportDraft';
import { AppKeys, ThemePalette } from '../common/Theme';
import { CoffeeDb } from '../data/CoffeeDb';
import { SettingsStore } from '../data/SettingsStore';
import { ClipboardImport, ClipboardCheckResult } from '../service/ClipboardImport';
import { LibraryView } from './LibraryView';
import { BrewLogView } from './BrewLogView';
import { MineView } from './MineView';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State showAddSheet: boolean = false;
  @State showImportSheet: boolean = false;
  @State importDraft: ImportDraft = new ImportDraft();
  @State importCategory: string = 'unknown';
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  private tabController: TabsController = new TabsController();
  private addOptions: OptionItem[] = [];

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    CoffeeDb.getInstance().init(context).catch((e: BusinessError) => {
      console.error(`db init failed: ${e.code} ${e.message}`);
    });
    this.addOptions = [
      {
        icon: '🫘',
        label: '记录咖啡豆',
        action: (): void => {
          this.goForm('pages/BeanFormPage');
        }
      },
      {
        icon: '⚗️',
        label: '记录器具',
        action: (): void => {
          this.goForm('pages/EquipmentFormPage');
        }
      },
      {
        icon: '☕',
        label: '记录冲煮',
        action: (): void => {
          this.goForm('pages/BrewFormPage');
        }
      },
      {
        icon: '🔗',
        label: '从剪贴板导入',
        action: (): void => {
          this.runClipboardImport(true);
        }
      }
    ];
  }

  onPageShow(): void {
    if (SettingsStore.getInstance().isAutoClipboard()) {
      this.runClipboardImport(false);
    }
  }

  private runClipboardImport(manual: boolean): void {
    ClipboardImport.check().then((r: ClipboardCheckResult) => {
      if (r.found) {
        this.importDraft = r.draft;
        this.importCategory = r.parse.category;
        this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
          this.showImportSheet = true;
        });
      } else if (manual) {
        this.getUIContext().getPromptAction().showToast({ message: '剪贴板中未发现商品链接' });
      }
    });
  }

  private closeImportSheet(): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showImportSheet = false;
    });
  }

  private pickImport(target: string): void {
    const d: ImportDraft = this.importDraft;
    d.target = target;
    AppStorage.setOrCreate(AppKeys.IMPORT_DRAFT, d);
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showImportSheet = false;
    });
    this.goForm(target === 'bean' ? 'pages/BeanFormPage' : 'pages/EquipmentFormPage');
  }

  private goForm(url: string): void {
    const p: FormParams = { id: -1 };
    this.getUIContext().getRouter().pushUrl({ url: url, params: p });
  }

  private openAddSheet(): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showAddSheet = true;
    });
  }

  private closeAddSheet(): void {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showAddSheet = false;
    });
  }

  @Builder
  tabItem(index: number, icon: string, label: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(20)
      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? this.themeColor : $r('app.color.text_tertiary'))
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .borderRadius(16)
    .onClick(() => {
      this.tabController.changeIndex(index);
    })
  }

  @Builder
  dockBar() {
    Row() {
      this.tabItem(0, '📖', '库藏')
      this.tabItem(1, '⏱', '冲煮')
      this.tabItem(2, '👤', '我的')
      Divider()
        .vertical(true)
        .height(26)
        .color($r('app.color.dock_divider_color'))
        .margin({ left: 10, right: 14 })
      Text('+')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(46)
        .height(46)
        .backgroundColor(this.themeColor)
        .borderRadius(23)
        .shadow({ radius: 8, color: ThemePalette.alpha(this.themeColor, 0.4), offsetY: 3 })
        .onClick(() => {
          this.openAddSheet();
        })
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding({ left: 14, right: 14 })
    .margin({ left: 16, right: 16, bottom: 14 })
    .height(64)
    .backgroundBlurStyle(BlurStyle.Thick)
    .borderRadius(32)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.10)', offsetY: 4 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
        TabContent() {
          LibraryView()
        }.tabBar('库藏')

        TabContent() {
          BrewLogView()
        }.tabBar('冲煮')

        TabContent() {
          MineView()
        }.tabBar('我的')
      }
      .barHeight(0)
      .onChange((index: number) => {
        this.currentTab = index;
      })
      .width('100%')
      .height('100%')

      this.dockBar()

      if (this.showAddSheet) {
        OptionSheet({
          title: '快速记录',
          options: this.addOptions,
          onClose: (): void => {
            this.closeAddSheet();
          }
        })
      }

      if (this.showImportSheet) {
        ImportPreviewSheet({
          draft: this.importDraft,
          category: this.importCategory,
          onPick: (target: string): void => {
            this.pickImport(target);
          },
          onClose: (): void => {
            this.closeImportSheet();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemePalette.page(this.themeColor, this.isDarkMode))
  }
}
