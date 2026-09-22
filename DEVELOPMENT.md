# Vexel Coffee Bar（咖啡志）— 开发记录与维护指南

> 本文档记录项目已实现的功能、使用的系统 Kit / API、关键机制与约定，供后续维护与继续开发参考。
> 项目简介见 [README.md](./README.md)。

- 版本：0.1.3（versionCode 1000103）— **唯一权威来源为根目录 `app-info.json`**，需与 `entry/src/main/resources/rawfile/app-info.json`、`AppScope/app.json5` 保持同步
- Bundle：`com.example.vexelcoffeebar`
- SDK：HarmonyOS 6.1.1(24)，`compileSdkVersion = compatibleSdkVersion = 6.1.1(24)`，`runtimeOS: HarmonyOS`
- 模块：单模块 `entry`（phone），无 HAR/HSP 依赖，无第三方 ohpm 包
- 权限：`ohos.permission.INTERNET`（LinkFetcher 抓取网页标题）

---

## 一、开发阶段记录

### 阶段 1：基础应用（已完成）

- 三 Tab 主页（库藏 / 冲煮 / 我的）+ 磨砂玻璃 Dock + 加号半模态菜单
- 咖啡豆 / 器具 / 冲煮记录三表 CRUD，卡片式展示
- RelationalStore 持久化 + Preferences 设置项
- 主题色 6 种预设即时生效、默认冲煮方式、清空数据（AlertDialog 确认）

### 阶段 2：订单信息一键导入（已完成）

- **剪贴板导入**：`Index.onPageShow` 自动检测 + 加号菜单「从剪贴板导入」手动入口 → 弹出 `ImportPreviewSheet` 预览 → 选择目标表单 → 预填并提示核对
- **截图 OCR 导入**：两个表单页「📷 从订单截图导入」按钮 → 相册选图 → 端侧 OCR → 逐字段预填 + Toast「已识别填入 N 项」
- **设置开关**：「自动检测剪贴板」Toggle（默认开，Preferences 持久化）
- **防重复**：同一剪贴板文本只弹一次（AppStorage 记录上次文本）

### 阶段 3：深色模式与主题色体系（已完成）

- `color.json` 双份（`base/` + `dark/` 各 14 组语义色：页面背景、卡片背景、主文本~禁用文本、分隔线、提示横幅、危险色等）
- `EntryAbility` 维护 `isDarkMode` 跟随系统；全部页面统一使用 `$r('app.color.*')`，禁止硬编码颜色
- `Theme.ets` 新增 `ThemePalette`：主题色的 `alpha(c, a)` / `page(c)` / `tint(c)` 派生，页面背景、标签底、提示横幅整体跟随主题色

### 阶段 4：数据模型扩展与分方式冲煮表单（已完成）

- **咖啡豆**新增：产地 origin / 克重 weight / 烘焙度 roastLevel（浅焙~深焙 5 档）/ 烘焙日期 roastDate / 处理法 processMethod（日晒 / 水洗 / 蜜处理 / 湿刨法 / 厌氧发酵 / 其他）/ 赏味期 shelfLife
- **器具**新增：配件 accessories / 新旧成色 conditionState（全新 / 二手）
- **冲煮记录**新增 13 个扩展字段 + pour3/4/5 Water/Time + **耗豆成本 beanCost**，全部经 `toExtraJson() / applyExtraJson()` 存入单列 `extra`（JSON 字符串）
- `BrewMethod.ALL` 扩至 8 种：手冲 / 摩卡壶 / 意式 / 爱乐压 / 冷萃 / 法压壶 / 虹吸壶 / 其他
- `BrewFieldConfig.of(method)` 按方式声明字段开关（水量 / 水温 / 研磨 / 时长 / 出品量 / 火候 / 注水计划 / 闷蒸 / 压力 / 浸泡 / 压下时长）
- `PourPlan`（MAX=5 + 中文序数）+ `pourWaterAt/setPourWaterAt/pourTimeAt/setPourTimeAt` 索引助手
- **手冲注水计划**：注水次数 1–5，行数动态生成；次数改小自动丢弃多余数据
- **beanCost 定格**：保存时 `Math.round(豆价 / 克重 × 粉量, 2)` 写入记录，之后改豆价不影响历史
- BrewFormPage / BeanFormPage / EquipmentFormPage 全部重写；BrewCard 按方式显示专属摘要（maxLines 2）

### 阶段 5：首页数据分析（已完成）

