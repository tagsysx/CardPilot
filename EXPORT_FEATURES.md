# CardPilot 数据导出功能使用指南

## 概述

CardPilot 应用提供了强大的数据导出功能，支持多种格式和过滤选项，让您能够灵活地导出收集到的NFC会话数据。导出功能支持CSV和JSON格式，并提供隐私保护选项。

## 支持的导出格式

### 1. CSV格式
- **标准CSV**: 包含所有数据，包括位置信息
- **隐私保护CSV**: 不包含位置信息，保护用户隐私

### 2. JSON格式
- **标准JSON**: 包含完整的数据结构和元数据
- **隐私保护JSON**: 不包含位置信息，适合数据共享

## 导出数据类型

### 基础数据
- **时间戳**: 会话触发时间
- **IP地址**: 设备当前IP地址
- **应用名称**: 触发应用名称

### NFC相关数据
- **NFC标签数据**: 扫描到的NFC标签内容
- **NFC使用类型**: NFC的使用方式
- **NFC触发源**: NFC触发的来源
- **NFC会话时长**: 整个NFC会话的持续时间

### 屏幕状态数据
- **屏幕状态**: 当前屏幕状态
- **屏幕亮度**: 屏幕亮度值
- **屏幕状态历史**: 屏幕状态变化记录

### 传感器数据
- **IMU数据**: 加速度计、陀螺仪、磁力计数据
- **磁力计数据**: 磁场强度信息
- **气压计数据**: 大气压力数据
- **环境光传感器**: 环境光照强度
- **距离传感器**: 物体距离信息
- **计步器数据**: 步数统计
- **温度传感器**: 设备温度
- **麦克风数据**: 环境音频记录
- **天气数据**: 当前位置天气信息

### 位置数据（可选）
- **GPS坐标**: 纬度和经度
- **详细地址**: 街道、城市、州、国家、邮政编码等
- **行政区域**: 行政区划信息

## 导出功能特性

### 1. 数据质量评分
系统会自动计算每个会话的数据质量评分（0.0-1.0），基于可用传感器数据的完整性。

### 2. 智能数据过滤
- **全部数据**: 导出所有可用数据
- **NFC数据**: 仅导出包含NFC信息的会话
- **位置数据**: 仅导出包含位置信息的会话
- **传感器数据**: 仅导出包含传感器数据的会话
- **屏幕状态数据**: 仅导出包含屏幕状态历史的会话

### 3. 时间范围导出
- **自定义时间范围**: 指定开始和结束时间
- **最近N天**: 快速导出最近几天的数据

### 4. 传感器数据统计报告
自动生成详细的传感器数据收集统计报告，包括：
- 各传感器数据可用性统计
- 数据收集时间范围
- 数据质量分析
- IMU数据点统计

## 使用方法

### 1. 基本导出操作

#### 导出所有数据
```swift
let exportManager = DataExportManager()
if let fileURL = exportManager.exportData(sessions, format: .csv) {
    // 导出成功，文件保存在 fileURL
}
```

#### 导出隐私保护版本
```swift
// 不包含位置信息的CSV导出
if let fileURL = exportManager.exportData(sessions, format: .csvPrivacy) {
    // 导出成功
}
```

### 2. 按时间范围导出

```swift
let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
let endDate = Date()

if let fileURL = exportManager.exportDataInTimeRange(
    sessions, 
    from: startDate, 
    to: endDate, 
    format: .json
) {
    // 导出最近7天的数据
}
```

### 3. 导出最近N天的数据

```swift
// 导出最近30天的数据
if let fileURL = exportManager.exportRecentData(sessions, days: 30, format: .csv) {
    // 导出成功
}
```

### 4. 按数据类型过滤导出

```swift
// 仅导出包含NFC数据的会话
if let fileURL = exportManager.exportDataByType(
    sessions, 
    dataType: .nfcData, 
    format: .json
) {
    // 导出成功
}
```

### 5. 生成传感器数据统计报告

```swift
// 生成统计报告
let report = exportManager.generateSensorDataReport(from: sessions)

// 导出统计报告为CSV
if let reportURL = exportManager.exportSensorDataReportCSV(from: sessions) {
    // 报告导出成功
}
```

## 导出文件命名规则

