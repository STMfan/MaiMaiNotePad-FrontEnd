@echo off
REM 开发环境运行脚本（Windows）
REM 使用本地开发服务器地址

echo Running in development mode...
echo API Base URL: http://localhost:9278

flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9278







