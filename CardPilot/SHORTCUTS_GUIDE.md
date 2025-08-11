# 📱 CardPilot Shortcuts 集成完整指南

## 🎯 概述

CardPilot 支持通过 iOS Shortcuts 应用进行 NFC 触发和 WiFi SSID 获取，实现自动化的数据收集和 NFC 使用追踪。本指南将详细介绍如何设置 NFC 和 WiFi 相关的快捷指令。

## 🔄 数据收集模式

### 1. **静默模式** (推荐用于 NFC)
- **触发方式**: NFC 标签点击
- **界面**: 极简覆盖层，显示收集进度
- **自动退出**: 是 (3秒后自动关闭)
- **用户体验**: 点击 → 收集 → 关闭 (无缝体验)

### 2. **交互模式**
- **触发方式**: 手动应用启动或特定 URL
- **界面**: 完整应用界面
- **自动退出**: 否 (保持打开状态)
- **用户体验**: 完整应用体验

## 🏗️ NFC 设置指南

### 步骤1：创建 NFC 快捷指令

1. **打开 Shortcuts 应用** 在您的 iPhone 上
2. **点击 "+" 创建新快捷指令**
3. **添加 "Open URLs" 动作** (不是 "Open App")
4. **添加 NFC 触发**:
   - 点击 "Add to Siri"
   - 选择 "NFC"
   - 扫描您的 NFC 标签
   - 命名它 (例如 "CardPilot 数据收集")
5. **保存快捷指令**

### 步骤2：测试 NFC 标签

1. **用您的 iPhone 点击 NFC 标签**
2. **CardPilot 应该**:
   - 启动并显示极简覆盖层
   - 显示 "Collecting Data..." 和进度
   - 短暂显示收集结果
   - 3秒后自动关闭
3. **稍后检查收集的数据** 在 CardPilot 的 Sessions 标签页
4. **查看 NFC 使用历史** 在新的 "NFC使用" 标签页

## 📶 WiFi SSID 设置指南

### 步骤1：创建 WiFi SSID 获取快捷指令

1. 打开 **Shortcuts** 应用
2. 点击 **+** 创建新快捷指令
3. 搜索并添加 **"Get Current WiFi Network"** 动作
4. 添加 **"Get Details of WiFi Network"** 动作
5. 从 WiFi 网络详情中选择 **"SSID"**

### 步骤2：设置 NFC 自动化

1. 在 Shortcuts 中点击 **"Automation"** 标签
2. 点击 **+** 创建新自动化
3. 选择 **"NFC"**
4. 扫描您的 NFC 标签
5. 添加您在步骤1中创建的快捷指令
6. 确保关闭 **"Ask Before Running"**

## 📱 URL Scheme 格式详解

CardPilot 支持以下 URL 格式：

### 基本格式
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&ssid=MyWiFiNetwork&silent=true&nfc=04:32:56:AB
```

### 参数说明

| 参数 | 必需 | 说明 | 示例 |
|------|------|------|------|
| `sourceApp` | 否 | 触发源应用名称 | `Shortcuts` |
| `autoExit` | 否 | 自动退出模式 | `true`/`false` |
| `ssid` | 否 | WiFi 网络 SSID | `MyHomeWiFi` |
| `nfc` | 否 | NFC 卡片 UID 或其他输入数据 | `04:32:56:AB` |
| `silent` | 否 | 静默模式 - 极简界面，自动数据收集 | `true`/`false` |

### 示例 URL

```bash
# 基本 NFC 数据收集（显示界面）
cardpilot://collect?sourceApp=Shortcuts&autoExit=true

# 带 WiFi SSID 的数据收集（静默模式，推荐）
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&ssid=HomeWiFi&silent=true

# 真实 NFC 触发（包含卡片 UID）
cardpilot://collect?sourceApp=NFC&autoExit=true&ssid=OfficeWiFi&nfc=04:32:56:AB&silent=true

