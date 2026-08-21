#!/bin/bash
# JSKeyboard IPA 生成脚本
# 前提：已安装 Xcode 15+ 并登录 Apple ID

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
IPA_OUTPUT="$BUILD_DIR/IPA"
SCHEME="JSKeyboard"
TARGET_PLATFORM="iPhoneOS"
SDK="iphoneos"
ARCH="arm64"
CODE_SIGN="NO"

echo "🔨 JSKeyboard IPA 构建脚本"
echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 未检测到 Xcode，请先安装 Xcode 15+"
    echo "   从 App Store 搜索并安装 Xcode"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1)
echo "✅ Xcode: $XCODE_VERSION"

# 清理旧产物
echo ""
echo "🧹 清理旧构建产物..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 检查 bundle ID
BUNDLE_ID="com.jskeyboard.app"
EXTENSION_ID="com.jskeyboard.app.keyboard"

# ===== Step 1: 编译主应用 =====
echo ""
echo "📦 [1/3] 编译主应用 ($SCHEME)..."
xcodebuild build \
    -project "$PROJECT_DIR/JSKeyboard.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk "$SDK" \
    -arch "$ARCH" \
    CODE_SIGNING_ALLOWED="$CODE_SIGN" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    IPHONEOS_DEPLOYMENT_TARGET=15.0 \
    OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    | tee "$BUILD_DIR/main_build.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 主应用编译失败，请查看 $BUILD_DIR/main_build.log"
    exit 1
fi
echo "✅ 主应用编译完成"

# ===== Step 2: 编译键盘扩展 =====
echo ""
echo "📦 [2/3] 编译键盘扩展..."
xcodebuild build \
    -project "$PROJECT_DIR/JSKeyboard.xcodeproj" \
    -scheme "$SCHEME" \
    -target "JSKeyboardExtension" \
    -configuration Release \
    -sdk "$SDK" \
    -arch "$ARCH" \
    CODE_SIGNING_ALLOWED="$CODE_SIGN" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    PRODUCT_BUNDLE_IDENTIFIER="$EXTENSION_ID" \
    IPHONEOS_DEPLOYMENT_TARGET=15.0 \
    OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    | tee "$BUILD_DIR/ext_build.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 扩展编译失败，请查看 $BUILD_DIR/ext_build.log"
    exit 1
fi
echo "✅ 键盘扩展编译完成"

# ===== Step 3: 打包 IPA =====
echo ""
echo "📦 [3/3] 打包 IPA..."

# 查找编译产物
APP_PATH=$(find "$PROJECT_DIR" -name "*.app" -path "*/Release-*" 2>/dev/null | head -1)
EXT_PATH=$(find "$PROJECT_DIR" -name "*.appex" -path "*/Release-*" 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ 未找到编译产物 .app，请检查构建日志"
    exit 1
fi

echo "   App 路径: $APP_PATH"
echo "   Extension: ${EXT_PATH:-未找到（将内嵌到 App 中）}"

# 创建 IPA 结构
IPA_NAME="JSKeyboard.ipa"
TEMP_IPA="$BUILD_DIR/$IPA_NAME"

# IPA 实际上是一个 .zip 文件，包含 Payload 目录
PAYLOAD_DIR="$BUILD_DIR/Payload"
rm -rf "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR"

# 复制 .app 到 Payload
cp -R "$APP_PATH" "$PAYLOAD_DIR/"

# 复制 extension 到 App 内部（如果需要）
if [ -n "$EXT_PATH" ]; then
    EXT_NAME=$(basename "$EXT_PATH")
    APP_NAME=$(basename "$APP_PATH" .app)
    mkdir -p "$PAYLOAD_DIR/$APP_NAME/PlugIns/$EXT_NAME"
    cp -R "$EXT_PATH" "$PAYLOAD_DIR/$APP_NAME/PlugIns/$EXT_NAME/"
fi

# 打包为 IPA
cd "$BUILD_DIR"
zip -r "$TEMP_IPA" Payload -x "*.DS_Store" > /dev/null
rm -rf "$PAYLOAD_DIR"

echo ""
echo "✅ IPA 生成完成！"
echo "📁 输出路径: $TEMP_IPA"
echo "📏 文件大小: $(du -sh "$TEMP_IPA" | cut -f1)"
echo ""
echo "📲 安装方式："
echo "   方法1: 通过 TestFlight / 企业证书签名后分发"
echo "   方法2: 使用第三方工具（如 ios-deploy）安装到测试设备"
echo "   方法3: 使用 Xcode -> Open Developer Tool -> iOS App Packager"
echo ""
echo "⚠️  注意：此 IPA 未签名，需在 iOS 设备上通过以下方式之一安装："
echo "   - Xcode 直接运行（连接设备）"
echo "   - 使用 odyssey-repo / palera1n 等越狱安装工具"
echo "   - 使用企业描述文件或 TestFlight 分发"
