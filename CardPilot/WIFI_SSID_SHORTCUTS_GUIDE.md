# 📶 WiFi SSID Shortcuts 集成指南

## 概述

由于iOS 14+的隐私限制，应用很难直接获取真实的WiFi SSID。但是，Shortcuts应用有更高的权限，可以获取WiFi信息并通过URL scheme传递给CardPilot。

## 🚀 设置方法

### 步骤1：创建WiFi SSID获取快捷指令

1. 打开 **Shortcuts** 应用
2. 点击 **+** 创建新快捷指令
3. 搜索并添加 **"Get Current WiFi Network"** 动作
4. 添加 **"Get Details of WiFi Network"** 动作
5. 从WiFi网络详情中选择 **"SSID"**

### 步骤2：添加URL调用

1. 添加 **"Open URLs"** 动作
2. 在URL字段中输入：
   ```
   cardpilot://collect?sourceApp=Shortcuts&autoExit=true&ssid=[SSID]
   ```
3. 点击 **[SSID]** 并选择来自上一步的SSID变量

### 步骤3：设置NFC自动化

1. 在Shortcuts中点击 **"Automation"** 标签
2. 点击 **+** 创建新自动化
3. 选择 **"NFC"**
4. 扫描您的NFC标签
5. 添加您在步骤1-2中创建的快捷指令
6. 确保关闭 **"Ask Before Running"**

## 📱 URL Scheme格式

CardPilot支持以下URL格式：

### 基本格式
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&ssid=MyWiFiNetwork&silent=true
```

### 参数说明

| 参数 | 必需 | 说明 | 示例 |
|------|------|------|------|
| `sourceApp` | 否 | 触发源应用名称 | `Shortcuts` |
| `autoExit` | 否 | 自动退出模式 | `true`/`false` |
| `ssid` | 否 | WiFi网络SSID | `MyHomeWiFi` |
| `nfc` | 否 | **NFC卡片UID或其他输入数据** | `04:32:56:AB` |
| `silent` | 否 | **静默模式** - 极简界面，自动数据收集 | `true`/`false` |

### 示例URL

```bash
# 基本NFC数据收集（显示界面）
cardpilot://collect?sourceApp=Shortcuts&autoExit=true

# 带WiFi SSID的数据收集（显示界面）
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&ssid=HomeWiFi

# 静默模式 - 不显示任何界面（推荐）
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&ssid=HomeWiFi&silent=true

# 真实NFC触发（包含卡片UID）
cardpilot://collect?sourceApp=NFC&autoExit=true&ssid=OfficeWiFi&nfc=04:32:56:AB&silent=true

# 手动触发（不自动退出，显示界面）
cardpilot://collect?sourceApp=Shortcuts&autoExit=false&ssid=OfficeWiFi
```

## 🏷️ nfc参数详解

### NFC卡片UID传递

`nfc`参数专门用于传递NFC相关的数据，主要用途：

- **🔍 真实NFC触发**：当使用真实NFC卡片触发时，传递卡片的UID
- **📝 Shortcuts模拟**：当使用Shortcuts模拟触发时，可以为空或传递自定义标识
- **🆔 唯一标识**：帮助区分不同的NFC卡片或触发源

### 使用场景对比

| 触发方式 | sourceApp | nfc | 使用场景 |
|----------|-----------|---------------|----------|
| 真实NFC卡片 | `NFC` | `04:32:56:AB` | 物理NFC卡片触发，记录实际UID |
| Shortcuts模拟 | `Shortcuts` | 空或自定义 | 快捷指令模拟NFC，无真实UID |
| 手动测试 | `Manual` | `TestCard_001` | 手动测试，使用测试标识 |

### nfc数据格式

```bash
# NFC UID格式（推荐）
nfc=04:32:56:AB

# 自定义标识格式
nfc=HomeCard
nfc=OfficeAccess_001
nfc=PaymentCard_Visa

