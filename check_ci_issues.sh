#!/bin/bash

# PE Reader 项目完整性检查脚本
# 检查导入、依赖、语法等问题

echo "🔍 PE Reader 项目完整性检查"
echo "=============================="
echo ""

cd /root/pe

# 1. 检查包名
echo "1. 检查 pubspec.yaml 包名..."
PKG_NAME=$(grep "^name:" pubspec.yaml | awk '{print $2}')
if [[ "$PKG_NAME" =~ " " ]]; then
  echo "   ❌ 包名包含空格: $PKG_NAME"
else
  echo "   ✅ 包名有效: $PKG_NAME"
fi
echo ""

# 2. 检查所有 Dart 文件的导入
echo "2. 检查 Dart 文件导入路径..."
INVALID_IMPORTS=0
while IFS= read -r file; do
  if grep -q "package:pe_reader" "$file" || grep -q "package:PE Reader" "$file"; then
    echo "   ❌ $file - 错误包名"
    ((INVALID_IMPORTS++))
  fi
done < <(find lib test -name "*.dart" -type f 2>/dev/null)

if [ $INVALID_IMPORTS -eq 0 ]; then
  echo "   ✅ 所有导入路径正确"
else
  echo "   ⚠️  发现 $INVALID_IMPORTS 个文件使用错误包名"
fi
echo ""

# 3. 检查测试文件包名
echo "3. 检查测试文件..."
if grep -q "package:reader_flutter" test/core/errors/exceptions_test.dart 2>/dev/null; then
  echo "   ✅ 测试文件包名正确"
else
  echo "   ❌ 测试文件包名错误"
fi
echo ""

# 4. 检查关键文件是否存在
echo "4. 检查关键优化文件是否存在..."
FILES=(
  "lib/core/constants/app_constants.dart"
  "lib/core/errors/exceptions.dart"
  "lib/core/logger/logger.dart"
  "lib/core/network/dio_client.dart"
  "lib/core/storage/preferences.dart"
  "lib/core/utils/debouncer.dart"
  "lib/ui/widgets/book_cover.dart"
  "lib/services/api_service_v2.dart"
  "test/core/errors/exceptions_test.dart"
  ".github/workflows/ci.yml"
  "analysis_options.yaml"
  "scripts/optimize.sh"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "   ✅ $file"
  else
    echo "   ❌ $file 缺失"
  fi
done
echo ""

# 5. 检查是否有 print() 语句（会被 lint 视为错误）
echo "5. 检查 print() 语句..."
PRINT_COUNT=$(grep -r "print(" --include="*.dart" lib/ | grep -v "debugPrint" | grep -v "// " | wc -l)
if [ $PRINT_COUNT -eq 0 ]; then
  echo "   ✅ 未使用 print()"
else
  echo "   ⚠️  发现 $PRINT_COUNT 处 print() 调用"
fi
echo ""

# 6. 检查 pubspec.yaml 依赖
echo "6. 检查必要依赖..."
DEPS=(
  "dio"
  "logger"
  "cached_network_image"
  "shared_preferences"
  "http"
)

for dep in "${DEPS[@]}"; do
  if grep -q "^  $dep:" pubspec.yaml; then
    echo "   ✅ $dep"
  else
    echo "   ❌ $dep 缺失"
  fi
done
echo ""

# 7. 检查分析选项
echo "7. 检查 analysis_options.yaml..."
if [ -f "analysis_options.yaml" ]; then
  if grep -q "avoid_print: error" analysis_options.yaml; then
    echo "   ✅ avoid_print 设置为 error"
  else
    echo "   ⚠️  avoid_print 未设置为 error"
  fi
else
  echo "   ❌ analysis_options.yaml 不存在"
fi
echo ""

# 8. 尝试编译检查（需要 Flutter）
echo "8. Flutter 编译检查..."
if command -v flutter &> /dev/null; then
  echo "   运行 flutter analyze..."
  flutter analyze --no-pub 2>&1 | head -20
else
  echo "   ⚠️  Flutter 未安装，跳过编译检查"
  echo "   建议在本地运行: flutter pub get && flutter analyze"
fi
echo ""

echo "✅ 检查完成！"
echo ""
echo "如果发现任何问题，请修复后重新提交："
echo "  git add . && git commit -m 'fix: 修复 CI 问题' && git push origin master"
