#!/bin/bash
# 开发环境构建脚本（Linux/Mac）
# 使用本地开发服务器地址

echo "Building for development environment..."
echo "API Base URL: http://localhost:9278"

flutter build web --dart-define=API_BASE_URL=http://localhost:9278

echo ""
echo "Build completed!"
echo "Output: build/web/"





















