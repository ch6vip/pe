#!/bin/bash

# PE Reader 自动化优化脚本
# 用法: bash scripts/optimize.sh

set -e  # 遇到错误退出

echo "🔧 PE Reader 项目优化脚本"
echo "================================"

# 检查是否在项目根目录
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ 请在项目根目录运行此脚本"
  exit 1
fi

# 1. 格式化代码
echo "📝 1. 格式化代码..."
flutter format .

# 2. 静态分析
echo "🔍 2. 运行静态分析..."
flutter analyze || true  # 不中断，仅警告

# 3. 更新依赖
echo "📦 3. 更新依赖..."
flutter pub upgrade --major-versions

# 4. 生成代码覆盖率报告
echo "🧪 4. 运行测试..."
if [ -d "test" ]; then
  flutter test --coverage
  echo "📊 覆盖率报告: coverage/lcov.info"
else
  echo "⚠️  未找到测试目录，跳过测试"
fi

# 5. 检查 pubspec.yaml 格式
echo "🔬 5. 验证 pubspec.yaml..."
dart pub get --dry-run

# 6. 检查废弃 API
echo "🚫 6. 检查废弃 API..."
flutter pub outdated || true

# 7. 生成文档 (如果配置了)
if [ -f "dart_docs.yaml" ]; then
  echo "📚 7. 生成 API 文档..."
  dart doc
fi

echo "✅ 优化完成！"
echo ""
echo "建议的后续步骤:"
echo "  1. 查看分析警告并修复"
echo "  2. 补充测试用例 (目标覆盖率 >80%)"
echo "  3. 考虑添加 CI/CD 配置"
echo "  4. 更新 README.md"
