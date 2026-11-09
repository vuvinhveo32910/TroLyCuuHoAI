@echo off
chcp 65001 >nul
title Thiết lập Môi trường Dự án Trợ lý Cứu hộ AI
echo =======================================================================
echo   TRỢ LÝ CỨU HỘ AI - TỰ ĐỘNG THIẾT LẬP DỰ ÁN CHO THÀNH VIÊN NHÓM
echo =======================================================================
echo.

echo [1/3] Đang tải các gói thư viện Flutter...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [!] Lưu ý: Kiểm tra đường dẫn Flutter SDK nếu có lỗi.
) else (
    echo [+] Tải thư viện Flutter thành công!
)
echo.


echo [2/3] Dang kiem tra Python tren may...

where python >nul 2>&1

if errorlevel 1 goto PYTHON_NOT_FOUND

echo [+] Da tim thay Python.
echo [+] Dang cai dat thu vien YOLO...

python -m pip install ultralytics pillow --quiet

if errorlevel 1 (
    echo [!] Cai dat thu vien Python that bai.
) else (
    echo [+] Da cai dat xong thu vien YOLO!
)

goto PYTHON_DONE

:PYTHON_NOT_FOUND
echo [!] May chua cai Python.
echo     Vui long tai Python tai:
echo     https://www.python.org/downloads/
echo     Nho chon Add Python to PATH khi cai dat.

:PYTHON_DONE
echo.


echo [3/3] Kết nối Supabase Database...
echo [+] Đã tích hợp sẵn thông tin kết nối Supabase Cloud trong mã nguồn.
echo.

echo =======================================================================
echo   CHÚC MỪNG: DỰ ÁN ĐÃ SẴN SÀNG!
echo   Thành viên nhóm có thể mở VS Code và nhấn F5 (hoặc gõ flutter run) để chạy ngay!
echo =======================================================================
echo.
pause
