# 咖啡志 — 开发记录与维护指南

> 本文档记录项目已实现的功能、使用的系统 Kit / API、关键机制与约定，供后续维护与继续开发参考。
> 项目简介见 [README.md](./README.md)。

- 版本：1.0.0（versionCode 1000000）
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

---

## 二、文件地图

```
entry/src/main/ets/
├── common/
│   ├── Theme.ets           # ThemeColors（主题色预设）、AppKeys（AppStorage key 注册表）
│   └── DateUtil.ets        # formatDate 等
├── model/
│   ├── Models.ets          # CoffeeBean / Equipment / BrewRecord / BrewMethod / GrindSize / EquipmentType
│   ├── RouteParams.ets     # FormParams { id }
│   └── ImportDraft.ets     # ImportDraft / ShareParseResult / OcrParseResult / CategoryKeywords
├── data/
│   ├── CoffeeDb.ets        # RelationalStore 单例：三表建表 + CRUD + clearAll
│   └── SettingsStore.ets   # Preferences 单例：主题色 / 默认冲煮方式 / autoClipboard
├── service/                # ===== 订单导入解析与编排（阶段 2）=====
│   ├── ShareParser.ets     # 分享文本解析：平台识别 / URL / 价格 / 标题 / 电商域名过滤
│   ├── OcrParser.ets       # OCR 全文 → 结构化字段（价格/日期/商家/标题/品牌/型号/类型）
│   ├── LinkFetcher.ets     # best-effort 网页 <title> 抓取（5s 超时，失败返回 ''）
│   ├── OcrImport.ets       # 选图 → 解码 → 缩放 → OCR → 解析，三态结果（ok/empty/failed/cancelled）
│   └── ClipboardImport.ets # 剪贴板读取 → 过滤去重 → 解析 → 组装 ImportDraft
├── components/
│   ├── BeanCard.ets / EquipmentCard.ets / BrewCard.ets
│   ├── OptionSheet.ets           # 通用底部磨砂选项弹层（OptionItem）
│   └── ImportPreviewSheet.ets    # 导入预览弹层（商品/价格/来源 + 双目标按钮）
├── pages/
│   ├── Index.ets           # @Entry 主页：Tabs + Dock + 加号菜单 + 导入弹层 + onPageShow 检测
│   ├── LibraryView.ets     # 库藏 Tab
│   ├── BrewLogView.ets     # 冲煮 Tab
│   ├── MineView.ets        # 我的 Tab（设置项）
│   ├── BeanFormPage.ets    # 咖啡豆表单（草稿消费 + 截图导入）
│   ├── EquipmentFormPage.ets # 器具表单（草稿消费 + 截图导入）
│   └── BrewFormPage.ets    # 冲煮记录表单
└── entryability/EntryAbility.ets
```

---

## 三、关键机制

### 1. AppStorage Key 注册表（common/Theme.ets `AppKeys`）

| Key | 用途 | 读 / 写方 |
| --- | --- | --- |
| `themeColor` | 当前主题色 | 全组件 `@StorageProp`；MineView 写 |
| `dataVersion` | 列表数据版本号 | 保存/删除后 `+1`；列表页 `@StorageLink + @Watch` 刷新 |
| `defaultBrewMethod` | 默认冲煮方式 | MineView 写，BrewFormPage 读 |
| `importDraft` | 待预填的订单草稿（ImportDraft 实例） | Index 写，表单页 `aboutToAppear` 消费后**立即置空** |
| `autoClipboard` | 剪贴板自动检测开关（仅 Preferences，不常驻 AppStorage） | MineView Toggle 写 |
| `lastImportedText` | 上次已处理的剪贴板文本（防重复） | ClipboardImport 读写 |

### 2. 数据刷新（dataVersion 机制）

- 任何写库操作成功后 `AppStorage.setOrCreate('dataVersion', +1)`
- 列表页用 `@StorageLink('dataVersion') dataVersion + @Watch('onVersion')` 触发重新查询
- `ForEach` 的 key 生成函数带 `_v${dataVersion}` 后缀，强制子组件重建（规避同 key 复用不刷新）

### 3. 订单导入数据流

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

### 4. 解析规则速查

- **电商域名过滤**：`taobao | tb.cn | tmall | jd.com | pinduoduo | yangkeduo | pdd`
- **平台识别**：文本含「淘宝/tb.cn/taobao」→ 淘宝；「京东/jd.com」→ 京东；「拼多多/yangkeduo/pinduoduo」→ 拼多多
- **价格**：`[¥￥]\s*(数字)`；**URL**：`https?://非空白符`；**标题**：剔除【前缀】/口号/URL/价格后取最长段（>3 字符）
- **OCR 日期**：`yyyy[-/年.]M[-/月.]d` → 当天 12:00 时间戳，置 `dateFound`
- **商家**：优先 `xx旗舰店/专营店/专卖店/自营店` 正则，其次含「店铺/京东自营」短行
- **分类**：`CategoryKeywords.classify()` — BEAN 关键词（咖啡豆/耶加/瑰夏/云南/日晒…）与 EQUIPMENT 关键词（壶/磨豆机/滤杯/手冲…）互斥命中判定；均命中或均不中 → `unknown`（预览层不高亮，任选表单）

---

## 四、Kit / API 用法速查

