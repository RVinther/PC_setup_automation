Clear-Host

$LogMappe = "C:\Logs"
$SupportMappe = "C:\Support"
$TempMappe = "C:\Temp"

New-Item $LogMappe -ItemType Directory -Force | Out-Null

$log = "$LogMappe\Setup_log.txt"

Start-Transcript $log -Force

$bruger = [Security.Principal.WindowsIdentity]::GetCurrent()
$ret = New-Object Security.Principal.WindowsPrincipal($bruger)

if (-not $ret.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Koer som administrator!"
    Read-Host "Tryk Enter for at afslutte"
    Exit
}

function Sektion($sektion) {
    Write-Host ""
    Write-Host "===================="
    Write-Host "$sektion"
    Write-Host "===================="
    Write-Host ""
}

function test_internet {
    if (Test-NetConnection 8.8.8.8 -InformationLevel Quiet) {
        Write-Host "Internetforbindelse er OK" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Ingen internetforbindelse!" -ForegroundColor Red
        return $false
    }
}

function tjek_winget {

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $version = winget --version
        Write-Host "Winget fundet (version $version)" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Winget ikke fundet" -ForegroundColor Yellow
        return $false
    }
}

function installer_winget {

    Write-Host "Installerer winget..." -ForegroundColor Yellow

    $url = "https://aka.ms/getwinget"
    $fil = "$env:TEMP\winget.msixbundle"

    try {
        Invoke-WebRequest $url -OutFile $fil -ErrorAction Stop
        Add-AppxPackage -Path $fil -ErrorAction Stop
        Write-Host "Winget installeret" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Winget installation fejlede" -ForegroundColor Red
        return $false
    }
}

function applikationer {
    $apps = @(
        "Google.Chrome",
        "7zip.7zip",
        "VideoLAN.VLC",
        "Dropbox.Dropbox",
        "Adobe.Acrobat.Reader.64-bit",
        "Microsoft.VisualStudioCode",
        "Notepad++.Notepad++"
    )

    foreach ($app in $apps) {
        Write-Host "Installerer $app..." -ForegroundColor Yellow
        
        winget install --id $app -e --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$app installeret korrekt" -ForegroundColor Green
        }
        else {
            Write-Host "Fejl ved installation af $app" -ForegroundColor Red
        }
    }
}

function lav_mapper {
    $mapper = @(
        "$SupportMappe",
        "$TempMappe"
    )

    foreach ($mappe in $mapper) {
        New-Item $mappe -ItemType Directory -Force
    }
}

function kop_filer {
    $kilde = "$PSScriptRoot\Filer"

    if (-not (Test-Path $kilde)) {
        Write-Host "Ingen Filer-mappe fundet" -ForegroundColor Yellow
        return
    }

    Copy-Item "$kilde\*" "$SupportMappe" -Recurse -Force
}

function endelser {
    Set-ItemProperty -PATH "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    Set-ItemProperty -PATH "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
}

Sektion "STARTER SETUP AF PC"

Sektion "Tester internet"
if (-not (test_internet)) {
    Stop-Transcript
    Read-Host "Tryk Enter for at afslutte"
    Exit
}

Sektion "Tjekker winget"
if (-not (tjek_winget)) {
    if (-not (installer_winget)) {
        Stop-Transcript
        Read-Host "Winget kunne ikke installeres. Tryk Enter for at afslutte"
        Exit
    }

    if (-not (tjek_winget)) {
        Stop-Transcript
        Read-Host "Winget virker stadig ikke. Tryk Enter for at afslutte"
        Exit
    }
}

Sektion "Opretter mapper"
lav_mapper

Sektion "Flytter filer til $SupportMappe"
kop_filer

Sektion "Installerer applikationer"
applikationer

Sektion "Saetter indstillinger"
endelser

Sektion "SETUP AF PC SLUT"

Stop-Transcript

Write-Host ""
Write-Host "Find log her:"
Write-Host "$log" -ForegroundColor Cyan
Write-Host ""

Read-Host "Tryk Enter for at afslutte"
Exit