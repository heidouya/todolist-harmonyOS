import { TodoItem, FilterType } from '../model/TodoItem';
import { TodoDatabase } from '../model/TodoDatabase';
import { FilterTabBar } from '../components/FilterTabBar';
import { TodoInputBar } from '../components/TodoInputBar';
import { Logger } from '../utils/Logger';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct TodoPage {
  // 当前筛选条件
  @State currentFilter: FilterType = 'all';
  // 搜索关键词
  @State searchKeyword: string = '';
  // 多选模式 — 通过 @Provide 共享给子组件
  @Provide isSelectionMode: boolean = false;
  // 已选中的待办 id 集合 — 通过 @Provide 共享给子组件
  @Provide selectedIds: Set<number> = new Set();
  // 待办列表（直接用 @State 数组驱动 ForEach）
  @State todoList: TodoItem[] = [];
  // 各状态数量（用三个独立 @State 原始值，确保 @Prop 可靠同步）
  @State allCount: number = 0;
  @State activeCount: number = 0;
  @State completedCount: number = 0;
  // 编辑对话框控制
  @State editingItem: TodoItem = {
    id: 0, title: '', description: '', completed: false, priority: 2, createdAt: 0, updatedAt: 0
  };
  @State editTitle: string = '';
  @State editDescription: string = '';
  @State editPriority: number = 2;

  // 编辑对话框控制器
  editDialogController: CustomDialogController = new CustomDialogController({
    builder: TodoEditDialog({
      title: $editTitle,
      description: $editDescription,
      priority: $editPriority,
      onConfirm: () => { this.handleSaveEdit(); }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  /**
   * 生命周期：页面显示前初始化数据库并加载数据
   */
  async aboutToAppear(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await TodoDatabase.initDatabase(context);
      await this.loadData();
    } catch (err) {
      Logger.error('Failed to initialize: %{public}s', JSON.stringify(err));
      promptAction.showToast({ message: '数据初始化失败' });
    }
  }

  /**
   * 加载待办列表数据和数量统计
   * 统一通过 queryTodos('all') 查全部数据，内存中分拣列表和计数
   * 彻底消除 getCounts 因 RdbPredicates 差异导致的计数为 0 问题
   */
  async loadData(): Promise<void> {
    const allTodos = await TodoDatabase.queryTodos('all', this.searchKeyword);

    // 根据当前筛选条件分拣列表
    if (this.currentFilter === 'active') {
      this.todoList = allTodos.filter((t: TodoItem) => !t.completed);
    } else if (this.currentFilter === 'completed') {
      this.todoList = allTodos.filter((t: TodoItem) => t.completed);
    } else {
      this.todoList = allTodos;
    }

    // 从全量数据计算各状态数量，直接赋给 @State 变量
    let actCount = 0;
    let compCount = 0;
    for (const item of allTodos) {
      if (item.completed) {
        compCount++;
      } else {
        actCount++;
      }
    }
    this.allCount = allTodos.length;
    this.activeCount = actCount;
    this.completedCount = compCount;
  }

  /**
   * 筛选条件变更
   */
  handleFilterChange(filter: FilterType): void {
    this.currentFilter = filter;
    this.exitSelectionMode();
    this.loadData();
  }

  /**
   * 搜索关键词变更
   */
  handleSearchChange(value: string): void {
    this.searchKeyword = value;
    this.loadData();
  }

  /**
   * 清除搜索关键词
   */
  handleClearSearch(): void {
    this.searchKeyword = '';
    this.loadData();
  }

  /**
   * 添加待办
   */
  async handleAdd(title: string, priority: number): Promise<void> {
    const now = Date.now();
    const newItem: TodoItem = {
      id: 0, title: title, description: '', completed: false,
      priority: priority, createdAt: now, updatedAt: now
    };
    const rowId = await TodoDatabase.insertTodo(newItem);
    if (rowId > 0) {
      promptAction.showToast({ message: '添加成功' });
      await this.loadData();
    } else {
      promptAction.showToast({ message: '添加失败' });
    }
  }

  /**
   * 切换完成状态
   */
  async toggleTodo(id: number): Promise<void> {
    await TodoDatabase.toggleTodo(id);
    await this.loadData();
  }

  /**
   * 删除待办（带确认对话框）
   */
  deleteTodo(id: number): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除该待办事项吗？此操作不可撤销。',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF3B30',
        action: async () => {
          await TodoDatabase.deleteTodo(id);
          promptAction.showToast({ message: '已删除' });
          await this.loadData();
        }
      }
    });
  }

  /**
   * 打开编辑对话框
   */
  openEditDialog(item: TodoItem): void {
    this.editingItem = item;
    this.editTitle = item.title;
    this.editDescription = item.description;
    this.editPriority = item.priority;
    this.editDialogController.open();
  }

  /**
   * 保存编辑
   */
  async handleSaveEdit(): Promise<void> {
    const title = this.editTitle.trim();
    if (title.length === 0) {
      promptAction.showToast({ message: '标题不能为空' });
      return;
    }
    const rows = await TodoDatabase.updateTodo(this.editingItem.id, {
      title: title,
      description: this.editDescription.trim(),
      priority: this.editPriority,
      updatedAt: Date.now()
    });
    if (rows > 0) {
      promptAction.showToast({ message: '修改成功' });
      this.editDialogController.close();
      await this.loadData();
    } else {
      promptAction.showToast({ message: '修改失败' });
    }
  }

  /**
   * 进入多选模式
   */
  enterSelectionMode(): void {
    this.isSelectionMode = true;
    this.selectedIds.clear();
  }

  /**
   * 退出多选模式
   */
  exitSelectionMode(): void {
    this.isSelectionMode = false;
    this.selectedIds.clear();
  }

  /**
   * 处理多选中的选择变更
   */
  handleSelectChange(id: number, selected: boolean): void {
    if (selected) {
      this.selectedIds.add(id);
    } else {
      this.selectedIds.delete(id);
    }
    // 触发状态刷新 — 创建新 Set 以触发响应式更新
    const newSet = new Set<number>();
    this.selectedIds.forEach((val: number) => {
      newSet.add(val);
    });
    this.selectedIds = newSet;
  }

  /**
   * 批量删除
   */
  async handleBatchDelete(): Promise<void> {
    if (this.selectedIds.size === 0) {
      promptAction.showToast({ message: '请选择要删除的待办事项' });
      return;
    }
    AlertDialog.show({
      title: '批量删除',
      message: `确定要删除选中的 ${this.selectedIds.size} 个待办事项吗？`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF3B30',
        action: async () => {
          const ids: number[] = [];
          this.selectedIds.forEach((id: number) => {
            ids.push(id);
          });
          await TodoDatabase.deleteBatch(ids);
          promptAction.showToast({ message: `已删除 ${ids.length} 项` });
          this.exitSelectionMode();
          await this.loadData();
        }
      }
    });
  }

  /**
   * 获取空状态提示文字
   */
  getEmptyText(): string {
    if (this.searchKeyword.length > 0) {
      return '没有找到匹配的待办事项';
    }
    if (this.currentFilter === 'active') {
      return '所有任务已完成 🎉';
    } else if (this.currentFilter === 'completed') {
      return '还没有完成任务';
    } else {
      return '暂无待办事项，添加一个吧 ✍️';
    }
  }

  build() {
    Stack() {
      Column() {
        // ===== 顶部标题栏 =====
        Row() {
          Text('待办事项')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Blank()

          // 多选模式下显示取消和批量删除
          if (this.isSelectionMode) {
            Button('取消')
              .fontSize(14)
              .fontColor('#007DFF')
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.exitSelectionMode();
              })
              .margin({ right: 12 })

            Button('删除')
              .fontSize(14)
              .fontColor('#FF3B30')
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.handleBatchDelete();
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')

        // ===== 搜索框 =====
        Row() {
          Row() {
            Text('🔍')
              .fontSize(14)
              .margin({ left: 12, right: 8 })

            TextInput({ placeholder: '搜索待办事项...', text: this.searchKeyword })
              .layoutWeight(1)
              .height(36)
              .backgroundColor(Color.Transparent)
              .fontSize(14)
              .onChange((value: string) => {
                this.handleSearchChange(value);
              })

            if (this.searchKeyword.length > 0) {
              Text('✕')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ right: 12 })
                .onClick(() => {
                  this.handleClearSearch();
                })
            }
          }
          .height(36)
          .backgroundColor('#F0F0F0')
          .borderRadius(18)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        .backgroundColor('#FFFFFF')

        // ===== 筛选 Tab =====
        FilterTabBar({
          currentFilter: this.currentFilter,
          allCount: $allCount,
          activeCount: $activeCount,
          completedCount: $completedCount,
          onChange: (filter: FilterType) => {
            this.handleFilterChange(filter);
          }
        })

        // ===== 列表区域 =====
        if (this.todoList.length === 0) {
          // 空状态
          Column() {
            Column() {
              Text(this.getEmptyText().includes('🎉') || this.getEmptyText().includes('✍️') ? '📋' : '📭')
                .fontSize(60)
                .opacity(0.3)
              Text(this.getEmptyText())
                .fontSize(16)
                .fontColor('#999999')
                .margin({ top: 16 })
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor('#F5F5F5')
        } else {
          // 列表内容
          List() {
            ForEach(this.todoList, (item: TodoItem) => {
              ListItem() {
                Row() {
                  // 完成状态切换图标 / 多选复选框
                  if (this.isSelectionMode) {
                    Checkbox()
                      .selectedColor('#007DFF')
                      .select(this.selectedIds.has(item.id))
                      .onChange((value: boolean) => {
                        this.handleSelectChange(item.id, value);
                      })
                      .margin({ right: 12 })
                  } else {
                    Row() {
                      Text(item.completed ? '●' : '○')
                        .fontSize(22)
                        .fontColor(item.completed ? '#007DFF' : '#CCCCCC')
                    }
                    .width(44)
                    .height(44)
                    .justifyContent(FlexAlign.Center)
                    .onClick(() => {
                      this.toggleTodo(item.id);
                    })
                  }

                  // 内容区域
                  Column() {
                    Text(item.title)
                      .fontSize(16)
                      .fontColor(item.completed ? '#999999' : '#333333')
                      .decoration(item.completed ?
                        { type: TextDecorationType.LineThrough } :
                        { type: TextDecorationType.None })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (item.description.length > 0) {
                      Text(item.description)
                        .fontSize(12)
                        .fontColor(item.completed ? '#BBBBBB' : '#999999')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 4 })
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  // 优先级颜色小圆点
                  Circle()
                    .width(10)
                    .height(10)
                    .fill(this.getPriorityColor(item.priority))
                    .margin({ left: 8, right: 4 })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .onClick(() => {
                  if (this.isSelectionMode) {
                    this.handleSelectChange(item.id, !this.selectedIds.has(item.id));
                  } else {
                    this.openEditDialog(item);
                  }
                })
              }
              .swipeAction({
                end: {
                  builder: () => {
                    this.DeleteSwipeButton()
                  },
                  onAction: () => {
                    this.deleteTodo(item.id);
                  }
                }
              })
              .margin({ left: 16, right: 16, top: 4, bottom: 4 })
            }, (item: TodoItem) => `${item.id}_${item.updatedAt}`)
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor('#F5F5F5')
          .padding({ top: 8, bottom: 8 })
        }

        // ===== 底部输入栏 =====
        if (!this.isSelectionMode) {
          TodoInputBar({
            onAdd: (title: string, priority: number) => {
              this.handleAdd(title, priority);
            }
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    // 长按进入多选模式 — 监听整个 Stack
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (!this.isSelectionMode) {
            this.enterSelectionMode();
          }
        })
    )
  }

  @Builder
  DeleteSwipeButton() {
    Row() {
      Text('删除')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .margin({ left: 16, right: 16 })
    }
    .height('100%')
    .backgroundColor('#FF3B30')
    .justifyContent(FlexAlign.Center)
  }

  private getPriorityColor(priority: number): string {
    const colors: Record<number, string> = { 1: '#FF3B30', 2: '#FF9500', 3: '#34C759' };
    return colors[priority] || '#999999';
  }
}

/**
 * 编辑待办对话框
 */
@CustomDialog
struct TodoEditDialog {
  @Link title: string;
  @Link description: string;
  @Link priority: number;
  controller: CustomDialogController;
  onConfirm: () => void = () => {};

  build() {
    Column() {
      // 标题
      Text('编辑待办')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 20, bottom: 16 })

      TextInput({ placeholder: '待办标题', text: this.title })
        .width('100%')
        .height(44)
        .fontSize(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.title = value;
        })

      TextInput({ placeholder: '描述（选填）', text: this.description })
        .width('100%')
        .height(44)
        .fontSize(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.description = value;
        })

      Row() {
        Text('优先级')
          .fontSize(15)
          .fontColor('#666666')
        Blank()
        Row() {
          this.PriorityOption(1, '高', '#FF3B30')
          this.PriorityOption(2, '中', '#FF9500')
          this.PriorityOption(3, '低', '#34C759')
        }
      }
      .width('100%')
      .margin({ top: 16 })

      Row() {
        Button('取消')
          .fontSize(15)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .onClick(() => {
            this.controller.close();
          })

        Button('保存')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .margin({ left: 12 })
          .onClick(() => {
            this.onConfirm();
          })
      }
      .width('100%')
      .margin({ top: 20, bottom: 20 })
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ left: 20, right: 20 })
    .width("90%")
  }

  @Builder
  PriorityOption(value: number, label: string, color: string) {
    Row() {
      Circle()
        .width(12)
        .height(12)
        .fill(color)
      Text(label)
        .fontSize(13)
        .fontColor(this.priority === value ? '#FFFFFF' : '#666666')
        .margin({ left: 4, right: 4 })
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor(this.priority === value ? color + '30' : '#F0F0F0')
    .borderRadius(14)
    .margin({ left: 4 })
    .onClick(() => {
      this.priority = value;
    })
  }
}
