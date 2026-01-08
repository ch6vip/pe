# Android 应用签名配置指南

## 概述

本指南将帮助您为 Flutter Android 应用配置正式的发布签名。签名是发布应用到 Google Play 或其他应用商店的必要步骤。

## 步骤 1: 生成签名密钥库 (Keystore)

使用 Java 的 `keytool` 命令生成密钥库文件。在项目根目录执行以下命令：

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 命令说明：
- `-keystore`: 指定密钥库文件路径
- `-keyalg RSA`: 使用 RSA 算法
- `-keysize 2048`: 密钥大小为 2048 位
- `-validity 10000`: 有效期 10000 天（约 27 年）
- `-alias upload`: 密钥别名

### 执行时需要输入：
1. **密钥库密码** (storePassword): 设置一个强密码并记住它
2. **密钥密码** (keyPassword): 可以与密钥库密码相同
3. **您的姓名** (CN): 例如：John Doe
4. **组织单位** (OU): 例如：Development
5. **组织名称** (O): 例如：Your Company
6. **城市或地区** (L): 例如：Beijing
7. **省/市/自治区** (ST): 例如：Beijing
8. **国家代码** (C): 例如：CN

## 步骤 2: 配置 key.properties

编辑 `android/key.properties` 文件，填入您在步骤 1 中设置的密码：

```properties
storePassword=您设置的密钥库密码
keyPassword=您设置的密钥密码
keyAlias=upload
storeFile=../app/upload-keystore.jks
```

**重要提示**：
- `key.properties` 文件已在 `.gitignore` 中，不会被提交到版本控制
- 请妥善保管密钥库文件和密码，丢失后无法恢复

## 步骤 3: 验证配置

配置完成后，您可以通过以下命令验证签名配置是否正确：

```bash
# 构建 release 版本的 APK
flutter build apk --release

# 或者构建 App Bundle (推荐用于 Google Play)
flutter build appbundle --release
```

构建成功后，输出文件位于：
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

## 步骤 4: 备份密钥库

**非常重要**：请将以下文件备份到安全的地方：
1. `android/app/upload-keystore.jks` - 密钥库文件
2. `android/key.properties` - 密钥配置文件（包含密码）

建议备份到：
- 加密的云存储
- 安全的物理存储设备
- 密码管理器

## GitHub Actions 签名配置

在 GitHub Actions 中进行自动化构建时，需要使用 GitHub Secrets 来安全地存储签名信息。

### 步骤 1: 配置 GitHub Secrets

在 GitHub 仓库中设置以下 Secrets：

1. 进入 GitHub 仓库页面
2. 点击 Settings → Secrets and variables → Actions
3. 点击 "New repository secret" 添加以下 secrets：

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `SIGNING_STORE_PASSWORD` | `qazwsx520` | 密钥库密码 |
| `SIGNING_KEY_PASSWORD` | `qazwsx520` | 密钥密码 |
| `SIGNING_KEY_ALIAS` | `ch6vip` | 密钥别名 |
| `SIGNING_KEYSTORE_BASE64` | (见下方说明) | Base64编码的密钥库文件 |

### 步骤 2: 生成密钥库的 Base64 编码

在本地执行以下命令生成密钥库文件的 Base64 编码：

```bash
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/ch6vip-keystore.jks")) | Out-File -FilePath 'keystore.base64' -Encoding UTF8

# macOS/Linux
base64 -i android/app/ch6vip-keystore.jks -o keystore.base64
```

然后将 `keystore.base64` 文件的内容复制到 `SIGNING_KEYSTORE_BASE64` secret 中。

### 步骤 3: 工作流配置

GitHub Actions 工作流已配置为：
- **普通 push**: 构建签名的 release 版本 APK
- **推送 tag**: 构建签名的 release 版本 APK 并创建 GitHub Release

所有构建都会使用签名配置，确保APK的一致性和发布准备。当推送包含版本号的 tag 时（如 `v1.0.0`），会额外：
1. 创建 GitHub Release
2. 上传签名的 APK 文件到 Release

### 步骤 4: 验证配置

推送一个版本 tag 来测试配置：

```bash
git tag v1.0.0
git push origin v1.0.0
```

### 安全注意事项

1. **Secrets 加密**: GitHub Secrets 在传输和存储时都是加密的
2. **权限控制**: 确保只有受信任的协作者有权限访问 Secrets
3. **定期轮换**: 建议定期更换签名密码和密钥库
4. **本地备份**: 即使配置了 GitHub Secrets，仍建议本地备份密钥库文件

## 常见问题

### 1. keytool 命令找不到

确保已安装 Java JDK 并配置了环境变量。可以通过以下命令检查：

```bash
java -version
```

### 2. 密钥库密码忘记

如果忘记密码，您需要重新生成密钥库文件。但请注意，这会导致应用无法更新（因为签名不同）。

### 3. 不同环境使用不同签名

- **开发环境**: 使用 debug 签名（自动生成）
- **发布环境**: 使用 release 签名（您配置的）

### 4. Google Play 上传密钥 vs 应用签名密钥

- **上传密钥**: 用于上传新版本到 Google Play
- **应用签名密钥**: Google Play 用于签名最终 APK

建议使用同一个密钥库，但可以创建不同的别名。

## 安全建议

1. **不要将密钥库文件提交到版本控制系统**
2. **使用强密码**（至少 12 个字符，包含大小写字母、数字和特殊字符）
3. **定期备份密钥库文件**
4. **限制对密钥库文件的访问权限**
5. **考虑使用密钥管理服务**（如 Google Cloud KMS）

## 参考链接

- [Flutter Android 发布指南](https://flutter.dev/docs/deployment/android)
- [Android 应用签名](https://developer.android.com/studio/publish/app-signing)
- [Google Play 应用签名](https://support.google.com/googleplay/android-developer/answer/7384423)
- [GitHub Secrets 使用指南](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)