- 新建 `HomeView.ets`，Index dock 最左侧新增「📊 首页」Tab（原 Tab 顺移，共 4 Tab）
- 咖啡豆分析：共花费 / 克均价；冲煮统计：次数 / 平均花销 + 公式横幅；器具统计列表复用 `EquipmentCard`（可编辑 / 删除）
- 统计口径：总豆均价 = 所有冲煮 `beanCost` 平均值；器具均价 = 器具总支出 ÷ 冲煮次数；总均价 = 总豆均价 + 器具均价

### 阶段 6：软件信息统一与数据导入导出（已完成）

- **软件信息 / Logo**：根目录 `app-info.json` 为权威源，`rawfile/app-info.json` 镜像；`AppInfo.ets` 用 `getRawFileContentSync` 读取；应用名 / 版本号 / Logo 三处同步
- **导出**：`DataBackup.exportToFile(context)` → 全量查询 → 组装 JSON → `DocumentViewPicker.save` 保存
- **导入**：`DocumentViewPicker.select` 选文件 → utf-8 读取解析 → 确认弹窗（显示条数 + 覆盖警告）→ `CoffeeDb.restoreAll()` 事务化覆盖还原 → `dataVersion +1` 全局刷新
- 备份 JSON 格式：`{ app: 'Vexel Coffee Bar', format: 1, exportedAt, beans[], equipments[], brews[] }`；冲煮的 `extra` 为 JSON 字符串字段，导入时 `applyExtraJson` 还原，无损且简单

---

## 二、文件地图

```
entry/src/main/ets/
├── common/
│   ├── Theme.ets           # ThemeColors（6 预设）、ThemePalette（alpha/page/tint 派生）、AppKeys
│   ├── AppInfo.ets         # rawfile/app-info.json 读取（getRawFileContentSync），AppInfoData
│   └── DateUtil.ets        # formatDate 等
├── model/
│   ├── Models.ets          # CoffeeBean / Equipment / BrewRecord（toExtraJson/applyExtraJson）
│   │                       # BrewMethod(8) / BrewFieldConfig / PourPlan / HeatLevel / GrindSize
│   │                       # EquipmentType(12) / RoastLevel / ProcessMethod / ConditionState
│   ├── RouteParams.ets     # FormParams { id }
│   └── ImportDraft.ets     # ImportDraft / ShareParseResult / OcrParseResult / CategoryKeywords
├── data/
│   ├── CoffeeDb.ets        # RelationalStore 单例：三表建表 + 9 条 ALTER 迁移 + CRUD
│   │                       # + clearAll + restoreAll（事务覆盖还原）
│   └── SettingsStore.ets   # Preferences 单例：主题色 / 默认冲煮方式 / autoClipboard
├── service/
│   ├── ShareParser.ets     # 分享文本解析：平台识别 / URL / 价格 / 标题 / 电商域名过滤
│   ├── OcrParser.ets       # OCR 全文 → 结构化字段（价格/日期/商家/标题/品牌/型号/类型）
│   ├── LinkFetcher.ets     # best-effort 网页 <title> 抓取（5s 超时，失败返回 ''）
│   ├── OcrImport.ets       # 选图 → 解码 → 缩放 → OCR → 解析，三态结果
│   ├── ClipboardImport.ets # 剪贴板读取 → 过滤去重 → 解析 → 组装 ImportDraft
│   └── DataBackup.ets      # 导出 JSON 构建 + DocumentViewPicker 保存/读取 + 解析还原
├── components/
│   ├── BeanCard.ets / EquipmentCard.ets / BrewCard.ets   # 卡片（BrewCard 按方式显示专属摘要）
│   ├── OptionSheet.ets           # 通用底部磨砂选项弹层（OptionItem）
│   └── ImportPreviewSheet.ets    # 导入预览弹层（商品/价格/来源 + 双目标按钮）
├── pages/
│   ├── Index.ets           # @Entry 主页：四 Tab（首页/库藏/冲煮/我的）+ Dock + 加号菜单
│   ├── HomeView.ets        # 首页数据分析（三卡片：豆 / 冲煮 / 器具）
│   ├── LibraryView.ets     # 库藏 Tab（咖啡豆 / 器具两段）
│   ├── BrewLogView.ets     # 冲煮 Tab（按 8 种方式 chips 筛选）
│   ├── MineView.ets        # 我的 Tab（主题色 / 设置 / 数据管理 / 版本信息）
│   ├── BeanFormPage.ets    # 咖啡豆表单（草稿消费 + 截图导入 + 新字段）
│   ├── EquipmentFormPage.ets # 器具表单（草稿消费 + 截图导入 + 配件/成色）
│   └── BrewFormPage.ets    # 冲煮表单（BrewFieldConfig 分方式动态表单 + 注水计划 1–5 段）
├── entryability/EntryAbility.ets          # 深色模式跟随系统（isDarkMode）
└── entrybackupability/EntryBackupAbility.ets

resources/
├── base/element/color.json     # 14 组语义色（浅色）
└── dark/element/color.json     # 14 组语义色（深色）
```

