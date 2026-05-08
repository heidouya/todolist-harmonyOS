/**
 * 待办事项数据模型
 */
export interface TodoItem {
  id: number;         // 主键，自增，由数据库自动生成
  title: string;      // 待办标题（必填）
  description: string; // 待办描述（选填）
  completed: boolean;  // 是否已完成，默认 false
  priority: number;    // 优先级：1=高, 2=中, 3=低
  createdAt: number;   // 创建时间戳（毫秒）
  updatedAt: number;   // 最后更新时间戳（毫秒）
}

/**
 * 优先级枚举
 */
export enum Priority {
  HIGH = 1,    // 高
  MEDIUM = 2,  // 中
  LOW = 3      // 低
}

/**
 * 筛选类型
 */
export type FilterType = 'all' | 'active' | 'completed';

/**
 * 各状态待办数量统计
 */
export interface TodoCounts {
  all: number;
  active: number;
  completed: number;
}

/**
 * 优先级标签映射
 */
export const PRIORITY_LABELS: Record<number, string> = {
  [Priority.HIGH]: '高',
  [Priority.MEDIUM]: '中',
  [Priority.LOW]: '低'
};

/**
 * 优先级颜色映射
 */
export const PRIORITY_COLORS: Record<number, string> = {
  [Priority.HIGH]: '#FF3B30',   // 红色
  [Priority.MEDIUM]: '#FF9500', // 橙色
  [Priority.LOW]: '#34C759'     // 绿色
};
