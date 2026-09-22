import { ImportDraft } from '../model/ImportDraft';
import { ThemePalette } from '../common/Theme';

@Component
export struct ImportPreviewSheet {
  @StorageProp('themeColor') themeColor: string = '#6F4E37';
  draft: ImportDraft = new ImportDraft();
  category: string = 'unknown';
  onPick: (target: string) => void = (target: string) => {};
  onClose: () => void = () => {};

  private isBeanRecommended(): boolean {
    return this.category === 'bean';
  }

  private isEquipRecommended(): boolean {
    return this.category === 'equipment';
  }

  @Builder
  fieldRow(label: string, value: string) {
    Row({ space: 10 }) {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.text_tertiary'))
        .width(60)
      Text(value)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  pickButton(label: string, recommended: boolean, target: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(recommended ? '#FFFFFF' : this.themeColor)
      if (recommended) {
        Text('按商品类型推荐')
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.8)')
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .borderRadius(16)
    .backgroundColor(recommended ? this.themeColor : $r('app.color.card_background'))
    .border({ width: 1, color: recommended ? this.themeColor : ThemePalette.alpha(this.themeColor, 0.35) })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onPick(target);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.mask_color'))
        .onClick(() => {
          this.onClose();
        })
        .transition(TransitionEffect.OPACITY.animation({ duration: 250, curve: Curve.EaseOut }))

      Column({ space: 14 }) {
        Text('🔗 识别到商品链接')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: 22 })

        Column({ space: 10 }) {
          this.fieldRow('商品', this.draft.title)
          this.fieldRow('价格', this.draft.price > 0 ? `¥${this.draft.price}` : '未识别')
          this.fieldRow('来源', this.draft.vendor.length > 0 ? this.draft.vendor : '未知平台')
        }
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor(ThemePalette.alpha(this.themeColor, 0.10))

        if (this.draft.sourceUrl.length > 0) {
          Text(this.draft.sourceUrl)
            .fontSize(10)
            .fontColor($r('app.color.text_hint'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Row({ space: 12 }) {
          Column() {
            this.pickButton('填入咖啡豆表单', this.isBeanRecommended(), 'bean')
          }.layoutWeight(1)

          Column() {
            this.pickButton('填入器具表单', this.isEquipRecommended(), 'equipment')
          }.layoutWeight(1)
        }
        .width('100%')

        Text('取消')
          .fontSize(14)
          .fontColor($r('app.color.text_tertiary'))
          .padding({ top: 4, bottom: 8 })
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
      .backgroundColor($r('app.color.sheet_background'))
      .backgroundBlurStyle(BlurStyle.Thick)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .transition(TransitionEffect.translate({ y: 420 }).animation({ duration: 250, curve: Curve.EaseOut }))
    }
    .width('100%')
    .height('100%')
  }
}
