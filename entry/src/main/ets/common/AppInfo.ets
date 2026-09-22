import { bundleManager, common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

export class AppInfoData {
  name: string = '咖啡志';
  slogan: string = '记录每一杯咖啡的美好';
  versionName: string = '1.0.0';
  versionCode: string = '1000000';
  buildVersion: string = '1';
  userAgreement: string = '开发中，敬请期待';
  privacyPolicy: string = '开发中，敬请期待';
}

export class AppInfo {
  private static str(obj: Record<string, Object>, key: string, fallback: string): string {
    const v: Object | undefined = obj[key];
    return v === undefined ? fallback : `${v}`;
  }

  static load(context: common.Context): AppInfoData {
    const data: AppInfoData = new AppInfoData();
    try {
      const raw: Uint8Array = context.resourceManager.getRawFileContentSync('app-info.json');
      const text: string = util.TextDecoder.create('utf-8').decodeToString(raw);
      const obj: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
      data.name = AppInfo.str(obj, 'name', data.name);
      data.slogan = AppInfo.str(obj, 'slogan', data.slogan);
      data.versionName = AppInfo.str(obj, 'versionName', data.versionName);
      data.versionCode = AppInfo.str(obj, 'versionCode', data.versionCode);
      data.buildVersion = AppInfo.str(obj, 'buildVersion', data.buildVersion);
      data.userAgreement = AppInfo.str(obj, 'userAgreement', data.userAgreement);
      data.privacyPolicy = AppInfo.str(obj, 'privacyPolicy', data.privacyPolicy);
      return data;
    } catch (e) {
      console.error(`read app-info.json failed: ${e}`);
    }
    try {
      const info: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      data.versionName = info.versionName;
      data.versionCode = `${info.versionCode}`;
    } catch (e) {
      console.error(`get bundle version failed: ${e}`);
    }
    return data;
  }
}