# 空值（Shortcuts模拟时）
# 不包含nfc参数，或者为空
```

## ✨ 静默模式详解

### 静默模式优势

静默模式 (`silent=true`) 提供了近乎无界面的数据收集体验：

- **🎯 极简界面**: 只显示淡色背景和小型进度指示器
- **⚡ 即时执行**: 绕过普通收集界面，立即开始数据收集  
- **🔄 自动完成**: 数据收集完成后自动重置状态
- **📳 触觉反馈**: 完成时提供震动提示确认
- **🏠 自动最小化**: 完成后直接最小化应用，不跳转到其他应用
- **⏱️ 快速体验**: 整个过程仅需2-3秒

### 普通模式 vs 静默模式

| 特性 | 普通模式 | 静默模式 |
|------|----------|----------|
| 界面显示 | 完整收集界面 | 极简进度界面 |
| 用户交互 | 需要点击完成 | 完全自动化 |
| 视觉反馈 | 详细状态显示 | 最小视觉提示 |
| 完成方式 | 手动关闭 | 自动最小化到后台 |
| 适用场景 | 调试、详细查看 | 日常快速收集 |

## 🔧 高级设置

### 自定义WiFi检测快捷指令

如果基本的WiFi获取不工作，您可以尝试这个更全面的快捷指令：

1. **Get Current WiFi Network**
2. **Get Details of WiFi Network** → 选择 "SSID"
3. **If** (SSID contains text)
   - **Then**: 使用获取的SSID
   - **Otherwise**: 使用默认值 "Unknown_WiFi"
4. **Format URL** with SSID
5. **Open URLs**

### 错误处理

如果WiFi SSID获取失败，快捷指令会：
1. 自动使用 "Unknown_WiFi" 作为默认值
2. 仍然触发CardPilot数据收集
3. CardPilot会回退到网络连接状态检测

## 📊 数据显示

在CardPilot中，WiFi信息会显示为：

- **有外部SSID时**: `"MyHomeWiFi"` (真实网络名称)
- **无外部SSID时**: `"WiFi_Network_Active"` (连接状态)
- **模拟器中**: `"Simulator_WiFi_Network"`

## 🎯 最佳实践

1. **命名快捷指令**: 使用描述性名称如 "NFC + WiFi Collector"
2. **测试设置**: 先在Safari中测试URL scheme
3. **权限确认**: 确保Shortcuts有WiFi网络访问权限
4. **自动化设置**: 关闭"运行前询问"以实现无缝体验

## 🐛 故障排除

### WiFi SSID不显示
1. 检查Shortcuts是否有网络权限
2. 确认URL中的SSID参数格式正确
3. 重启CardPilot应用

### URL Scheme不工作
1. 确认CardPilot已安装并注册URL scheme
2. 测试基本URL: `cardpilot://collect`
3. 检查Bundle ID是否匹配

### 自动化不触发
1. 确认NFC标签已正确扫描
2. 检查自动化设置中的"运行前询问"选项
3. 重新创建NFC自动化

## 📝 示例快捷指令

### 完整的NFC + WiFi数据收集快捷指令（静默模式）

```
1. Get Current WiFi Network
2. Get Details of WiFi Network → SSID
3. Text Action → "cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true&ssid=&nfc="
4. Combine Text → [Step 3] + [SSID from Step 2]
5. Open URLs → [Combined URL from Step 4]
```

## 🆕 静默模式的优势

使用 `silent=true` 参数具有以下优势：

- **完全无界面**：应用在后台收集数据，不显示任何界面
- **更快速度**：无需渲染UI，数据收集更快完成
- **无缝体验**：用户感觉像是直接扫描NFC标签，没有应用切换感
- **自动最小化**：数据收集完成后自动将应用最小化到后台
- **触觉反馈**：完成时提供触觉反馈，让用户知道操作成功

这个设置将确保每次扫描NFC标签时，CardPilot都能静默收到真实的WiFi SSID信息！
