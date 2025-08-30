#!/bin/bash

APP_PATH="$1"

if [ -z "$APP_PATH" ]; then
  echo "用法: ./sign_wine_app.sh /path/to/YourApp.app"
  exit 1
fi

echo "🔍 扫描 $APP_PATH 中的 Mach-O 文件以签名..."

# 查找所有文件，逐个检查是否为 Mach-O，可签名
find "$APP_PATH" -type f | while read -r file; do
  if file "$file" | grep -q "Mach-O"; then
    echo "✅ 签名: $file"
    codesign --force --sign - "$file"
  else
    echo "⏭️ 跳过: $file"
  fi
done

echo "🔏 对整个 .app 包进行深度签名..."
codesign --force --deep --sign - "$APP_PATH"

echo "✅ 签名完成"

# 可选验证
echo "🧪 验证签名..."
# codesign --verify --deep --strict --verbose=2 "$APP_PATH"
sudo codesign --verify --deep --strict --verbose=2 "$APP_PATH"

