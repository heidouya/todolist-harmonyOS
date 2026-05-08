import { FilterType } from '../model/TodoItem';

/**
 * 筛选 Tab 栏组件
 * @Link 建立与父组件的双向引用绑定，确保计数值实时同步
 */
@Component
export struct FilterTabBar {
  @Prop currentFilter: FilterType = 'all';
  @Link allCount: number;
  @Link activeCount: number;
  @Link completedCount: number;
  onChange: (filter: FilterType) => void = () => {};

  build() {
    Row() {
      // 全部 Tab
      Column() {
        Row() {
          Text('全部')
            .fontSize(15)
            .fontWeight(this.currentFilter === 'all' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentFilter === 'all' ? '#007DFF' : '#666666')
          Text(`(${this.allCount})`)
            .fontSize(12)
            .fontColor(this.currentFilter === 'all' ? '#007DFF' : '#999999')
            .margin({ left: 4 })
        }
        if (this.currentFilter === 'all') {
          Divider()
            .width(32)
            .height(2)
            .color('#007DFF')
            .margin({ top: 6 })
        } else {
          Divider()
            .width(32)
            .height(2)
            .color(Color.Transparent)
            .margin({ top: 6 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.onChange('all'))

      // 未完成 Tab
      Column() {
        Row() {
          Text('未完成')
            .fontSize(15)
            .fontWeight(this.currentFilter === 'active' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentFilter === 'active' ? '#007DFF' : '#666666')
          Text(`(${this.activeCount})`)
            .fontSize(12)
            .fontColor(this.currentFilter === 'active' ? '#007DFF' : '#999999')
            .margin({ left: 4 })
        }
        if (this.currentFilter === 'active') {
          Divider()
            .width(32)
            .height(2)
            .color('#007DFF')
            .margin({ top: 6 })
        } else {
          Divider()
            .width(32)
            .height(2)
            .color(Color.Transparent)
            .margin({ top: 6 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.onChange('active'))

      // 已完成 Tab
      Column() {
        Row() {
          Text('已完成')
            .fontSize(15)
            .fontWeight(this.currentFilter === 'completed' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentFilter === 'completed' ? '#007DFF' : '#666666')
          Text(`(${this.completedCount})`)
            .fontSize(12)
            .fontColor(this.currentFilter === 'completed' ? '#007DFF' : '#999999')
            .margin({ left: 4 })
        }
        if (this.currentFilter === 'completed') {
          Divider()
            .width(32)
            .height(2)
            .color('#007DFF')
            .margin({ top: 6 })
        } else {
          Divider()
            .width(32)
            .height(2)
            .color(Color.Transparent)
            .margin({ top: 6 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.onChange('completed'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }
}
