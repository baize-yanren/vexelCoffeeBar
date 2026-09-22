export class OptionItem {
  icon: string = '';
  label: string = '';
  action: () => void = () => {};
}

@Component
export struct OptionSheet {
  title: string = '';
  options: OptionItem[] = [];
  onClose: () => void = () => {};

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

      Column() {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 18, bottom: 4 })

        ForEach(this.options, (opt: OptionItem) => {
          Row({ space: 12 }) {
            Text(opt.icon)
              .fontSize(22)
              .width(26)
              .textAlign(TextAlign.Center)
            Text(opt.label)
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor($r('app.color.text_disabled'))
          }
          .width('100%')
          .height(52)
          .padding({ left: 24, right: 24 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.onClose();
            opt.action();
          })
        }, (opt: OptionItem, index: number): string => `opt_${index}_${opt.label}`)
      }
      .width('100%')
      .padding({ bottom: 34 })
      .backgroundColor($r('app.color.sheet_background'))
      .backgroundBlurStyle(BlurStyle.Thick)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .transition(TransitionEffect.translate({ y: 420 }).animation({ duration: 250, curve: Curve.EaseOut }))
    }
    .width('100%')
    .height('100%')
  }
}
