import { BusinessError } from '@kit.BasicServicesKit';
import { CoffeeBean, Equipment } from '../model/Models';
import { FormParams } from '../model/RouteParams';
import { CoffeeDb } from '../data/CoffeeDb';
import { BeanCard } from '../components/BeanCard';
import { EquipmentCard } from '../components/EquipmentCard';
import { ThemePalette } from '../common/Theme';

@Component
export struct LibraryView {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('dataVersion') @Watch('onDataChanged') dataVersion: number = 0;
  @State beanMode: boolean = true;
  @State beans: CoffeeBean[] = [];
  @State equipments: Equipment[] = [];

  aboutToAppear(): void {
    this.load();
  }

  onDataChanged(): void {
    this.load();
  }

  private load(): void {
    CoffeeDb.getInstance().queryBeans().then((list: CoffeeBean[]) => {
      this.beans = list;
    }).catch((e: BusinessError) => {
      console.error(`load beans failed: ${e.code}`);
    });
    CoffeeDb.getInstance().queryEquipments().then((list: Equipment[]) => {
      this.equipments = list;
    }).catch((e: BusinessError) => {
      console.error(`load equipments failed: ${e.code}`);
    });
  }

  private bumpVersion(): void {
    AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
  }

  private goEdit(url: string, id: number): void {
    const p: FormParams = { id: id };
    this.getUIContext().getRouter().pushUrl({ url: url, params: p });
  }

  private confirmDeleteBean(b: CoffeeBean): void {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: `确定删除咖啡豆「${b.variety}」吗？`,
      primaryButton: {
        value: '删除',
        action: (): void => {
          CoffeeDb.getInstance().deleteBean(b.id).then(() => {
            this.bumpVersion();
            this.getUIContext().getPromptAction().showToast({ message: '已删除' });
          }).catch((e: BusinessError) => {
            console.error(`delete bean failed: ${e.code}`);
          });
        }
      },
      secondaryButton: {
        value: '取消',
        action: (): void => {}
      }
    });
  }

  private confirmDeleteEquipment(e: Equipment): void {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: `确定删除器具「${e.type}」吗？`,
      primaryButton: {
        value: '删除',
        action: (): void => {
          CoffeeDb.getInstance().deleteEquipment(e.id).then(() => {
            this.bumpVersion();
            this.getUIContext().getPromptAction().showToast({ message: '已删除' });
          }).catch((err: BusinessError) => {
            console.error(`delete equipment failed: ${err.code}`);
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
  emptyState(icon: string, text: string) {
    Column({ space: 10 }) {
      Text(icon)
        .fontSize(48)
      Text(text)
        .fontSize(13)
        .fontColor($r('app.color.text_hint'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('库藏')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Row() {
          Text('咖啡豆')
            .fontSize(13)
            .fontColor(this.beanMode ? '#FFFFFF' : $r('app.color.text_secondary'))
            .padding({ left: 16, right: 16, top: 7, bottom: 7 })
            .backgroundColor(this.beanMode ? this.themeColor : Color.Transparent)
            .borderRadius(16)
            .onClick(() => {
              this.beanMode = true;
            })
          Text('器具')
            .fontSize(13)
            .fontColor(!this.beanMode ? '#FFFFFF' : $r('app.color.text_secondary'))
            .padding({ left: 16, right: 16, top: 7, bottom: 7 })
            .backgroundColor(!this.beanMode ? this.themeColor : Color.Transparent)
            .borderRadius(16)
            .onClick(() => {
              this.beanMode = false;
            })
        }
        .backgroundColor(ThemePalette.tint(this.themeColor, this.isDarkMode, 0.14))
        .borderRadius(18)
        .padding(3)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.beanMode) {
        if (this.beans.length === 0) {
          this.emptyState('🫘', '还没有咖啡豆记录\n点右下角 + 添加')
        } else {
          List({ space: 10 }) {
            ForEach(this.beans, (item: CoffeeBean) => {
              ListItem() {
                BeanCard({
                  bean: item,
                  onTap: (b: CoffeeBean): void => {
                    this.goEdit('pages/BeanFormPage', b.id);
                  },
                  onDelete: (b: CoffeeBean): void => {
                    this.confirmDeleteBean(b);
                  }
                })
              }
            }, (item: CoffeeBean): string => `bean_${item.id}_v${this.dataVersion}`)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 4, bottom: 104 })
          .edgeEffect(EdgeEffect.Spring)
        }
      } else {
        if (this.equipments.length === 0) {
          this.emptyState('⚗️', '还没有器具记录\n点右下角 + 添加')
        } else {
          List({ space: 10 }) {
            ForEach(this.equipments, (item: Equipment) => {
              ListItem() {
                EquipmentCard({
                  equipment: item,
                  onTap: (e: Equipment): void => {
                    this.goEdit('pages/EquipmentFormPage', e.id);
                  },
                  onDelete: (e: Equipment): void => {
                    this.confirmDeleteEquipment(e);
                  }
                })
              }
            }, (item: Equipment): string => `eq_${item.id}_v${this.dataVersion}`)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 4, bottom: 104 })
          .edgeEffect(EdgeEffect.Spring)
        }
      }
    }
    .width('100%')
    .height('100%')
  }
}
