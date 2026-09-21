# 咖啡志（vexelCoffeeBar）

一款专为手冲咖啡爱好者打造的 HarmonyOS 原生应用：记录咖啡豆库藏、器具清单与每一次冲煮，并支持从电商分享链接 / 订单截图**一键导入**商品信息，告别手动录入。

![Platform](https://img.shields.io/badge/platform-HarmonyOS-1F6FEB) ![SDK](https://img.shields.io/badge/SDK-6.1.1(24)-orange) ![Language](https://img.shields.io/badge/language-ArkTS-teal) ![License](https://img.shields.io/badge/license-MIT-green)

## 功能特性

### 三大主页（底部 Dock 切换）

- **📖 库藏** — 咖啡豆卡片（品种、名称、风味标签、价格、商家、购买时间）与器具卡片（种类、品牌、型号）管理，支持新增 / 编辑 / 删除
- **⏱ 冲煮** — 冲煮记录时间轴：豆子 × 器具 × 手法（手冲 / 法压 / 摩卡 / 冷萃 / 浓缩 / 爱乐压）× 研磨度 × 粉水比 × 水温 × 用时 × 主观评分与备注
- **👤 我的** — 主题色即时切换（6 种预设）、默认冲煮方式、剪贴板自动检测开关、数据清空、版本信息

### 订单信息一键导入（v1.1 核心特性）

| 入口 | 流程 |
| --- | --- |
| 复制电商分享文案 → 打开 App | 自动检测剪贴板中的淘宝 / 京东 / 拼多多链接，弹出磨砂预览层，一键预填表单 |
| 加号菜单「🔗 从剪贴板导入」 | 手动触发同样的剪贴板识别流程 |
| 表单页「📷 从订单截图导入」 | 从相册选择订单截图，端侧 OCR 识别商品名 / 价格 / 商家 / 日期 / 品牌 / 型号并逐项填入 |

- 解析结果**先预览、后预填、保存前可修改**，绝不静默写库
- 按商品标题关键词自动分类：咖啡豆 → 「填入咖啡豆表单」高亮推荐；壶 / 磨豆机 / 滤杯等 → 「填入器具表单」高亮推荐
- 相同剪贴板内容不重复弹窗；识别失败静默降级，不打断使用

### 体验细节

- 磨砂玻璃 Dock + 半模态加号菜单 + 底部弹层动效（TransitionEffect）
- 主题色全局即时生效（AppStorage 驱动）
- 数据本地持久化，应用重启不丢失

## 技术栈与架构

- **语言 / 框架**：ArkTS + ArkUI（声明式 UI，@Entry / @Component / @Builder / 状态装饰器）
- **SDK**：HarmonyOS 6.1.1(24)，`runtimeOS: HarmonyOS`
- **数据层**：RelationalStore（关系型数据库，三张表）+ Preferences（键值设置）
- **能力套件**：BasicServicesKit（剪贴板）、NetworkKit（HTTP）、CoreFileKit（相册选择器）、ImageKit（图片解码）、CoreVisionKit（端侧 OCR 文字识别）

```
entry/src/main/ets/
├── common/          # 主题常量、AppStorage Key 注册表、日期工具
├── model/           # 数据模型（CoffeeBean / Equipment / BrewRecord / ImportDraft ...）
├── data/            # CoffeeDb（RelationalStore）、SettingsStore（Preferences）
├── service/         # 解析与编排（ShareParser / OcrParser / LinkFetcher / OcrImport / ClipboardImport）
├── components/      # 通用组件（卡片、OptionSheet、ImportPreviewSheet）
├── pages/           # 页面（Index 三 Tab + 各表单页）
└── entryability/    # Ability 入口
```

详细模块说明、接口用法与开发记录见 [DEVELOPMENT.md](./DEVELOPMENT.md)。

## 构建与运行

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（含 HarmonyOS SDK 6.1.1(24) 及以上）
2. 用 DevEco Studio 打开项目根目录，等待 oh_modules 同步完成
3. 连接真机或启动模拟器，点击 Run；或命令行：

```bash
hvigorw assembleHap   # 构建
```

## 目录导航

- [DEVELOPMENT.md](./DEVELOPMENT.md) — 已实现功能清单、Kit / API 用法速查、架构约定与后续开发指南
- [LICENSE](./LICENSE) — MIT 开源许可

## 许可

[MIT License](./LICENSE) © 2026 baize-yanren
