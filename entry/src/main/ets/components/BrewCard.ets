import { BrewRecord, BrewFieldConfig } from '../model/Models';
import { DateUtil } from '../common/DateUtil';

@Component
export struct BrewCard {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  record: BrewRecord = new BrewRecord();
  onTap: (r: BrewRecord) => void = (r: BrewRecord) => {};
  onDelete: (r: BrewRecord) => void = (r: BrewRecord) => {};

  private summaryParts(r: BrewRecord): string[] {
    const cfg: BrewFieldConfig = BrewFieldConfig.of(r.method);
    const parts: string[] = [];
    if (r.dose > 0) {
      parts.push(`粉 ${r.dose}g`);
    }
    if (cfg.showWater && r.waterAmount > 0) {
      parts.push(`水 ${r.waterAmount}g`);
    }
    if (cfg.showTemp && r.waterTemp > 0) {
      parts.push(`${r.waterTemp}℃`);
    }
    if (r.grindSize.length > 0) {
      parts.push(r.grindSize);
    }
    if (r.brewDuration > 0) {
      parts.push(DateUtil.formatDuration(r.brewDuration));
    }
    return parts;
  }

  private stars(rating: number): string {
    let s: string = '';
    for (let i = 0; i < 5; i++) {
      s += i < rating ? '★' : '☆';
    }
    return s;
  }

  build() {
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(this.record.method)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor(this.themeColor)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .borderRadius(10)
          Text(this.record.beanName.length > 0 ? this.record.beanName : '未关联咖啡豆')
            .fontSize(13)
            .fontColor('#555555')
            .maxLines(1)
            .layoutWeight(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(DateUtil.formatDateTime(this.record.brewDate))
            .fontSize(11)
            .fontColor('#AAAAAA')
        }
        .width('100%')

        if (this.summaryParts(this.record).length > 0) {
          Text(this.summaryParts(this.record).join(' · '))
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        if (this.record.rating > 0) {
          Text(this.stars(this.record.rating))
            .fontSize(14)
            .fontColor(this.themeColor)
        }

        if (this.record.notes.length > 0) {
          Text(this.record.notes)
            .fontSize(12)
            .fontColor('#888888')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        this.onTap(this.record);
      })

      Text('✕')
        .fontSize(15)
        .fontColor('#CCCCCC')
        .padding(6)
        .onClick(() => {
          this.onDelete(this.record);
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(VerticalAlign.Top)
  }
}
