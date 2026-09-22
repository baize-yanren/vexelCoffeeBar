export class ThemeColors {
  static readonly DEFAULT: string = '#6F4E37';
  static readonly PRESETS: string[] = ['#6F4E37', '#8B5E3C', '#B0653A', '#4E7A5C', '#5B6D9E', '#A0522D'];
}

export class AppKeys {
  static readonly THEME_COLOR: string = 'themeColor';
  static readonly DATA_VERSION: string = 'dataVersion';
  static readonly DEFAULT_BREW_METHOD: string = 'defaultBrewMethod';
  static readonly IMPORT_DRAFT: string = 'importDraft';
  static readonly AUTO_CLIPBOARD: string = 'autoClipboard';
  static readonly LAST_IMPORTED: string = 'lastImportedText';
  static readonly COLOR_MODE: string = 'isDarkMode';
}

export class ThemePalette {
  private static rgb(color: string): number[] {
    const hex: string = color.replace('#', '');
    return [parseInt(hex.substring(0, 2), 16), parseInt(hex.substring(2, 4), 16), parseInt(hex.substring(4, 6), 16)];
  }

  private static toHex(v: number): string {
    const s: string = v.toString(16).toUpperCase();
    return v < 16 ? `0${s}` : s;
  }

  private static blend(color: string, base: number[], ratio: number): string {
    const c: number[] = ThemePalette.rgb(color);
    const r: number = Math.round(base[0] + (c[0] - base[0]) * ratio);
    const g: number = Math.round(base[1] + (c[1] - base[1]) * ratio);
    const b: number = Math.round(base[2] + (c[2] - base[2]) * ratio);
    return `#${ThemePalette.toHex(r)}${ThemePalette.toHex(g)}${ThemePalette.toHex(b)}`;
  }

  static alpha(color: string, a: number): string {
    const c: number[] = ThemePalette.rgb(color);
    return `rgba(${c[0]},${c[1]},${c[2]},${a})`;
  }

  static page(color: string, dark: boolean): string {
    return dark ?
      ThemePalette.blend(color, [22, 19, 16], 0.16) :
      ThemePalette.blend(color, [255, 255, 255], 0.09);
  }

  static tint(color: string, dark: boolean, ratio: number): string {
    return dark ?
      ThemePalette.blend(color, [36, 31, 27], ratio) :
      ThemePalette.blend(color, [255, 255, 255], ratio);
  }
}