---

## 三、关键机制

### 1. AppStorage Key 注册表（common/Theme.ets `AppKeys`）

| Key | 用途 | 读 / 写方 |
| --- | --- | --- |
| `themeColor` | 当前主题色 | 全组件 `@StorageProp`；MineView 写 |
| `dataVersion` | 列表数据版本号 | 保存/删除/导入后 `+1`；列表页 `@StorageLink + @Watch` 刷新 |
| `defaultBrewMethod` | 默认冲煮方式 | MineView 写，BrewFormPage 读 |
| `importDraft` | 待预填的订单草稿（ImportDraft 实例） | Index 写，表单页 `aboutToAppear` 消费后**立即置空** |
| `autoClipboard` | 剪贴板自动检测开关（仅 Preferences，不常驻 AppStorage） | MineView Toggle 写 |
| `lastImportedText` | 上次已处理的剪贴板文本（防重复） | ClipboardImport 读写 |

### 2. 数据刷新（dataVersion 机制）

- 任何写库操作成功后 `AppStorage.setOrCreate('dataVersion', +1)`
- 列表页用 `@StorageLink('dataVersion') dataVersion + @Watch('onVersion')` 触发重新查询
- `ForEach` 的 key 生成函数带 `_v${dataVersion}` 后缀，强制子组件重建（规避同 key 复用不刷新）

### 3. 数据库迁移（无损升级）

- 建表统一 `CREATE TABLE IF NOT EXISTS`
- 新列逐条 `ALTER TABLE ... ADD COLUMN ...`，每条 try-catch 容忍「列已存在」错误
- 新增无需迁移的字段（pour3-5、beanCost）直接进 `extra` JSON
- 老数据升级后原值保留，不做破坏性重建

### 4. extra 扩展列策略

- 冲煮差异字段（闷蒸 / 注水 1–5 / 压力 / 冷藏时长 / 浸泡 / 压下 / 出品量 / 火候 / beanCost）不占独立列，统一 `BrewRecord.toExtraJson()` 序列化存 `brew_records.extra`
- 读取时 `applyExtraJson()` 反序列化；导出时 `extra` 原样作为 JSON 字符串写入备份，导入时还原——**不丢字段、不需要为新字段改表**

### 5. 订单导入数据流

```
剪贴板路径：
onPageShow / 菜单项
  → ClipboardImport.check()                     (pasteboard → 过滤 → ShareParser → LinkFetcher 补标题)
  → ImportPreviewSheet 预览（category 高亮推荐）
  → pickImport(target) 写 AppStorage['importDraft']
  → router.pushUrl 表单页 → aboutToAppear 消费 → 置空草稿 → 预填 + 顶部提示条

截图路径：
表单页按钮 → OcrImport.pickAndRecognize()
  → PhotoViewPicker 选图 → image.createImageSource → createPixelMap（>1280 缩放）
  → textRecognition.init + recognizeText → OcrParser.parseOrderText
  → applyOcr() 逐字段预填 + Toast「已识别填入 N 项」
```

- 草稿只在**新建模式**（`id <= 0`）下消费；编辑模式忽略
- `OcrParseResult.dateFound` 标记 OCR 是否真的识别到日期，避免覆盖用户已选日期
- 剪贴板 / 网络 / OCR 全链路 try-catch 静默降级，永不阻塞主流程

### 6. 数据备份 / 恢复数据流

```
导出：MineView.exportData → DataBackup.exportToFile
  → CoffeeDb 全量查询 → 组装 JSON → DocumentViewPicker.save → toast

导入：MineView.importData → DataBackup.importFromFile
  → DocumentViewPicker.select → fs.openSync + TextDecoder('utf-8') 读取 → parse
  → confirmImport AlertDialog（X 条豆 / Y 条器具 / Z 条冲煮 + 覆盖警告）
  → CoffeeDb.restoreAll：beginTransaction → 清空三表 → 按原 ID 插入 → commit（异常 rollBack）
  → dataVersion +1 → toast「导入成功」
```

