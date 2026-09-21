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
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => {
          this.onClose();
        })
        .transition(TransitionEffect.OPACITY.animation({ duration: 250, curve: Curve.EaseOut }))

      Column() {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#8C8C8C')
          .margin({ top: 18, bottom: 4 })

        ForEach(this.options, (opt: OptionItem) => {
          Row({ space: 12 }) {
            Text(opt.icon)
              .fontSize(22)
              .width(26)
              .textAlign(TextAlign.Center)
            Text(opt.label)
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor('#BBBBBB')
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
      .backgroundColor('rgba(255,255,255,0.86)')
      .backgroundBlurStyle(BlurStyle.Thick)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .transition(TransitionEffect.translate({ y: 420 }).animation({ duration: 250, curve: Curve.EaseOut }))
    }
    .width('100%')
    .height('100%')
  }
}
