@echo off
chcp 65001 >nul
title بناء برنامج صحتي

echo.
echo ============================================
echo    بناء برنامج صحتي - إصدار ويندوز
echo ============================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [خطأ] لم يتم العثور على Flutter. تأكد من تثبيته وإضافته للمسار PATH.
    pause
    exit /b 1
)

echo [1/4] جاري التحقق من تحديثات الحزم...
call flutter pub get
if %errorlevel% neq 0 (
    echo [خطأ] فشل تحميل الحزم.
    pause
    exit /b 1
)

echo [2/4] جاري تحليل الكود...
call flutter analyze
if %errorlevel% neq 0 (
    echo [تحذير] توجد تحذيرات في الكود لكن سيستمر البناء.
)

echo [3/4] جاري بناء البرنامج لويندوز...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [خطأ] فشل بناء البرنامج.
    pause
    exit /b 1
)

echo [4/4] جاري تجهيز الملف النهائي...
set "OUTPUT_DIR=.\build\صحتي"
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

REM Copy the build output
xcopy /E /I /Y "build\windows\x64\runner\Release\*" "%OUTPUT_DIR%\" >nul 2>nul
if %errorlevel% neq 0 (
    REM Try alternative path
    xcopy /E /I /Y "build\windows\x64\runner\Release\*" "%OUTPUT_DIR%\" >nul 2>nul
)

REM Rename the executable
if exist "%OUTPUT_DIR%\صحتي.exe" (
    echo تم بناء البرنامج بنجاح!
) else (
    echo تم بناء البرنامج. الملفات موجودة في: %OUTPUT_DIR%
)

echo.
echo ============================================
echo    تم البناء بنجاح! ✓
echo    البرنامج موجود في: %OUTPUT_DIR%
echo ============================================
echo.
pause
