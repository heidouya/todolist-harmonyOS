// 文档地址：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-relationalstore
import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { TodoItem, FilterType } from './TodoItem';
import { Logger } from '../utils/Logger';

const DB_NAME = 'todo.db';
const TABLE_NAME = 'todos';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

// 建表 SQL
const SQL_CREATE_TABLE = `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  completed INTEGER DEFAULT 0,
  priority INTEGER DEFAULT 2,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)`;

let rdbStore: relationalStore.RdbStore | null = null;

/**
 * Todo 数据库管理器
 * 封装所有数据库 CRUD 操作
 */
export class TodoDatabase {
  /**
   * 初始化数据库，创建 todos 表
   * @param context 应用上下文
   */
  static async initDatabase(context: common.Context): Promise<void> {
    try {
      rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await rdbStore.executeSql(SQL_CREATE_TABLE);
      Logger.info('Database initialized successfully');
    } catch (err) {
      Logger.error('Failed to init database: %{public}s', JSON.stringify(err));
      throw err;
    }
  }

  /**
   * 结果集转 TodoItem 数组
   */
  private static parseResultSet(resultSet: relationalStore.ResultSet): TodoItem[] {
    const todos: TodoItem[] = [];
    while (resultSet.goToNextRow()) {
      todos.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        description: resultSet.getString(resultSet.getColumnIndex('description')),
        completed: resultSet.getLong(resultSet.getColumnIndex('completed')) === 1,
        priority: resultSet.getLong(resultSet.getColumnIndex('priority')),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('createdAt')),
        updatedAt: resultSet.getLong(resultSet.getColumnIndex('updatedAt'))
      });
    }
    return todos;
  }

  /**
   * 插入待办，返回自增 id
   */
  static async insertTodo(item: TodoItem): Promise<number> {
    if (!rdbStore) {
      Logger.error('Database not initialized');
      return -1;
    }
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        title: item.title,
        description: item.description,
        completed: item.completed ? 1 : 0,
        priority: item.priority,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt
      };
      const rowId = await rdbStore.insert(TABLE_NAME, valueBucket);
      Logger.info('Inserted todo, rowId: %{public}d', rowId);
      return rowId;
    } catch (err) {
      Logger.error('Failed to insert todo: %{public}s', JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 更新指定待办的字段
   */
  static async updateTodo(id: number, updates: Partial<TodoItem>): Promise<number> {
    if (!rdbStore) {
      Logger.error('Database not initialized');
      return 0;
    }
    try {
      const valueBucket: relationalStore.ValuesBucket = {};
      if (updates.title !== undefined) {
        valueBucket['title'] = updates.title;
      }
      if (updates.description !== undefined) {
        valueBucket['description'] = updates.description;
      }
      if (updates.completed !== undefined) {
        valueBucket['completed'] = updates.completed ? 1 : 0;
      }
      if (updates.priority !== undefined) {
        valueBucket['priority'] = updates.priority;
      }
      if (updates.updatedAt !== undefined) {
        valueBucket['updatedAt'] = updates.updatedAt;
      }

      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('id', id);
      const rows = await rdbStore.update(valueBucket, predicates);
      Logger.info('Updated todo, affected rows: %{public}d', rows);
      return rows;
    } catch (err) {
      Logger.error('Failed to update todo: %{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 单条删除
   */
  static async deleteTodo(id: number): Promise<number> {
    if (!rdbStore) {
      Logger.error('Database not initialized');
      return 0;
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('id', id);
      const rows = await rdbStore.delete(predicates);
      Logger.info('Deleted todo, affected rows: %{public}d', rows);
      return rows;
    } catch (err) {
      Logger.error('Failed to delete todo: %{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 批量删除
   */
  static async deleteBatch(ids: number[]): Promise<number> {
    if (!rdbStore || ids.length === 0) {
      return 0;
    }
    try {
      // 构建 IN 子句的占位符
      const placeholders = ids.map(() => '?').join(',');
      const sql = `DELETE FROM ${TABLE_NAME} WHERE id IN (${placeholders})`;
      await rdbStore.executeSql(sql, ids as relationalStore.ValueType[]);
      Logger.info('Batch deleted, count: %{public}d', ids.length);
      return ids.length;
    } catch (err) {
      Logger.error('Failed to batch delete: %{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 组合查询
   * @param filter 筛选条件：'all' / 'active' / 'completed'
   * @param keyword 搜索关键词，为空则查全部
   * @returns 按 createdAt 降序排列的待办列表
   */
  static async queryTodos(filter: FilterType, keyword: string): Promise<TodoItem[]> {
    if (!rdbStore) {
      Logger.error('Database not initialized');
      return [];
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);

      // 按完成状态筛选
      if (filter === 'active') {
        predicates.equalTo('completed', 0);
      } else if (filter === 'completed') {
        predicates.equalTo('completed', 1);
      }

      // 按关键词模糊搜索标题
      if (keyword && keyword.trim().length > 0) {
        predicates.like('title', `%${keyword.trim()}%`);
      }

      // 按创建时间降序排列
      predicates.orderByDesc('createdAt');

      const resultSet = await rdbStore.query(predicates, [
        'id', 'title', 'description', 'completed', 'priority', 'createdAt', 'updatedAt'
      ]);
      const todos = TodoDatabase.parseResultSet(resultSet);
      resultSet.close();
      return todos;
    } catch (err) {
      Logger.error('Failed to query todos: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 切换完成状态，同时更新 updatedAt
   */
  static async toggleTodo(id: number): Promise<number> {
    if (!rdbStore) {
      Logger.error('Database not initialized');
      return 0;
    }
    try {
      // 先查询当前完成状态
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('id', id);
      const resultSet = await rdbStore.query(predicates, ['completed']);
      if (!resultSet.goToNextRow()) {
        resultSet.close();
        return 0;
      }
      const currentCompleted = resultSet.getLong(resultSet.getColumnIndex('completed'));
      resultSet.close();

      // 切换状态
      const valueBucket: relationalStore.ValuesBucket = {
        completed: currentCompleted === 1 ? 0 : 1,
        updatedAt: Date.now()
      };
      const rows = await rdbStore.update(valueBucket, predicates);
      Logger.info('Toggled todo, new status: %{public}d', currentCompleted === 1 ? 0 : 1);
      return rows;
    } catch (err) {
      Logger.error('Failed to toggle todo: %{public}s', JSON.stringify(err));
      return 0;
    }
  }

}
