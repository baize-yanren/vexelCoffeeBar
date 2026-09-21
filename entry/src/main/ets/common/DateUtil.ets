export class DateUtil {
  static pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }

  static formatDate(ts: number): string {
    if (ts <= 0) {
      return '';
    }
    const d = new Date(ts);
    return `${d.getFullYear()}-${DateUtil.pad(d.getMonth() + 1)}-${DateUtil.pad(d.getDate())}`;
  }

  static formatDateTime(ts: number): string {
    if (ts <= 0) {
      return '';
    }
    const d = new Date(ts);
    return `${DateUtil.formatDate(ts)} ${DateUtil.pad(d.getHours())}:${DateUtil.pad(d.getMinutes())}`;
  }

  static formatDuration(sec: number): string {
    if (sec <= 0) {
      return '';
    }
    const m: number = Math.floor(sec / 60);
    const s: number = sec % 60;
    if (m === 0) {
      return `${s}秒`;
    }
    return `${m}分${s}秒`;
  }

  static formatPrice(price: number): string {
    return `¥${price}`;
  }
}
