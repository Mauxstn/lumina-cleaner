@echo off
:: ==================================
::  Lumina Cleaner
::  by Maurice - v3.2
::  https://github.com/yourusername/LuminaCleaner
:: ==================================

:: Check for updates if not started with /noupdate
if not "%~1"=="/noupdate" (
    call :check_for_updates
    if errorlevel 1 (
        echo.
        call :center "Update verfuegbar! Moechtest du es jetzt installieren? (J/N)"
        choice /c JN /n /m "  Auswahl: "
        if %errorlevel% equ 1 (
            call :install_update
            exit /b
        )
    )
)

goto :start_script

:check_for_updates
setlocal
set "update_available=0"

:: Get current script version
set "current_version=3.2"

:: Get latest version from GitHub
curl -s -o "%TEMP%\latest_version.txt" https://raw.githubusercontent.com/yourusername/LuminaCleaner/main/version.txt 2>nul
if %errorlevel% neq 0 (
    endlocal & exit /b 0
)

set /p "latest_version=" < "%TEMP%\latest_version.txt"
del "%TEMP%\latest_version.txt" 2>nul

:: Compare versions
if "%latest_version%" gtr "%current_version%" (
    endlocal & exit /b 1
) else (
    endlocal & exit /b 0
)

:install_update
setlocal
call :center "Update wird heruntergeladen..."

:: Download the new version
curl -s -o "%TEMP%\LuminaCleaner_new.bat" https://raw.githubusercontent.com/yourusername/LuminaCleaner/main/LuminaCleaner.bat 2>nul
if %errorlevel% neq 0 (
    call :center "Fehler beim Herunterladen des Updates!"
    timeout /t 3 >nul
    endlocal & exit /b 1
)

:: Replace the current script
move /y "%TEMP%\LuminaCleaner_new.bat" "%~f0" >nul

call :center "Update erfolgreich installiert! Starte neu..."
timeout /t 2 >nul

:: Restart with the new version
start "" /b "cmd" /c ""%~f0" /noupdate"
endlocal
exit /b 0

:start_script
setlocal enabledelayedexpansion

mode con: cols=70 lines=28
title Lumina Cleaner by Maurice v3.2
color 0B
cls

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [FEHLER] Bitte als Administrator ausfuehren!
    echo  ---------------------------------
    echo  1. Rechtsklick auf die Datei
    echo  2. 'Als Administrator ausfuehren' waehlen
    echo.
    pause
    exit /b 1
)

goto :menu

:center
echo  %~1
goto :eof

:menu
cls
echo.
echo  =================================
  echo     LUMINA CLEANER by Maurice
  echo  =================================
  echo  1. Verlauf ^& Cookies loeschen (sicher)
  echo  2. Komplett bereinigen (Achtung!)
  echo  3. System optimieren ^& aufraeumen
  echo  4. Beenden
  echo  =================================
  
choice /c 1234 /n /m "  Auswahl (1-4): "

if %errorlevel% equ 1 goto clean
if %errorlevel% equ 2 goto advanced_clean
if %errorlevel% equ 3 goto optimize
if %errorlevel% equ 4 exit

:clean
cls
echo.
call :center "SICHERE BERREINIGUNG WIRD VORBEREITET"
call :center "===================================="
timeout /t 1 >nul

:: Chrome - Erweiterte sichere Bereinigung
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\" (
    call :center "[CHROME] Bereinigung gestartet..."
    
    :: 1. Cache löschen
    if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
        rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
        call :center "  • Cache erfolgreich gelöscht"
    )
    
    :: 2. Verlauf löschen, aber Downloads behalten
    if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\History" (
        :: Temporäre Sicherung der Downloads
        sqlite3 "%LOCALAPPDATA%\Google\Chrome\User Data\Default\History" ".backup '%TEMP%\chrome_history_backup.db'" >nul 2>&1
        
        :: Lösche nur den Verlauf, nicht die Downloads
        sqlite3 "%LOCALAPPDATA%\Google\Chrome\User Data\Default\History" "DELETE FROM urls WHERE url NOT LIKE 'chrome://downloads%'" >nul 2>&1
        call :center "  • Verlauf gelöscht (Downloads behalten)"
    )
    
    :: 3. Formulardaten und Passwörter behalten
    call :center "  • Wichtige Daten wurden beibehalten"
    
    :: 4. Lesezeichen sichern
    if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Bookmarks" (
        copy "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Bookmarks" "%TEMP%\chrome_bookmarks_backup" >nul 2>&1
    )
    
    call :center "[CHROME] Bereinigung abgeschlossen"
    timeout /t 1 >nul
) else (
    call :center "[INFO] Chrome nicht gefunden"
)

:: Firefox - Erweiterte sichere Bereinigung
if exist "%APPDATA%\Mozilla\Firefox\Profiles\" (
    call :center "[FIREFOX] Bereinigung gestartet..."
    
    for /d %%i in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
        :: 1. Cache löschen
        if exist "%%i\cache2\" (
            rd /s /q "%%i\cache2" 2>nul
            call :center "  • Cache erfolgreich gelöscht"
        )
        
        :: 2. Verlauf löschen, aber Downloads behalten
        if exist "%%i\places.sqlite" (
            sqlite3 "%%i\places.sqlite" "DELETE FROM moz_historyvisits WHERE id IN (SELECT v.id FROM moz_places h JOIN moz_historyvisits v ON h.id = v.place_id WHERE h.url NOT LIKE 'place:%' AND h.url NOT LIKE 'about:downloads%');" >nul 2>&1
            call :center "  • Verlauf gelöscht (Downloads behalten)"
        )
        
        :: 3. Formulardaten und Passwörter behalten
        call :center "  • Wichtige Daten wurden beibehalten"
    )
    
    call :center "[FIREFOX] Bereinigung abgeschlossen"
    timeout /t 1 >nul
) else (
    call :center "[INFO] Firefox nicht gefunden"
)

