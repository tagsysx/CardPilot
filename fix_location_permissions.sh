#!/bin/bash

# CardPilot 位置权限修复脚本
# 用于诊断和修复iOS真机GPS定位问题

echo "🔍 CardPilot 位置权限诊断工具"
echo "=================================="

# 检查Xcode项目配置
echo ""
echo "📱 检查Xcode项目配置..."

# 检查Info.plist中的位置权限配置
if grep -q "NSLocationWhenInUseUsageDescription" CardPilot/Info.plist; then
    echo "✅ NSLocationWhenInUseUsageDescription 已配置"
else
    echo "❌ NSLocationWhenInUseUsageDescription 缺失"
fi

if grep -q "NSLocationAlwaysAndWhenInUseUsageDescription" CardPilot/Info.plist; then
    echo "✅ NSLocationAlwaysAndWhenInUseUsageDescription 已配置"
else
    echo "❌ NSLocationAlwaysAndWhenInUseUsageDescription 缺失"
fi

# 检查Capabilities配置
echo ""
echo "🔧 检查项目Capabilities..."

if [ -f "CardPilot.xcodeproj/project.pbxproj" ]; then
    if grep -q "com.apple.developer.location-services" CardPilot.xcodeproj/project.pbxproj; then
        echo "✅ Location Services capability 已启用"
    else
        echo "⚠️  Location Services capability 未找到，建议在Xcode中启用"
    fi
else
    echo "❌ 无法找到项目文件"
fi

echo ""
echo "📋 真机GPS定位问题排查步骤："
echo "=================================="
echo ""
echo "1. 🔐 检查系统设置："
echo "   - 设置 > 隐私与安全性 > 定位服务 > 开启"
echo "   - 设置 > 隐私与安全性 > 定位服务 > CardPilot > 选择'使用期间'或'始终'"
echo ""
echo "2. 📱 检查应用权限："
echo "   - 设置 > 通用 > VPN与设备管理 > 开发者应用 > CardPilot > 位置 > 允许"
echo ""
echo "3. 🌐 检查网络设置："
echo "   - 确保WiFi或蜂窝网络已连接"
echo "   - 检查是否有网络限制"
echo ""
echo "4. 📍 检查GPS信号："
echo "   - 确保在室外或有GPS信号的地方"
echo "   - 避免在建筑物内部或地下"
echo ""
echo "5. 🔄 重启应用和设备："
echo "   - 完全关闭应用后重新打开"
echo "   - 重启设备"
echo ""
echo "6. 🧪 使用调试视图："
echo "   - 在应用中使用LocationDebugView查看详细状态"
echo "   - 检查控制台日志输出"
echo ""
echo "7. ⚙️ 检查Xcode配置："
echo "   - 确保Bundle Identifier正确"
echo "   - 检查Provisioning Profile是否包含位置权限"
echo "   - 验证Entitlements文件配置"
echo ""

echo "🔧 建议的修复操作："
echo "=================================="
echo ""
echo "1. 在Xcode中检查项目设置："
echo "   - 选择项目 > Signing & Capabilities"
echo "   - 确保Location Services已添加"
echo "   - 检查Provisioning Profile权限"
echo ""
echo "2. 更新Info.plist权限描述："
echo "   - 确保权限描述清晰明确"
echo "   - 使用中文描述可能有助于用户理解"
echo ""
echo "3. 代码层面优化："
echo "   - 降低定位精度要求（已实现）"
echo "   - 增加超时时间（已实现）"
echo "   - 添加详细的错误日志（已实现）"
echo ""
echo "4. 测试建议："
echo "   - 先在模拟器中测试"
echo "   - 在真机上使用LocationDebugView诊断"
echo "   - 检查控制台输出"
echo ""

echo "📱 当前修复状态："
echo "=================================="
echo "✅ LocationManager已优化"
echo "✅ 权限检查逻辑已完善"
echo "✅ 错误处理已增强"
echo "✅ 调试视图已创建"
echo "✅ 真机环境特殊处理已添加"
echo ""

echo "🚀 下一步操作："
echo "=================================="
echo "1. 重新编译并安装应用到真机"
echo "2. 使用LocationDebugView查看详细状态"
echo "3. 检查控制台日志输出"
echo "4. 按照上述步骤检查系统设置"
echo ""

echo "💡 如果问题仍然存在，请："
echo "=================================="
echo "1. 查看控制台完整日志"
echo "2. 检查设备系统版本兼容性"
echo "3. 验证Provisioning Profile权限"
echo "4. 联系Apple开发者支持"
echo ""

echo "🔍 诊断完成！"