# 手动触发（不自动退出，显示界面）
cardpilot://collect?sourceApp=Shortcuts&autoExit=false&ssid=OfficeWiFi
```

## 🏷️ NFC 参数详解

### NFC 卡片 UID 传递

`nfc` 参数专门用于传递 NFC 相关的数据，主要用途：

- **🔍 真实 NFC 触发**: 当使用真实 NFC 卡片触发时，传递卡片的 UID
- **📝 Shortcuts 模拟**: 当使用 Shortcuts 模拟触发时，可以为空或传递自定义标识
- **🆔 唯一标识**: 帮助区分不同的 NFC 卡片或触发源

### 使用场景对比

| 触发方式 | sourceApp | nfc | 使用场景 |
|----------|-----------|-----|----------|
| 真实 NFC 卡片 | `NFC` | `04:32:56:AB` | 物理 NFC 卡片触发，记录实际 UID |
| Shortcuts 模拟 | `Shortcuts` | 空或自定义 | 快捷指令模拟 NFC，无真实 UID |
| 手动测试 | `Manual` | `TestCard_001` | 手动测试，使用测试标识 |

### NFC 数据格式

```bash
# NFC UID 格式（推荐）
nfc=04:32:56:AB

# 自定义标识格式
nfc=HomeCard
nfc=OfficeAccess_001
nfc=PaymentCard_Visa

# 空值（Shortcuts 模拟时）
# 不包含 nfc 参数，或者为空
```

## ✨ 静默模式详解

### 静默模式优势

静默模式 (`silent=true`) 提供了近乎无界面的数据收集体验：

- **🎯 极简界面**: 只显示淡色背景和小型进度指示器
- **⚡ 即时执行**: 绕过普通收集界面，立即开始数据收集  
- **🔄 自动完成**: 数据收集完成后自动重置状态
- **📳 触觉反馈**: 完成时提供震动提示确认
- **🏠 自动最小化**: 完成后直接最小化应用，不跳转到其他应用
- **⏱️ 快速体验**: 整个过程仅需 2-3 秒

### 普通模式 vs 静默模式

| 特性 | 普通模式 | 静默模式 |
|------|----------|----------|
| 界面显示 | 完整收集界面 | 极简进度界面 |
| 用户交互 | 需要点击完成 | 完全自动化 |
| 视觉反馈 | 详细状态显示 | 最小视觉提示 |
| 完成方式 | 手动关闭 | 自动最小化到后台 |
| 适用场景 | 调试、详细查看 | 日常快速收集 |

## 📊 自动 NFC 使用记录

### 自动记录的内容：
- ⏰ **精确时间戳** 每次 NFC 使用的时间
- 📍 **GPS 位置** NFC 使用的地点
- 🏷️ **使用类型** (支付、交通、门禁等)
- 📱 **触发源** (哪个快捷指令/应用触发的)
- 📊 **使用统计** 和频率分析

### 智能类型检测：
CardPilot 自动检测 NFC 使用类型，基于：
- URL 参数 (例如 `cardpilot://collect?type=payment`)
- 触发应用中的上下文关键词
- 常见用例的默认假设

### 隐私与控制：
- 所有数据都保存在您的设备上
- 在 "NFC使用" 标签页中查看所有记录
- 删除个别记录或清除所有数据
- 导出使用统计进行分析

## 🔧 高级设置

### 自定义 WiFi 检测快捷指令

如果基本的 WiFi 获取不工作，您可以尝试这个更全面的快捷指令：

1. **Get Current WiFi Network**
2. **Get Details of WiFi Network** → 选择 "SSID"
3. **If** (SSID contains text)
   - **Then**: 使用获取的 SSID
   - **Otherwise**: 使用默认值 "Unknown_WiFi"
4. **Format URL** with SSID
5. **Open URLs**

### 错误处理

如果 WiFi SSID 获取失败，快捷指令会：
1. 自动使用 "Unknown_WiFi" 作为默认值
2. 仍然触发 CardPilot 数据收集
3. CardPilot 会回退到网络连接状态检测

## 📋 高级快捷指令设置

### 选项 A：简单 NFC 自动化
```
动作 1: Open URLs
URL: cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true
触发: NFC
```

### 选项 B：增强 NFC 带通知
```
动作 1: Open URLs
URL: cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true

动作 2: Wait (4 秒)

动作 3: Show Notification
标题: "数据已收集"
内容: "CardPilot 已收集您的传感器数据"
```

### 选项 C：条件收集
```
动作 1: Ask for Input (Choose from Menu)
选项: "快速收集", "完整应用", "取消"

动作 2: If (快速收集)
  → Open URLs: cardpilot://collect?autoExit=true&silent=true

动作 3: If (完整应用)
  → Open App: CardPilot

动作 4: If (取消)
  → Stop Shortcut
```

## 🎨 您将看到什么