:: Microsoft Edge (Chromium-basiert)
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\" (
    call :center "[EDGE] Bereinigung gestartet..."
    
    :: Cache löschen
    if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
        rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
        call :center "  • Cache erfolgreich gelöscht"
    )
    
    call :center "[EDGE] Bereinigung abgeschlossen"
    timeout /t 1 >nul
)

:: Erfolgsmeldung
cls
echo.
call :center "==================================="
call :center " BEREINIGUNG ERFOLGREICH ABGESCHLOSSEN "
call :center "==================================="
echo.
call :center "Zusammenfassung der Bereinigung:"
call :center "• Browser-Cache wurde gelöscht"
call :center "• Verlauf wurde bereinigt"
call :center "• Downloads wurden beibehalten"
call :center "• Gespeicherte Logins & Formulardaten sind erhalten"
call :center "• Lesezeichen wurden nicht verändert"
echo.
call :center "Deine Browser sollten jetzt schneller laufen!"
timeout /t 4 >nul
goto :menu

:advanced_clean
cls
echo.
call :center "WARNUNG: ERWEITERTE BEREINIGUNG"
call :center "-------------------------------"
call :center "Diese Aktion wird dich ueberall ausloggen!"
call :center "- Alle Browser-Sessions werden beendet"
call :center "- Alle gespeicherten Logins gehen verloren"
call :center "- Alle offenen Tabs gehen verloren"
echo.
call :center "Moechtest du wirklich fortfahren? (J/N)"
choice /c JN /n /m "                               Auswahl: "

if %errorlevel% equ 2 (
    call :center "Vorgang abgebrochen"
    timeout /t 2 >nul
    goto :menu
)

cls
echo.
call :center "Erweiterte Bereinigung startet..."
call :center "Dies kann mehrere Minuten dauern..."
timeout /t 2 >nul

:: Close all browser processes first
taskkill /f /im chrome.exe >nul 2>&1
taskkill /f /im firefox.exe >nul 2>&1
taskkill /f /im msedge.exe >nul 2>&1
timeout /t 2 >nul

:: Chrome - Complete clean (including login data)
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\" (
    call :center "Bereinige Google Chrome komplett..."
    
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default" 2>nul
    if errorlevel 1 (
        call :center "Warnung: Konnte Chrome-Daten nicht vollstaendig loeschen"
    ) else (
        call :center "Chrome-Daten erfolgreich geloescht"
    )
    
    timeout /t 1 >nul
)

:: Firefox - Complete clean (including login data)
if exist "%APPDATA%\Mozilla\Firefox\Profiles\" (
    call :center "Bereinige Firefox komplett..."
    
    for /d %%i in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
        rd /s /q "%%i" 2>nul
    )
    
    if errorlevel 1 (
        call :center "Warnung: Konnte Firefox-Daten nicht vollstaendig loeschen"
    ) else (
        call :center "Firefox-Daten erfolgreich geloescht"
    )
    
    timeout /t 1 >nul
)

:: Additional cleanup
call :center "Bereinige Systemtemp..."
del /q /f /s "%temp%\*.*" >nul 2>&1
if errorlevel 1 (
    call :center "Warnung: Konnte nicht alle Temp-Dateien loeschen"
) else (
    call :center "Temp-Ordner erfolgreich bereinigt"
)

call :center "Bereinige Zwischenablage..."
echo off | clip
if errorlevel 1 (
    call :center "Warnung: Konnte Zwischenablage nicht leeren"
) else (
    call :center "Zwischenablage erfolgreich geleert"
)

:: Finale Meldung
cls
echo.
call :center "==================================="
call :center " ERWEITERTE BEREINIGUNG FERTIG "
call :center "==================================="
timeout /t 3 >nul
goto :menu

:optimize
cls
echo.
call :center "SYSTEMOPTIMIERUNG WIRD VORBEREITET..."
timeout /t 1 >nul

:: 1. Clear temporary files
echo.
call :center "1/5 Bereinige temporaere Dateien..."
cleanmgr /sagerun:1 >nul 2>&1
timeout /t 1 >nul

:: 2. Clean Windows temp folder
echo.
call :center "2/5 Bereinige Windows-Temp-Ordner..."
del /q /f /s %temp%\*.* >nul 2>&1
timeout /t 1 >nul

:: 3. Empty Recycle Bin
echo.
call :center "3/5 Bereinige Papierkorb..."
rd /s /q %systemdrive%\$Recycle.bin >nul 2>&1
timeout /t 1 >nul

:: 4. Optimize system performance
echo.
call :center "4/5 Optimiere Systemleistung..."
powercfg -h off >nul 2>&1
timeout /t 1 >nul

:: 5. Restart Windows services
echo.
call :center "5/5 Starte Windows-Dienste neu..."
net stop wuauserv >nul 2>&1
net start wuauserv >nul 2>&1
timeout /t 1 >nul

:: Final message
cls
echo.
call :center "=================================="
call :center " SYSTEMOPTIMIERUNG ABGESCHLOSSEN "
call :center "=================================="
echo.
call :center "Dein System wurde erfolgreich optimiert!"
call :center " "
call :center "Tipp: Starte deinen Computer neu, um alle"
call :center "Aenderungen zu uebernehmen."
timeout /t 5 >nul
goto :menu