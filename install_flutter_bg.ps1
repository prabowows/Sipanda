$ErrorActionPreference = 'Stop'
Write-Host "1. Memulai Download Flutter SDK (3.24.5) secara Fast Track..."
curl.exe -L -C - -o "C:\src\flutter.zip" "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

Write-Host "2. Mengekstrak ZIP archive (ini akan memakan sedikit waktu)..."
tar -xf "C:\src\flutter.zip" -C "C:\src"

Write-Host "3. Memasang PATH..."
$env:PATH += ";C:\src\flutter\bin"

Write-Host "4. Melakukan setup flutter platform..."
Set-Location -Path "d:\AntiGravity\AntiGravity-Project\SiPanda\sipanda_app"
flutter create .
Write-Host "Proses Cepat Selesai!"
