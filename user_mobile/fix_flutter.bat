@echo off
echo [INFO] Memulai perbaikan mendalam Flutter SDK...
cd /d C:\Users\USER\flutter

echo [INFO] Menghapus cache internal Flutter (ini akan diunduh ulang nanti)...
if exist bin\cache (
    rmdir /s /q bin\cache
)

echo [INFO] Menghapus dan mengatur ulang remote Git...
git remote remove origin
git remote add origin https://github.com/flutter/flutter.git
git fetch origin
git checkout stable
git reset --hard origin/stable

echo [INFO] Membersihkan konfigurasi Git yang mungkin tersisa...
git config --unset-all remote.origin.url
git config remote.origin.url https://github.com/flutter/flutter.git

echo [INFO] Memastikan variabel lingkungan bersih untuk sesi ini...
set FLUTTER_GIT_URL=

echo [INFO] Menjalankan inisialisasi ulang (tunggu sebentar)...
call bin\flutter doctor

echo.
echo [SUKSES] Perbaikan selesai!
echo Silakan coba jalankan kembali 'flutter upgrade' sekarang.
echo.
pause
