# 停止常见进程
$procs = @('dart.exe','java.exe','adb.exe','gradle.exe','node.exe')
foreach ($p in $procs) {
  try { taskkill /f /im $p | Out-Null } catch {}
}

# 停止 Gradle
if (Test-Path ".\android\gradlew.bat") {
  Push-Location .\android
  try { .\gradlew.bat --stop | Out-Null } catch {}
  Pop-Location
}

# 尝试删除 build
try { rd /s /q .\build } catch {}

# 再跑 flutter clean
flutter clean