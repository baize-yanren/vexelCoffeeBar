# Vexel Coffee Bar（咖啡志）

一款专为咖啡爱好者打造的 HarmonyOS 原生应用：记录咖啡豆库藏、器具清单与每一次冲煮，支持**分冲煮方式的差异化参数记录**、**首页花销数据分析**、**深色模式与主题色**，以及**数据导出 / 导入备份**，还可从电商分享链接 / 订单截图一键导入商品信息，告别手动录入。

![Platform](https://img.shields.io/badge/platform-HarmonyOS-1F6FEB) ![SDK](https://img.shields.io/badge/SDK-6.1.1(24)-orange) ![Language](https://img.shields.io/badge/language-ArkTS-teal) ![Version](https://img.shields.io/badge/version-0.1.3-blue) ![License](https://img.shields.io/badge/license-MIT-green)

## 功能特性

### 四大主页（底部 Dock 切换）

- **📊 首页** — 数据分析仪表盘：
  - 咖啡豆分析：购豆总花费、克均价
  - 冲煮统计：累计冲煮次数、平均每次冲煮花销，并给出 **总均价 = 总豆均价 + 器具均价** 公式横幅
  - 器具统计：器具清单（种类 / 品牌 / 型号 / 价格），可直接编辑、删除
- **📖 库藏** — 咖啡豆卡片（名称、品种、产地、克重、烘焙度、处理法、烘焙日期、赏味期、风味标签、价格、商家、购买时间）与器具卡片（种类、品牌·型号、新旧成色、配件、价格、备注），支持新增 / 编辑 / 删除
- **⏱ 冲煮** — 冲煮记录时间轴，**按 8 种冲煮方式差异化记录**（手冲 / 摩卡壶 / 意式 / 爱乐压 / 冷萃 / 法压壶 / 虹吸壶 / 其他），支持按方式筛选
- **👤 我的** — 主题色即时切换（6 种预设，全局派生配色）、默认冲煮方式、剪贴板自动检测开关、**数据导出 / 导入**、清空数据、版本信息、用户协议、隐私政策

### 分冲煮方式的差异化记录

| 冲煮方式 | 专属字段 |
| --- | --- |
| 手冲 | 注水计划（1–5 段，每段注水量 + 注水时间，行数跟随注水次数动态生成）、闷蒸（水量 / 时间）、总水量、水温、研磨度、总萃取时长 |
| 摩卡壶 | 萃取时长、水量、火候（小火 / 中火 / 大火）、出品量 |
| 意式 | 萃取压力、浓缩重量 |
| 爱乐压 | 浸泡时间、压下时长 |
| 冷萃 | 冷藏时长（自动换算「= X 小时」） |

- 每次冲煮保存时按 `豆价 ÷ 克重 × 粉量` **定格记录耗豆成本**，之后修改豆价不影响历史记录
- 时长输入实时显示换算提示（如 `= 2分30秒`）
- 列表卡片按方式显示专属摘要（闷蒸 30g/30s、一注~五注、冷藏 12小时、火候 中火 等）

### 订单信息一键导入

| 入口 | 流程 |
| --- | --- |
| 复制电商分享文案 → 打开 App | 自动检测剪贴板中的淘宝 / 京东 / 拼多多链接，弹出磨砂预览层，一键预填表单 |
| 加号菜单「🔗 从剪贴板导入」 | 手动触发同样的剪贴板识别流程 |
| 表单页「📷 从订单截图导入」 | 从相册选择订单截图，端侧 OCR 识别商品名 / 价格 / 商家 / 日期 / 品牌 / 型号并逐项填入 |

- 解析结果**先预览、后预填、保存前可修改**，绝不静默写库
- 按商品标题关键词自动分类：咖啡豆 → 「填入咖啡豆表单」高亮推荐；壶 / 磨豆机 / 滤杯等 → 「填入器具表单」高亮推荐
- 相同剪贴板内容不重复弹窗；识别失败静默降级，不打断使用

### 数据备份与恢复

- **导出**：一键将全部咖啡豆、器具、冲煮记录导出为 JSON 备份文件（系统文件保存器，无需权限）
- **导入**：从备份文件恢复，覆盖前弹窗显示数据条数并二次确认；事务化写入，失败自动回滚；按原 ID 还原，保留冲煮与豆子的关联

### 体验细节

- **深色模式跟随系统**：14 组语义色全量适配（base + dark 双份 `color.json`）
- **主题色全局派生**：页面背景、标签底色、提示横幅、阴影均由主题色派生，一处切换全局生效
- 磨砂玻璃 Dock + 半模态加号菜单 + 底部弹层动效（TransitionEffect）
- 软件信息（名称 / 版本 / 标语 / 协议）统一由 `rawfile/app-info.json` 驱动
- 数据本地持久化，应用重启不丢失；老版本数据自动无损迁移

## 技术栈与架构

- **语言 / 框架**：ArkTS + ArkUI（声明式 UI，@Entry / @Component / @Builder / 状态装饰器）
- **SDK**：HarmonyOS 6.1.1(24)，`runtimeOS: HarmonyOS`
- **数据层**：RelationalStore（关系型数据库，三张表 + `extra` JSON 扩展列）+ Preferences（键值设置）
- **能力套件**：BasicServicesKit（剪贴板）、NetworkKit（HTTP）、CoreFileKit（文件选择器 / 相册选择器 / 文件读写）、ImageKit（图片解码）、CoreVisionKit（端侧 OCR 文字识别）

```
entry/src/main/ets/
├── common/          # 主题常量与派生、AppStorage Key 注册表、AppInfo（rawfile 读取）、日期工具
├── model/           # 数据模型（CoffeeBean / Equipment / BrewRecord / BrewFieldConfig / PourPlan ...）
├── data/            # CoffeeDb（RelationalStore + 迁移 + restoreAll）、SettingsStore（Preferences）
├── service/         # 解析与编排（ShareParser / OcrParser / LinkFetcher / OcrImport / ClipboardImport / DataBackup）
├── components/      # 通用组件（卡片、OptionSheet、ImportPreviewSheet）
├── pages/           # 页面（Index 四 Tab：HomeView / LibraryView / BrewLogView / MineView + 各表单页）
└── entryability/    # Ability 入口（深色模式跟随系统）
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
