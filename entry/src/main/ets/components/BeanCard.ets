import { CoffeeBean } from '../model/Models';
import { DateUtil } from '../common/DateUtil';

@Component
export struct BeanCard {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  bean: CoffeeBean = new CoffeeBean();
  onTap: (b: CoffeeBean) => void = (b: CoffeeBean) => {};
  onDelete: (b: CoffeeBean) => void = (b: CoffeeBean) => {};

  build() {
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(this.bean.variety)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(DateUtil.formatPrice(this.bean.price))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColor)
        }
        .width('100%')

        if (this.bean.name.length > 0) {
          Text(this.bean.name)
            .fontSize(13)
            .fontColor('#888888')
            .maxLines(1)
        }

        Row({ space: 14 }) {
          if (this.bean.vendor.length > 0) {
            Text(this.bean.vendor)
              .fontSize(12)
              .fontColor('#999999')
              .maxLines(1)
          }
          Text(DateUtil.formatDate(this.bean.purchaseDate))
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')

        if (this.bean.flavorTagList().length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.bean.flavorTagList(), (tag: string) => {
              Text(tag)
                .fontSize(11)
                .fontColor(this.themeColor)
                .backgroundColor('#F5EDE4')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .borderRadius(10)
                .margin({ right: 6, bottom: 4 })
            }, (tag: string, index: number): string => `tag_${index}_${tag}`)
          }
          .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        this.onTap(this.bean);
      })

      Text('✕')
        .fontSize(15)
        .fontColor('#CCCCCC')
        .padding(6)
        .onClick(() => {
          this.onDelete(this.bean);
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(VerticalAlign.Top)
  }
}
