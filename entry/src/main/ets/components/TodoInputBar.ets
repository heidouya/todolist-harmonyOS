/**
 * 底部输入组件
 * 输入框 + 添加按钮 + 优先级选择
 */
@Component
export struct TodoInputBar {
  @State inputText: string = '';
  @State selectedPriority: number = 2; // 默认中优先级
  onAdd: (title: string, priority: number) => void = () => {};

  build() {
    Column() {
      Divider().height(0.5).color('#E5E5E5')
      Row() {
        // 优先级选择器
        Row() {
          Text(this.getPriorityLabel())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .backgroundColor(this.getPriorityColor())
        }
        .onClick(() => {
          // 循环切换优先级
          this.selectedPriority = this.selectedPriority >= 3 ? 1 : this.selectedPriority + 1;
        })
        .margin({ right: 8 })

        // 输入框
        TextInput({ placeholder: '添加新的待办事项...', text: this.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.handleAdd();
          })

        // 添加按钮
        Button('添加')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(20)
          .height(40)
          .padding({ left: 16, right: 16 })
          .margin({ left: 8 })
          .onClick(() => {
            this.handleAdd();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
  }

  /**
   * 获取优先级标签文字
   */
  private getPriorityLabel(): string {
    if (this.selectedPriority === 1) {
      return '高';
    } else if (this.selectedPriority === 2) {
      return '中';
    } else {
      return '低';
    }
  }

  /**
   * 获取优先级颜色
   */
  private getPriorityColor(): string {
    if (this.selectedPriority === 1) {
      return '#FF3B30';
    } else if (this.selectedPriority === 2) {
      return '#FF9500';
    } else {
      return '#34C759';
    }
  }

  /**
   * 处理添加逻辑
   */
  private handleAdd(): void {
    const title = this.inputText.trim();
    if (title.length === 0) {
      return;
    }
    this.onAdd(title, this.selectedPriority);
    this.inputText = '';
    this.selectedPriority = 2; // 重置为默认优先级
  }
}