| 能力 | Kit | 关键 API / 用法 |
| --- | --- | --- |
| 关系型数据库 | `@kit.ArkData` | `relationalStore.getRdbStore(context, {name})`、`execute` 建表、`querySql`、`insert/update/delete`，异步 Promise |
| 键值设置 | `@kit.ArkData` | `preferences.getPreferencesSync(context, {name:'settings'})`、`getSync/putSync/flush` |
| 剪贴板 | `@kit.BasicServicesKit` | `pasteboard.getSystemPasteboard().getData(): Promise<PasteData>` → `getPrimaryText(): string` |
| HTTP | `@kit.NetworkKit` | `http.createHttp()` → `request(url, {method, connectTimeout, readTimeout, header})` → `finally req.destroy()` |
| 相册选图 | `@kit.CoreFileKit` | `picker.PhotoViewPicker` + `PhotoSelectOptions`（MIMEType=IMAGE_TYPE, maxSelectNumber=1）→ `select()` 返回 `photoUris`（*API 18+ 有新选择器，见「已知限制」*） |
| 文件读取 | `@kit.CoreFileKit` | `fileIo as fs` → `fs.openSync(uri, fs.OpenMode.READ_ONLY)` 得 `file.fd`，用完 `fs.closeSync(file)` |
| 图片解码 | `@kit.ImageKit` | `image.createImageSource(file.fd)` → `createPixelMap()` → `getImageInfo()`、`scale(w,h)`、`release()` |
| 端侧 OCR | `@kit.CoreVisionKit` | `textRecognition.init()`（可容错跳过）→ `recognizeText({ pixelMap }: VisionInfo): Promise<TextRecognitionResult>`，结果在 `.value`（全文，`\n` 分行） |
| 弹窗/路由/动效 | ArkUI UIContext | **统一走 `this.getUIContext()`**：`getRouter().pushUrl/back/getParams`、`getPromptAction().showToast`、`showAlertDialog`、`showDatePickerDialog`、`animateTo` |
| 应用信息 | `@kit.AbilityKit` | `bundleManager.getBundleInfoForSelfSync(BundleFlag.GET_BUNDLE_INFO_DEFAULT).versionName` |

---

## 五、ArkTS 严格模式约定（本项目踩坑沉淀）

新增/修改代码务必遵守，否则编译失败：

1. **禁止正则字面量**，一律 `new RegExp('...')`；字符串内 `\\s` `\\.` 转义
2. **中文引号等特殊字符写进正则字符串时用 `\\u201c` 等 unicode 转义**——曾因智能引号被写成 ASCII 引号导致字符串字面量断裂（ShareParser 第 45 行事故）
3. 禁止解构赋值、禁止 `$$` 双向绑定、禁止 `any/unknown`、禁止 `as` 以外的类型断言乱用
4. 对象字面量必须有类型上下文：显式标注变量/参数类型，或先 `new` 再赋属性（见 MineView `methodOptions` 的 map 写法）
5. async 方法显式 `Promise<T>` 返回类型；catch 无类型注解时用 `(e as BusinessError).code` 取错误码
6. UI 系 API 一律 `this.getUIContext().xxx`（getRouter / getPromptAction / animateTo / showAlertDialog / showDatePickerDialog），不要用全局 router / promptAction
7. `@Builder` 内不能有局部变量声明，参数不要带 `$` 前缀
8. ForEach 同 key 不重建子组件 → 需强制刷新时在 key 中拼接版本号

---

## 六、构建 / 调试备忘

```bash
# 构建（产物 HAP；未配置签名仅影响真机安装）
hvigorw assembleHap          # 或在 DevEco Studio 中 Run

# 静态检查（提交前必跑；对 SDK @arkts.lang.d.ets 的 6 个报错为环境噪音，忽略）
arkts_check entry/src/main/ets/**/*.ets
```

- 模拟器验证：`devecocli emulator start "Mate 60 pro"` → `devecocli run --skip-build --device "Mate 60 pro"`
- `hdc` 不在 PATH 时用 `hdc_log` 类工具查日志；崩溃查 `JSCRASH` 前缀
- debug 构建约 1 分钟；增量 CompileArkTS 约 25 秒

---

## 七、已知限制与后续开发建议

1. **无全局悬浮球**：HarmonyOS NEXT 悬浮窗需 `SYSTEM_FLOAT_WINDOW`（system_core 级），第三方应用不可申请，SDK 无 `ohos.permission.FLOAT_WINDOW`。替代方案即当前剪贴板自动检测。
2. **PhotoViewPicker 系列 API 标记 deprecated**（WARN 不阻塞）：较新 API 提供 `selectAssets` 等替代，升级 targetSdkVersion 时可迁移。
3. **淘宝等站点登录墙**：LinkFetcher 大概率拿不到真实标题，属预期——分享文本本身通常含完整标题，网页抓取只是 best-effort 补充。
4. **剪贴板读取可能有系统隐私提示**（HarmonyOS NEXT 行为），读取失败会静默跳过，不影响使用。
5. **CategoryKeywords.BEAN 含宽泛词「云南」**，理论上可能误分类，但预览层允许任选表单，可接受；如需收紧可移除该词。
6. **OCR 结果 `p.type` 兜底值可能是长标题**：表单页仅接受 ≤12 字符的类型，长文本降级写入备注（`识别参考：xxx`）。
7. 可选后续方向：冲煮数据统计图表、云同步、豆子弹尽提醒、深色模式适配、分享记录卡片。
