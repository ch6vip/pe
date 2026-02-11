# 贡献指南

感谢您对 PE 阅读器项目的关注！我们欢迎任何形式的贡献。

## 🤝 如何贡献

### 报告问题

如果您发现了 bug 或有功能建议：

1. 先搜索 [Issues](../../issues) 确认是否已有相同问题
2. 如果没有，创建新的 Issue，提供：
   - 清晰的标题
   - 详细的问题描述
   - 复现步骤
   - 预期行为
   - 实际行为
   - 环境信息（Flutter 版本、平台等）
   - 相关日志（如果有）

### 提交代码

#### 开发流程

1. **Fork 仓库**
   ```bash
   # 点击 GitHub 页面右上角的 Fork 按钮
   ```

2. **克隆到本地**
   ```bash
   git clone https://github.com/your-username/pe.git
   cd pe
   ```

3. **创建分支**
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/your-bug-fix
   ```

4. **进行开发**
   - 遵循现有代码风格
   - 添加必要的注释
   - 确保代码通过 lint 检查

5. **提交代码**
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   ```

6. **推送到 Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **创建 Pull Request**
   - 在 GitHub 上发起 PR
   - 清晰描述改动内容
   - 关联相关的 Issue

#### 代码规范

- 遵循 [Dart 代码规范](https://dart.dev/guides/language/effective-dart/style)
- 使用 `flutter analyze` 检查代码
- 所有公共 API 必须有文档注释
- 使用有意义的变量和函数命名
- 保持函数简洁，单一职责

#### Commit 消息规范

使用语义化提交消息：

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 重构（不是新功能也不是修复 bug）
- `perf`: 性能优化
- `test`: 添加或修改测试
- `chore`: 构建过程或辅助工具的变动

示例：
```
feat(reader): 添加章节预加载功能
fix(api): 修复网络请求超时问题
docs(readme): 更新安装说明
```

## 🧪 测试

在提交 PR 前，请确保：

- 代码可以通过 `flutter analyze` 检查
- 在至少一个平台上测试过改动
- 新功能有相应的测试用例（如适用）

## 📝 文档

如果您修改了功能，请同步更新相关文档：
- README.md
- CHANGELOG.md
- 代码注释

## 💬 讨论

对于较大的改动，建议先创建 Issue 讨论：
- 新功能设计
- 架构调整
- 重大 bug 修复方案

## 📜 行为准则

请尊重所有贡献者，保持友好和专业的交流态度。

## 📧 联系方式

如有任何问题，欢迎通过 Issue 联系我们。

---

再次感谢您的贡献！
