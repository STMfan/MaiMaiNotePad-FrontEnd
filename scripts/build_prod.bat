@echo off
REM 生产环境构建脚本（Windows）
REM 使用默认生产服务器地址

echo Building for production environment...
echo API Base URL: http://hk-2.lcf.im:10103

flutter build web --release

echo.
echo Build completed!
echo Output: build/web/