### 静默收集流程：
1. **NFC 点击** → 快捷指令触发
2. **CardPilot 启动** 带深色覆盖层
3. **收集进度** 显示：
   - 动画 NFC 图标
   - "Collecting Data..." 文本
   - 进度指示器
   - 实时状态更新
4. **结果摘要** 显示：
   - ✓ 位置已收集
   - ✓ 网络数据
   - ✓ 运动传感器
5. **自动关闭倒计时** (3 秒)
6. **应用自动关闭**

### 收集界面特性：
- **极简设计**: 深色覆盖层，不会干扰其他应用
- **进度反馈**: 数据收集的实时状态
- **结果摘要**: 快速查看收集了什么数据
- **触觉反馈**: 成功/完成时的触觉确认
- **错误显示**: 显示任何传感器收集数据失败的情况

## 📊 数据显示

在 CardPilot 中，WiFi 信息会显示为：

- **有外部 SSID 时**: `"MyHomeWiFi"` (真实网络名称)
- **无外部 SSID 时**: `"WiFi_Network_Active"` (连接状态)
- **模拟器中**: `"Simulator_WiFi_Network"`

## 🎯 最佳实践

### 对于 NFC 标签：
- **标记您的标签** (例如 "汽车", "办公室", "家")
- **定期测试** 确保它们工作正常
- **使用优质标签** 获得更好的可靠性

### 对于快捷指令：
- **保持 URL 简单** - 避免复杂参数
- **部署前测试** 在实际 NFC 标签上
- **使用描述性名称** 为您的快捷指令

### 对于数据收集：
- **授予所有权限** 获得最佳结果
- **确保良好信号** (GPS、蜂窝/WiFi)
- **收集期间保持静止** (获得更好的 IMU 数据)

## 🐛 故障排除

### NFC 标签不工作？
1. **检查 URL**: 确保它完全是 `cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true`
2. **测试快捷指令**: 先手动运行快捷指令
3. **NFC 设置**: 确保在设置 → 控制中心中启用了 NFC
4. **标签质量**: 尝试不同的 NFC 标签

### 应用不自动关闭？
1. **检查 URL 参数**: 必须包含 `autoExit=true`
2. **等待完成**: 自动关闭发生在收集完成后
3. **手动关闭**: 如果需要，点击 "Close"

### 收集失败？
1. **权限**: 在设置中授予位置和运动访问权限
2. **网络**: 确保设备有互联网用于 IP 检测
3. **重试**: 某些传感器可能需要片刻来初始化

### WiFi SSID 不显示
1. 检查 Shortcuts 是否有网络权限
2. 确认 URL 中的 SSID 参数格式正确
3. 重启 CardPilot 应用

### URL Scheme 不工作
1. 确认 CardPilot 已安装并注册 URL scheme
2. 测试基本 URL: `cardpilot://collect`
3. 检查 Bundle ID 是否匹配

### 自动化不触发
1. 确认 NFC 标签已正确扫描
2. 检查自动化设置中的 "运行前询问" 选项
3. 重新创建 NFC 自动化

## 📝 示例快捷指令

### 完整的 NFC + WiFi 数据收集快捷指令（静默模式）

```
1. Get Current WiFi Network
2. Get Details of WiFi Network → SSID
3. Text Action → "cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true&ssid=&nfc="
4. Combine Text → [步骤 3] + [来自步骤 2 的 SSID]
5. Open URLs → [来自步骤 4 的组合 URL]
```

## 🔄 从旧设置迁移

如果您有之前的 CardPilot 快捷指令：

1. **打开现有快捷指令**
2. **替换 "Open App" 动作** 为 "Open URLs"
3. **设置 URL 为**: `cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true`
4. **用您的 NFC 标签测试**

这提供了更好的用户体验，具有无缝的背景收集！

## 🆕 静默模式的优势

使用 `silent=true` 参数具有以下优势：

- **完全无界面**: 应用在后台收集数据，不显示任何界面
- **更快速度**: 无需渲染 UI，数据收集更快完成
- **无缝体验**: 用户感觉像是直接扫描 NFC 标签，没有应用切换感
- **自动最小化**: 数据收集完成后自动将应用最小化到后台
- **触觉反馈**: 完成时提供触觉反馈，让用户知道操作成功

这个设置将确保每次扫描 NFC 标签时，CardPilot 都能静默收到真实的 WiFi SSID 信息！
