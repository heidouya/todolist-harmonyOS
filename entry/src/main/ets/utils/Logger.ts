import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
const TAG = 'TodoApp';

/**
 * 日志工具类
 */
export class Logger {
  /**
   * 输出 info 级别日志
   */
  static info(format: string, ...args: Object[]): void {
    hilog.info(DOMAIN, TAG, format, args);
  }

  /**
   * 输出 error 级别日志
   */
  static error(format: string, ...args: Object[]): void {
    hilog.error(DOMAIN, TAG, format, args);
  }

  /**
   * 输出 warn 级别日志
   */
  static warn(format: string, ...args: Object[]): void {
    hilog.warn(DOMAIN, TAG, format, args);
  }

  /**
   * 输出 debug 级别日志
   */
  static debug(format: string, ...args: Object[]): void {
    hilog.debug(DOMAIN, TAG, format, args);
  }
}
