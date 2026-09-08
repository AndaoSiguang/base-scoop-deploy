#requires -Version 5.1

$ErrorActionPreference = "Stop"

function Test-Tool {
    param (
        [string]$CommandName
    )

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        return $false
    }

    & $CommandName --version *> $null

    return $LASTEXITCODE -eq 0
}

function Install-ScoopPackage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    Write-Host "Installing $PackageName..." -ForegroundColor Yellow

    & scoop install $PackageName
    $installExitCode = $LASTEXITCODE

    if ($installExitCode -ne 0) {
        throw "Failed to install $PackageName. Scoop exit code: $installExitCode"
    }
}

write-Host "Checking for Scoop installation..." -ForegroundColor Cyan

if (Test-Tool -CommandName "scoop") {
    Write-Host "Scoop is already installed." -ForegroundColor Green
}
else {
    while ($true) {
        $baseDirectory = Read-Host "Enter the Scoop base directory, for example D:\"

        if ([string]::IsNullOrWhiteSpace($baseDirectory)) {
            Write-Host "The Scoop base directory cannot be empty." -ForegroundColor Red
            continue
        }
        
        $baseDirectory = $baseDirectory.Trim()

        if ($baseDirectory -notmatch '^[A-Za-z]:[\\/](?:.*)?$') {
            Write-Host "Enter a full local path, for example D:\" -ForegroundColor Red
            continue
        }

        break
    }

    # install Directory
    $installRoot = Join-Path $baseDirectory "Scoop"
    $globalInstallRoot = Join-Path $baseDirectory "ScoopGlobal"

    Write-Host "User Scoop will be installed in: $installRoot" -ForegroundColor Yellow
    Write-Host "Global Scoop will be installed in: $globalInstallRoot" -ForegroundColor Yellow

    # Use a unique temporary file so concurrent runs do not interfere.
    $installerFileName = "scoop-install-{0}.ps1" -f [guid]::NewGuid().ToString("N")
    $installerPath = Join-Path $env:TEMP $installerFileName
    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol

    try {
        # Older Windows PowerShell installations may not enable TLS 1.2 by default.
        [Net.ServicePointManager]::SecurityProtocol = `
            $originalSecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        Invoke-RestMethod `
            -Uri "https://get.scoop.sh" `
            -OutFile $installerPath

        & powershell.exe `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $installerPath `
            -ScoopDir $installRoot `
            -ScoopGlobalDir $globalInstallRoot

        $scoopInstallExitCode = $LASTEXITCODE

        if ($scoopInstallExitCode -ne 0) {
            throw "Scoop installation failed. Exit code: $scoopInstallExitCode"
        }
    }
    finally {
        Remove-Item `
            -LiteralPath $installerPath `
            -Force `
            -ErrorAction SilentlyContinue

        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
    }

    $env:Path = "$installRoot\shims;$env:Path"
    Write-Host "Scoop installation completed." -ForegroundColor Green
}

Write-Host "Checking for Python installation..." -ForegroundColor Cyan

if (Test-Tool -CommandName "python") {
    Write-Host "Python is already installed." -ForegroundColor Green
}
else {
    Install-ScoopPackage -PackageName "python"
}

Write-Host "Checking for uv installation..." -ForegroundColor Cyan

if (Test-Tool -CommandName "uv") {
    Write-Host "uv is already installed." -ForegroundColor Green
}
else {
    Install-ScoopPackage -PackageName "uv"
}

Write-Host "Checking for git installation..." -ForegroundColor Cyan

if (Test-Tool -CommandName "git") {
    Write-Host "git is already installed." -ForegroundColor Green
}
else {
    Install-ScoopPackage -PackageName "git"
}

Write-Host "Checking for installation results..." -ForegroundColor Cyan

$pythonInstalled = Test-Tool -CommandName "python"
$uvInstalled = Test-Tool -CommandName "uv"
$gitInstalled = Test-Tool -CommandName "git"

$failedTools = @()

if (-not $pythonInstalled) {
    Write-Host "Python installation failed." -ForegroundColor Red
    $failedTools += "Python"
}

if (-not $uvInstalled) {
    Write-Host "uv installation failed." -ForegroundColor Red
    $failedTools += "uv"
}

if (-not $gitInstalled) {
    Write-Host "git installation failed." -ForegroundColor Red
    $failedTools += "git"
}

if ($failedTools.Count -gt 0) {
    Write-Host "Installation verification failed: $($failedTools -join ', ')" `
        -ForegroundColor Red
    exit 1
}

Write-Host "All installations completed successfully." -ForegroundColor Green
exit 0

