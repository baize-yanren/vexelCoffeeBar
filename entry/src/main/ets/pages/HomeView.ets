import { BusinessError } from '@kit.BasicServicesKit';
import { CoffeeBean, Equipment, BrewRecord } from '../model/Models';
import { FormParams } from '../model/RouteParams';
import { CoffeeDb } from '../data/CoffeeDb';
import { EquipmentCard } from '../components/EquipmentCard';
import { ThemePalette } from '../common/Theme';

interface CardHeaderOptions {
  icon: string;
  title: string;
}

@Component
export struct HomeView {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('dataVersion') @Watch('onDataChanged') dataVersion: number = 0;
  @State beans: CoffeeBean[] = [];
  @State brews: BrewRecord[] = [];
  @State equipments: Equipment[] = [];
  @State beanSpend: number = 0;
  @State beanGramPrice: number = 0;
  @State beanHasWeight: boolean = false;
  @State brewCount: number = 0;
  @State avgBeanCost: number = 0;
  @State equipSpend: number = 0;
  @State avgEquipCost: number = 0;
  @State avgTotalCost: number = 0;

  aboutToAppear(): void {
    this.load();
  }

  onDataChanged(): void {
    this.load();
  }

  private load(): void {
    CoffeeDb.getInstance().queryBeans().then((list: CoffeeBean[]) => {
      this.beans = list;
      this.recalc();
    }).catch((e: BusinessError) => {
      console.error(`load beans failed: ${e.code}`);
    });
    CoffeeDb.getInstance().queryBrews().then((list: BrewRecord[]) => {
      this.brews = list;
      this.recalc();
    }).catch((e: BusinessError) => {
      console.error(`load brews failed: ${e.code}`);
    });
    CoffeeDb.getInstance().queryEquipments().then((list: Equipment[]) => {
      this.equipments = list;
      this.recalc();
    }).catch((e: BusinessError) => {
      console.error(`load equipments failed: ${e.code}`);
    });
  }

  private brewBeanCost(r: BrewRecord): number {
    if (r.beanCost > 0) {
      return r.beanCost;
    }
    if (r.beanId <= 0 || r.dose <= 0) {
      return 0;
    }
    const bean: CoffeeBean | undefined =
      this.beans.find((b: CoffeeBean): boolean => b.id === r.beanId);
    if (bean === undefined || bean.weight <= 0) {
      return 0;
    }
    return bean.price / bean.weight * r.dose;
  }

  private recalc(): void {
    let spend: number = 0;
    let weight: number = 0;
    for (let i = 0; i < this.beans.length; i++) {
      spend += this.beans[i].price;
      weight += this.beans[i].weight;
    }
    this.beanSpend = spend;
    this.beanHasWeight = weight > 0;
    this.beanGramPrice = weight > 0 ? spend / weight : 0;

    const n: number = this.brews.length;
    let beanCostSum: number = 0;
    for (let i = 0; i < n; i++) {
      beanCostSum += this.brewBeanCost(this.brews[i]);
    }
    this.brewCount = n;
    this.avgBeanCost = n > 0 ? beanCostSum / n : 0;

    let equipTotal: number = 0;
    for (let i = 0; i < this.equipments.length; i++) {
      equipTotal += this.equipments[i].price;
    }
    this.equipSpend = equipTotal;
    this.avgEquipCost = n > 0 ? equipTotal / n : 0;
    this.avgTotalCost = this.avgBeanCost + this.avgEquipCost;
  }

  private goEdit(url: string, id: number): void {
    const p: FormParams = { id: id };
    this.getUIContext().getRouter().pushUrl({ url: url, params: p });
  }

  private confirmDeleteEquipment(e: Equipment): void {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: `确定删除器具「${e.type}」吗？`,
      primaryButton: {
        value: '删除',
        action: (): void => {
          CoffeeDb.getInstance().deleteEquipment(e.id).then(() => {
            AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
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
  cardHeader($$: CardHeaderOptions) {
    Row({ space: 8 }) {
      Text($$.icon)
        .fontSize(18)
      Text($$.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
  }

  build() {
    Column() {
      Text('首页')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 14 }) {
            this.cardHeader({ icon: '🫘', title: '咖啡豆分析' })
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text('共花费')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                Text(`¥${this.beanSpend.toFixed(2)}`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColor)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('克均价')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                Text(this.beanHasWeight ? `¥${this.beanGramPrice.toFixed(2)}/g` : '—')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColor)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 14 }) {
            this.cardHeader({ icon: '☕', title: '冲煮统计' })
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text('共冲煮次数')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                Text(`${this.brewCount} 次`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColor)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('平均每次冲煮花销')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                Text(`¥${this.avgTotalCost.toFixed(2)}`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.themeColor)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            Text(`总均价 = 总豆均价 ¥${this.avgBeanCost.toFixed(2)} + 器具均价 ¥${this.avgEquipCost.toFixed(2)}`)
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(ThemePalette.tint(this.themeColor, this.isDarkMode, 0.10))
              .borderRadius(12)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 12 }) {
            this.cardHeader({ icon: '⚗️', title: `器具统计 · 共 ${this.equipments.length} 件` })
            if (this.equipments.length === 0) {
              Text('还没有器具记录\n点右下角 + 添加')
                .fontSize(13)
                .fontColor($r('app.color.text_hint'))
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: 16, bottom: 16 })
            } else {
              ForEach(this.equipments, (item: Equipment) => {
                EquipmentCard({
                  equipment: item,
                  onTap: (e: Equipment): void => {
                    this.goEdit('pages/EquipmentFormPage', e.id);
                  },
                  onDelete: (e: Equipment): void => {
                    this.confirmDeleteEquipment(e);
                  }
                })
              }, (item: Equipment): string => `eq_${item.id}_v${this.dataVersion}`)
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 110 })
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }
}