- 导入为**覆盖式**（非合并），避免 ID 冲突；事务保证原子性
- 按原 ID 还原，保留冲煮记录与豆子的 `bean_id` 关联

### 7. 解析规则速查

- **电商域名过滤**：`taobao | tb.cn | tmall | jd.com | pinduoduo | yangkeduo | pdd`
- **平台识别**：文本含「淘宝/tb.cn/taobao」→ 淘宝；「京东/jd.com」→ 京东；「拼多多/yangkeduo/pinduoduo」→ 拼多多
- **价格**：`[¥￥]\s*(数字)`；**URL**：`https?://非空白符`；**标题**：剔除【前缀】/口号/URL/价格后取最长段（>3 字符）
- **OCR 日期**：`yyyy[-/年.]M[-/月.]d` → 当天 12:00 时间戳，置 `dateFound`
- **商家**：优先 `xx旗舰店/专营店/专卖店/自营店` 正则，其次含「店铺/京东自营」短行
- **分类**：`CategoryKeywords.classify()` — BEAN 关键词与 EQUIPMENT 关键词互斥命中判定；均命中或均不中 → `unknown`（预览层不高亮，任选表单）

---

## 四、Kit / API 用法速查

| 能力 | Kit | 关键 API / 用法 |
| --- | --- | --- |
| 关系型数据库 | `@kit.ArkData` | `relationalStore.getRdbStore(context, {name})`、`execute` 建表/ALTER 迁移、`querySql`、`insert/update/delete`、`beginTransaction/commit/rollBack`，异步 Promise |
| 键值设置 | `@kit.ArkData` | `preferences.getPreferencesSync(context, {name:'settings'})`、`getSync/putSync/flush` |
| 剪贴板 | `@kit.BasicServicesKit` | `pasteboard.getSystemPasteboard().getData(): Promise<PasteData>` → `getPrimaryText(): string` |
| HTTP | `@kit.NetworkKit` | `http.createHttp()` → `request(url, {method, connectTimeout, readTimeout, header})` → `finally req.destroy()` |
| 文件保存/选择（备份） | `@kit.CoreFileKit` | **`new picker.DocumentViewPicker(context)`** → `save(DocumentSaveOptions)` / `select(DocumentSelectOptions)` 返回 uri；无需权限 |
| 相册选图 | `@kit.CoreFileKit` | `picker.PhotoViewPicker` + `PhotoSelectOptions`（MIMEType=IMAGE_TYPE, maxSelectNumber=1）→ `select()` 返回 `photoUris`（*已弃用 WARN，见「已知限制」*） |
| 文件读取 | `@kit.CoreFileKit` | `fileIo as fs` → `fs.openSync(uri, fs.OpenMode.READ_ONLY)` 得 `file.fd`，用完 `fs.closeSync(file)`；写：`fs.openSync(uri, READ_WRITE)` + `fs.writeSync(fd, string)` |
| 文本解码 | `@kit.ArkTS` | **`util.TextDecoder.create('utf-8')` + `decodeToString(Uint8Array)`**（API 12+，替代已弃用的 `decodeWithStream`） |
| rawfile 读取 | ArkUI 资源 | **`getRawFileContentSync(context, 'app-info.json')`** 返回 Uint8Array；`getRawFileContent` 在 API 24 会被 linter 解析为 Promise 重载，**必须用 Sync 版本** |
| 图片解码 | `@kit.ImageKit` | `image.createImageSource(file.fd)` → `createPixelMap()` → `getImageInfo()`、`scale(w,h)`、`release()` |
| 端侧 OCR | `@kit.CoreVisionKit` | `textRecognition.init()`（可容错跳过）→ `recognizeText({ pixelMap }: VisionInfo): Promise<TextRecognitionResult>`，结果在 `.value`（全文，`\n` 分行） |
| 弹窗/路由/动效 | ArkUI UIContext | **统一走 `this.getUIContext()`**：`getRouter().pushUrl/back/getParams`、`getPromptAction().showToast`、`showAlertDialog`、`showDatePickerDialog`、`animateTo` |
| 应用信息 | `@kit.AbilityKit` | `bundleManager.getBundleInfoForSelfSync(...)` 备用；本项目以 `rawfile/app-info.json` 为权威源 |

---

## 五、ArkTS 严格模式约定（本项目踩坑沉淀）