### 标准导出文件
- **格式**: `CardPilot_Export_YYYY-MM-DD_HH-mm-ss.{csv|json}`
- **示例**: `CardPilot_Export_2025-01-15_14-30-25.csv`

### 时间范围导出文件
- **格式**: `CardPilot_Export_YYYY-MM-DD_HH-mm-ss_to_YYYY-MM-DD_HH-mm-ss.{csv|json}`
- **示例**: `CardPilot_Export_2025-01-08_00-00-00_to_2025-01-15_23-59-59.csv`

### 最近N天导出文件
- **格式**: `CardPilot_Recent{N}Days_YYYY-MM-DD_HH-mm-ss.{csv|json}`
- **示例**: `CardPilot_Recent7Days_2025-01-15_14-30-25.csv`

### 数据类型过滤导出文件
- **格式**: `CardPilot_{DataType}_YYYY-MM-DD_HH-mm-ss.{csv|json}`
- **示例**: `CardPilot_NFC Data_2025-01-15_14-30-25.json`

### 传感器统计报告文件
- **格式**: `CardPilot_SensorReport_YYYY-MM-DD_HH-mm-ss.csv`
- **示例**: `CardPilot_SensorReport_2025-01-15_14-30-25.csv`

## 文件存储位置

所有导出的文件都保存在应用的Documents目录中，可以通过以下方式访问：

```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
```

## 数据质量评估

### 数据质量评分计算
系统基于以下因素计算数据质量评分：

1. **IMU数据可用性** (10%)
2. **磁力计数据可用性** (10%)
3. **气压计数据可用性** (10%)
4. **环境光传感器可用性** (10%)
5. **距离传感器可用性** (10%)
6. **计步器数据可用性** (10%)
7. **温度传感器可用性** (10%)
8. **麦克风数据可用性** (10%)
9. **天气数据可用性** (10%)
10. **屏幕状态历史可用性** (10%)

### 评分等级
- **0.9-1.0**: 优秀 - 几乎所有传感器数据都可用
- **0.7-0.8**: 良好 - 大部分传感器数据可用
- **0.5-0.6**: 一般 - 约一半传感器数据可用
- **0.3-0.4**: 较差 - 少数传感器数据可用
- **0.0-0.2**: 很差 - 几乎没有传感器数据

## 隐私保护选项

### 位置数据隐私
- 选择隐私保护格式时，所有位置相关数据将被排除
- 包括GPS坐标、地址信息、天气数据等
- 适合数据共享和学术研究

### 数据脱敏
- 自动处理敏感信息
- 支持自定义数据过滤规则
- 确保符合隐私法规要求

## 性能优化建议

### 大数据量导出
- 对于大量数据，建议分批导出
- 使用后台线程进行导出操作
- 考虑数据压缩选项

### 内存管理
- 导出过程中注意内存使用
- 对于超大数据集，考虑流式处理
- 及时释放不需要的数据对象

## 错误处理

### 常见错误类型
1. **文件写入失败**: 检查存储空间和权限
2. **数据编码错误**: 验证数据完整性
3. **内存不足**: 减少导出数据量
4. **权限问题**: 确认应用权限设置

### 错误处理示例
```swift
do {
    let fileURL = try exportManager.exportData(sessions, format: .csv)
    // 处理成功情况
} catch {
    print("导出失败: \(error)")
    // 处理错误情况
}
```

## 使用场景示例

### 1. 学术研究
- 导出隐私保护格式的数据
- 生成传感器数据统计报告
- 分析数据收集质量

### 2. 数据分析
- 导出JSON格式进行程序化处理
- 按时间范围分析趋势
- 评估传感器数据完整性

### 3. 数据备份
- 定期导出重要数据
- 创建数据快照
- 迁移数据到其他系统

### 4. 故障诊断
- 导出特定时间段的数据
- 分析传感器数据异常
- 排查系统问题

## 技术支持

如果在使用导出功能时遇到问题，请：

1. 检查应用权限设置
2. 确认设备存储空间充足
3. 查看控制台错误日志
4. 尝试重新启动应用
5. 联系技术支持团队

## 更新日志

### v1.0
- 支持CSV和JSON格式导出
- 实现隐私保护选项
- 添加数据质量评分
- 支持时间范围过滤
- 生成传感器数据统计报告

---

*本文档描述了CardPilot应用的完整导出功能。如需更多技术细节，请参考源代码和API文档。*
