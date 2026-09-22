import { BusinessError } from '@kit.BasicServicesKit';
import { BrewRecord, BrewMethod } from '../model/Models';
import { FormParams } from '../model/RouteParams';
import { CoffeeDb } from '../data/CoffeeDb';
import { BrewCard } from '../components/BrewCard';

@Component
export struct BrewLogView {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  @StorageLink('dataVersion') @Watch('onDataChanged') dataVersion: number = 0;
  @State brews: BrewRecord[] = [];
  @State filterMethod: string = '';

  aboutToAppear(): void {
    this.load();
  }

  onDataChanged(): void {
    this.load();
  }

  private load(): void {
    CoffeeDb.getInstance().queryBrews().then((list: BrewRecord[]) => {
      this.brews = list;
    }).catch((e: BusinessError) => {
      console.error(`load brews failed: ${e.code}`);
    });
  }

  private filtered(): BrewRecord[] {
    if (this.filterMethod.length === 0) {
      return this.brews;
    }
    return this.brews.filter((r: BrewRecord): boolean => r.method === this.filterMethod);
  }

  private bumpVersion(): void {
    AppStorage.setOrCreate('dataVersion', (AppStorage.get<number>('dataVersion') ?? 0) + 1);
  }

  private goEdit(id: number): void {
    const p: FormParams = { id: id };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/BrewFormPage', params: p });
  }

  private confirmDelete(r: BrewRecord): void {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: `确定删除这条「${r.method}」冲煮记录吗？`,
      primaryButton: {
        value: '删除',
        action: (): void => {
          CoffeeDb.getInstance().deleteBrew(r.id).then(() => {
            this.bumpVersion();
            this.getUIContext().getPromptAction().showToast({ message: '已删除' });
          }).catch((e: BusinessError) => {
            console.error(`delete brew failed: ${e.code}`);
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
  methodChip(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(this.filterMethod === label ? '#FFFFFF' : $r('app.color.text_secondary'))
      .padding({ left: 12, right: 12, top: 5, bottom: 5 })
      .backgroundColor(this.filterMethod === label ? this.themeColor : $r('app.color.chip_background'))
      .borderRadius(14)
      .margin({ right: 8, bottom: 6 })
      .onClick(() => {
        this.filterMethod = label;
      })
  }

  build() {
    Column() {
      Text('冲煮')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      Scroll() {
        Flex({ wrap: FlexWrap.Wrap }) {
          Text('全部')
            .fontSize(12)
            .fontColor(this.filterMethod.length === 0 ? '#FFFFFF' : $r('app.color.text_secondary'))
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
            .backgroundColor(this.filterMethod.length === 0 ? this.themeColor : $r('app.color.chip_background'))
            .borderRadius(14)
            .margin({ right: 8, bottom: 6 })
            .onClick(() => {
              this.filterMethod = '';
            })
          ForEach(BrewMethod.ALL, (m: string) => {
            this.methodChip(m)
          }, (m: string): string => `chip_${m}`)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      if (this.filtered().length === 0) {
        Column({ space: 10 }) {
          Text('☕')
            .fontSize(48)
          Text(this.filterMethod.length === 0 ? '还没有冲煮记录\n点右下角 + 添加' : `暂无「${this.filterMethod}」记录`)
            .fontSize(13)
            .fontColor($r('app.color.text_hint'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.filtered(), (item: BrewRecord) => {
            ListItem() {
              BrewCard({
                record: item,
                onTap: (r: BrewRecord): void => {
                  this.goEdit(r.id);
                },
                onDelete: (r: BrewRecord): void => {
                  this.confirmDelete(r);
                }
              })
            }
          }, (item: BrewRecord): string => `brew_${item.id}_v${this.dataVersion}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 4, bottom: 104 })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
  }
}
