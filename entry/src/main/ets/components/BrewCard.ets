import { BrewRecord, BrewFieldConfig, PourPlan } from '../model/Models';
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
    if (cfg.showPourPlan) {
      if (r.pourCount > 0) {
        parts.push(`注水${r.pourCount}次`);
      }
      const limit: number = r.pourCount > 0 ? r.pourCount : PourPlan.MAX;
      for (let i: number = 1; i <= limit; i++) {
        const w: number = r.pourWaterAt(i);
        const t: number = r.pourTimeAt(i);
        if (w > 0) {
          parts.push(`${PourPlan.CN[i - 1]}注 ${w}g${t > 0 ? `/${t}s` : ''}`);
        }
      }
    }
    if (cfg.showBloom && (r.bloomWater > 0 || r.bloomTime > 0)) {
      const water: string = r.bloomWater > 0 ? `${r.bloomWater}g` : '';
      const time: string = r.bloomTime > 0 ? `${r.bloomTime}s` : '';
      parts.push(`闷蒸 ${water}${r.bloomWater > 0 && r.bloomTime > 0 ? '/' : ''}${time}`);
    }
    if (cfg.showWater && r.waterAmount > 0) {
      parts.push(`水 ${r.waterAmount}g`);
    }
    if (cfg.showTemp && r.waterTemp > 0) {
      parts.push(`${r.waterTemp}℃`);
    }
    if (cfg.showSteep) {
      if (r.steepHours > 0) {
        parts.push(`冷藏 ${r.steepHours}小时`);
      } else if (r.steepMinutes > 0) {
        parts.push(`浸泡 ${r.steepMinutes}分钟`);
      }
    }
    if (cfg.showPressTime && r.pressSeconds > 0) {
      parts.push(`压下 ${r.pressSeconds}秒`);
    }
    if (cfg.showPressure && r.pressure > 0) {
      parts.push(`${r.pressure}bar`);
    }
    if (r.grindSize.length > 0) {
      parts.push(r.grindSize);
    }
    if (cfg.showDuration && r.brewDuration > 0) {
      parts.push(DateUtil.formatDuration(r.brewDuration));
    }
    if (cfg.showYield && r.yieldAmount > 0) {
      parts.push(r.method === '意式' ? `浓缩 ${r.yieldAmount}g` : `出品 ${r.yieldAmount}g`);
    }
    if (cfg.showHeat && r.heatLevel.length > 0) {
      parts.push(`火候 ${r.heatLevel}`);
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
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .layoutWeight(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(DateUtil.formatDateTime(this.record.brewDate))
            .fontSize(11)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')

        if (this.summaryParts(this.record).length > 0) {
          Text(this.summaryParts(this.record).join(' · '))
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
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
            .fontColor($r('app.color.text_tertiary'))
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
        .fontColor($r('app.color.text_disabled'))
        .padding(6)
        .onClick(() => {
          this.onDelete(this.record);
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Top)
  }
}
