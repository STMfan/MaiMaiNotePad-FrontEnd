#!/bin/bash
# 启动构建好的Web项目（Linux/Mac）
# 使用Python内置HTTP服务器

echo "Starting web server..."
echo "Serving build/web/ directory"
echo ""
echo "Open your browser and visit: http://localhost:8000"
echo "Press Ctrl+C to stop the server"
echo ""

cd "$(dirname "$0")/.."
cd build/web

# 检查Python是否可用
if command -v python3 &> /dev/null; then
    echo "Using Python3 HTTP server..."
    python3 -m http.server 8000
elif command -v python &> /dev/null; then
    echo "Using Python HTTP server..."
    python -m http.server 8000
else
    echo "Python not found. Trying alternative methods..."
    echo ""
    echo "Please use one of the following methods:"
    echo "1. Install Python and run this script again"
    echo "2. Use Node.js: npx http-server build/web -p 8000"
    echo "3. Use Flutter: flutter run -d chrome --release"
    exit 1
fi















