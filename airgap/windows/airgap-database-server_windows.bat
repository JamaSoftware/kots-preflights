@echo off
setlocal
cd %cd%
echo %cd%\airgap-database-preflight_windows.zip
"C:\Program Files\7-Zip\7z.exe" x "%cd%\airgap-database-preflight_windows.zip" -o"C:\Temp\" 
"C:\Program Files\7-Zip\7z.exe" x "C:\Temp\airgap-database-preflight_windows\support-bundle\support-bundle_windows_amd64.zip" -o"C:\Temp\" 
C:\Temp\airgap-database-preflight_windows\support-bundle\support-bundle_windows_amd64\support-bundle.exe C:\Temp\airgap-database-preflight_windows\database-preflight.yml

RMDIR /S /Q "C:\Temp\airgap-database-preflight_windows"
del "C:\Temp\support-bundle.exe"
del "C:\Temp\key.pub"
del "C:\Temp\LICENSE"
del "C:\Temp\troubleshoot-sbom.tgz"
del "C:\Temp\troubleshoot-sbom.tgz.sig"


exit /b

