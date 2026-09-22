import { Equipment } from '../model/Models';
import { DateUtil } from '../common/DateUtil';

@Component
export struct EquipmentCard {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  equipment: Equipment = new Equipment();
  onTap: (e: Equipment) => void = (e: Equipment) => {};
  onDelete: (e: Equipment) => void = (e: Equipment) => {};

  build() {
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(this.equipment.type)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
          Text(DateUtil.formatPrice(this.equipment.price))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColor)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        if (this.equipment.brand.length > 0 || this.equipment.model.length > 0) {
          Text(this.equipment.brand.length > 0 && this.equipment.model.length > 0 ?
            `${this.equipment.brand} · ${this.equipment.model}` :
            (this.equipment.brand.length > 0 ? this.equipment.brand : this.equipment.model))
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }

        Row({ space: 14 }) {
          Text(DateUtil.formatDate(this.equipment.purchaseDate))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          if (this.equipment.notes.length > 0) {
            Text(this.equipment.notes)
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        this.onTap(this.equipment);
      })

      Text('✕')
        .fontSize(15)
        .fontColor($r('app.color.text_disabled'))
        .padding(6)
        .onClick(() => {
          this.onDelete(this.equipment);
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Top)
  }
}