新增/修改代码务必遵守，否则编译失败或 UI 不刷新：

1. **禁止正则字面量**，一律 `new RegExp('...')`；字符串内 `\\s` `\\.` 转义
2. **中文引号等特殊字符写进正则字符串时用 `\\u201c` 等 unicode 转义**——曾因智能引号被写成 ASCII 引号导致字符串字面量断裂
3. 禁止解构赋值、禁止 `any/unknown`、禁止 `as` 以外的类型断言乱用
4. 对象字面量必须有类型上下文：显式标注变量/参数类型，或先 `new` 再赋属性（见 MineView `methodOptions` 的 map 写法）
5. async 方法显式 `Promise<T>` 返回类型；catch 无类型注解时用 `(e as BusinessError).code` 取错误码
6. UI 系 API 一律 `this.getUIContext().xxx`，不要用全局 router / promptAction
7. **`@Builder` 按值传参不刷新 UI**：多参数 @Builder 调用点必须改为**单一对象字面量 + `$$` 按引用传递**（如 `inputRow($$: InputRowOptions)`、`groupRow({label, value, danger, onRowTap})`）。官方文档确认仅该模式支持参数变化刷新；曾因此出现「选择后仍显示点击选择」「编辑回填不显示」，共修复 37 处调用点
8. **`@Builder` 内不能有局部变量声明**，复杂逻辑放私有方法
9. **`DatePickerResult.month` 是 0 基索引（0 = 1 月）**：`showDatePickerDialog` 回调中构造日期用 `new Date(y, m, d, 12, 0, 0)`；注意 OCR 文本里的月份是 1 基，仍需 `m - 1`；`DateUtil` 显示时 `+1`。三者语义不同，勿混淆
10. ForEach 同 key 不重建子组件 → 需强制刷新时在 key 中拼接版本号

---

## 六、构建 / 调试备忘

```bash
# 构建（产物 HAP；未配置签名仅影响真机安装）
hvigorw assembleHap          # 或在 DevEco Studio 中 Run

# 静态检查（提交前必跑；对 SDK @arkts.lang.d.ets 的 6 个报错为环境噪音，忽略）
arkts_check entry/src/main/ets/**/*.ets
```

- 增量 CompileArkTS 约 3–5 秒，整包构建约 6–40 秒
- 模拟器验证：`devecocli emulator start "Mate 60 pro"` → `devecocli run --skip-build --device "Mate 60 pro"`
- `hdc` 不在 PATH 时用 `hdc_log` 类工具查日志；崩溃查 `JSCRASH` 前缀

### 发版检查清单

1. 改版本时**同时更新**：根目录 `app-info.json`（versionName/versionCode）+ `entry/src/main/resources/rawfile/app-info.json`（镜像）+ `AppScope/app.json5`
2. `arkts_check` 项目内文件零错误（SDK 噪声除外）
3. `hvigorw assembleHap` BUILD SUCCESSFUL
4. 真机 / 模拟器冒烟：新增记录 → 首页统计 → 导出 → 导入 → 数据完整

---

## 七、已知限制与后续开发建议

1. **OcrParser / ImportDraft 未扩展新字段**：OCR / 剪贴板导入仍只识别 品种 / 名称 / 价格 / 商家 / 日期（不含产地 / 克重 / 烘焙度等新字段），可选后续增强
2. **0.1.0 之前保存的记录日期错位一个月**（DatePicker 0 基月份 bug 已修复，历史数据不会自动纠正）；导入导出与迁移均无损，但旧数据需手动修正或重录
3. **PhotoViewPicker 系列 API 标记 deprecated**（WARN 不阻塞）：较新 API 提供 `selectAssets` 等替代，升级 targetSdkVersion 时可迁移
4. **无全局悬浮球**：HarmonyOS NEXT 悬浮窗需 system_core 级权限，第三方应用不可申请。替代方案即当前剪贴板自动检测
5. **淘宝等站点登录墙**：LinkFetcher 大概率拿不到真实标题，属预期——分享文本本身通常含完整标题
6. **剪贴板读取可能有系统隐私提示**（HarmonyOS NEXT 行为），读取失败会静默跳过
7. **导入为覆盖式**：当前不做合并 / 冲突检测；如需增量同步，可在 `DataBackup.parse` 后按 ID 分流
8. 可选后续方向：冲煮数据统计图表、云同步、豆子弹尽提醒、分享记录卡片、OCR 识别新字段（克重 / 烘焙度 / 产地）
