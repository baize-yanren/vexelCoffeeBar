import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppKeys, ThemeColors } from '../common/Theme';
import { BrewMethod } from '../model/Models';

export class SettingsStore {
  private static instance: SettingsStore | undefined = undefined;
  private store: preferences.Preferences | undefined = undefined;

  static getInstance(): SettingsStore {
    if (SettingsStore.instance === undefined) {
      SettingsStore.instance = new SettingsStore();
    }
    return SettingsStore.instance;
  }

  init(context: common.UIAbilityContext): void {
    if (this.store !== undefined) {
      return;
    }
    this.store = preferences.getPreferencesSync(context, { name: 'settings' });
    this.loadToAppStorage();
  }

  loadToAppStorage(): void {
    if (this.store === undefined) {
      return;
    }
    const theme: string = this.store.getSync(AppKeys.THEME_COLOR, ThemeColors.DEFAULT) as string;
    const method: string =
      this.store.getSync(AppKeys.DEFAULT_BREW_METHOD, BrewMethod.POUR_OVER) as string;
    AppStorage.setOrCreate(AppKeys.THEME_COLOR, theme);
    AppStorage.setOrCreate(AppKeys.DEFAULT_BREW_METHOD, method);
    AppStorage.setOrCreate(AppKeys.DATA_VERSION, 0);
  }

  getThemeColor(): string {
    return AppStorage.get<string>(AppKeys.THEME_COLOR) ?? ThemeColors.DEFAULT;
  }

  setThemeColor(color: string): void {
    if (this.store !== undefined) {
      this.store.putSync(AppKeys.THEME_COLOR, color);
      this.store.flush();
    }
    AppStorage.set(AppKeys.THEME_COLOR, color);
  }

  getDefaultBrewMethod(): string {
    return AppStorage.get<string>(AppKeys.DEFAULT_BREW_METHOD) ?? BrewMethod.POUR_OVER;
  }

  setDefaultBrewMethod(method: string): void {
    if (this.store !== undefined) {
      this.store.putSync(AppKeys.DEFAULT_BREW_METHOD, method);
      this.store.flush();
    }
    AppStorage.set(AppKeys.DEFAULT_BREW_METHOD, method);
  }

  isAutoClipboard(): boolean {
    if (this.store === undefined) {
      return true;
    }
    return this.store.getSync(AppKeys.AUTO_CLIPBOARD, true) as boolean;
  }

  setAutoClipboard(on: boolean): void {
    if (this.store !== undefined) {
      this.store.putSync(AppKeys.AUTO_CLIPBOARD, on);
      this.store.flush();
    }
  }
}
