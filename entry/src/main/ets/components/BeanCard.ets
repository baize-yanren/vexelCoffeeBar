import { CoffeeBean } from '../model/Models';
import { DateUtil } from '../common/DateUtil';
import { ThemePalette } from '../common/Theme';

@Component
export struct BeanCard {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  bean: CoffeeBean = new CoffeeBean();
  onTap: (b: CoffeeBean) => void = (b: CoffeeBean) => {};
  onDelete: (b: CoffeeBean) => void = (b: CoffeeBean) => {};

  private metaParts(): string[] {
    const parts: string[] = [];
    if (this.bean.vendor.length > 0) {
      parts.push(this.bean.vendor);
    }
    if (this.bean.origin.length > 0) {
      parts.push(this.bean.origin);
    }
    if (this.bean.weight > 0) {
      parts.push(`${this.bean.weight}g`);
    }
    const date: string = DateUtil.formatDate(this.bean.purchaseDate);
    if (date.length > 0) {
      parts.push(date);
    }
    return parts;
  }

  private tagList(): string[] {
    const tags: string[] = [];
    if (this.bean.processMethod.length > 0) {
      tags.push(this.bean.processMethod);
    }
    if (this.bean.roastLevel.length > 0) {
      tags.push(this.bean.roastLevel);
    }
    return tags.concat(this.bean.flavorTagList());
  }

  build() {
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(this.bean.variety)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
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
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
        }

        if (this.metaParts().length > 0) {
          Text(this.metaParts().join(' · '))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        if (this.tagList().length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.tagList(), (tag: string) => {
              Text(tag)
                .fontSize(11)
                .fontColor(this.themeColor)
                .backgroundColor(ThemePalette.alpha(this.themeColor, 0.12))
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
        .fontColor($r('app.color.text_disabled'))
        .padding(6)
        .onClick(() => {
          this.onDelete(this.bean);
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Top)
  }
}
