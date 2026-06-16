# ===========================================================================
# LUATOOLS LEGACY INSTALLER (Standalone / Unificado)
# ===========================================================================

# 1. Configuración de enlaces y variables
# Cambiamos el link original por el de piqseu como solicitaste
$Script:DownloadLink = if ($env:LT_DOWNLOAD_LINK) { $env:LT_DOWNLOAD_LINK } else { "https://github.com/piqseu/ltsteamplugin/releases/latest/download/ltsteamplugin.zip" }
$Script:PluginName   = if ($env:LT_PLUGIN_NAME) { $env:LT_PLUGIN_NAME } else { "ltsteamplugin" }
$Script:Branch       = if ($env:LT_BRANCH) { [int]$env:LT_BRANCH } else { 1 }
$Script:Culture      = $env:LT_CULTURE
$Script:Version      = "v2.36.4" # Versión Legacy forzada

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # fix SSL/TSL Error
$Script:ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$null = chcp 65001

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Net.Http

# ---------------------------------------------------------------------------
# 2. Locale defaults
# ---------------------------------------------------------------------------
function Get-DefaultStrings {
    param([string]$Culture)

    $tables = @{
        "en" = @{
            PluginDownloading     = "Downloading {0}"
            PluginExtracting      = "Extracting {0}"
            PluginInstalled       = "{0} installed"
            StartingSteam         = "Starting Steam"
        }
        "es" = @{
            PluginDownloading     = "Descargando {0}"
            PluginExtracting      = "Extrayendo {0}"
            PluginInstalled       = "{0} instalado"
            StartingSteam         = "Iniciando Steam"
        }
        # Puedes añadir el resto de traducciones aquí de tu código original...
    }

    foreach ($key in @($Culture, $Culture.Split('-')[0], "en")) {
        if ($tables.ContainsKey($key)) { return $tables[$key] }
    }
    return $tables["en"]
}

$Strings = Get-DefaultStrings -Culture $Script:Culture

# ---------------------------------------------------------------------------
# 3. Funciones integradas de Millennium (anteriormente millennium-py.ps1)
# ---------------------------------------------------------------------------
function Log {
    param ([string]$Type, [string]$Message, [boolean]$NoNewline = $false)
    $Type = $Type.ToUpper()
    switch ($Type) {
        "OK"   { $foreground = "Green" }
        "INFO" { $foreground = "Blue" }
        "ERR"  { $foreground = "Red" }
        "WARN" { $foreground = "Yellow" }
        "LOG"  { $foreground = "Magenta" }
        "AUX"  { $foreground = "DarkGray" }
        default { $foreground = "White" }
    }
    $date = Get-Date -Format "HH:mm:ss"
    $prefix = if ($NoNewline) { "`r[$date] " } else { "[$date] " }
    Write-Host $prefix -ForegroundColor "Cyan" -NoNewline
    Write-Host "[$Type] $Message" -ForegroundColor $foreground -NoNewline:$NoNewline
}

function GetSteam {
    $steam = $null
    $registries = @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )

    foreach ($reg in $registries) {
        if (!(Test-Path $reg)) { continue }
        $path = (Get-ItemProperty -Path $reg -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
        if ($path -and (Test-Path $path) -and (Test-Path (Join-Path $path "steam.exe"))) {
            $steam = $path                
            break
        }
    }

    if (!$steam) {
        Log "ERR" "Steam not found..."
        exit
    }
    Log "OK" "Steam found $steam"
    return $steam
}

function FetchGithub {
    param( [string]$ver ) 
    $api = if ($ver) { "tags/$($ver.Trim())" } else { "latest" }

    try {
        $res = Invoke-RestMethod "https://api.github.com/repos/SteamClientHomebrew/Millennium/releases/$api"
        $datas = $null
        foreach ($asset in $res.assets) {
            if ($asset.name -imatch "windows" -and $asset.name -imatch "zip") {
                $datas = @{
                    link = $asset.browser_download_url
                    version = $res.tag_name
                    size = $asset.size
                    sha = ($asset.digest -replace "sha256:", "").ToUpper()
                }
                Log "OK" "Found download link for Millennium ($ver)"
                break
            }
        }
        if (!$datas -or !$datas.link) { throw "No link" }
        return $datas
    } catch {
        Log "ERR" "No download link found for version $ver"
        exit
    }
}

function DownloadArchive {
    $downloadPath = Join-Path $steam "millennium.zip"
    Log "LOG" "Downloading Millennium archive"
    
    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0")
    
    $stream = $client.GetStreamAsync($datas.link).Result
    $fileStream = [System.IO.File]::Create($downloadPath)
    
    $stream.CopyTo($fileStream)
    $fileStream.Close()
    $stream.Close()
    $client.Dispose()
    
    $file = Get-Item $downloadPath
    if ((Test-Path $downloadPath) -and ($file.Length -eq $datas.size) -and ((Get-FileHash $file -Algorithm SHA256).Hash -eq $datas.sha)) {
        Log "OK" "Millennium download completed and verified"
    } else {
        Log "ERR" "Download failed"
        exit
    }
    return $downloadPath
}

function TerminateSteam {
    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if ($steamProcess) {
        Log "LOG" "Stopping Steam..."
        Stop-Process -Name "steam" -Force
        Start-Sleep -Seconds 2
    }
}

function ExtractArchive {
    $start = Get-Date
    Log "LOG" "Extracting Millennium archive"
    try {
        if (-not (Test-Path $steam)) { New-Item -ItemType Directory -Path $steam -Force | Out-Null }
        $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
        
        foreach ($entry in $zip.Entries) {
            $destinationPath = Join-Path $steam $entry.FullName
            if (-not $entry.FullName.EndsWith('/') -and -not $entry.FullName.EndsWith('\')) {
                $parentDir = Split-Path -Path $destinationPath -Parent
                if ($parentDir -and $parentDir.Trim() -ne '') {
                    [System.IO.Directory]::CreateDirectory($parentDir) | Out-Null
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true)
                }
            }
        }
        $zip.Dispose()
    }
    catch {
        if ($zip) { $zip.Dispose() }
        Log "WARN" "Error via System.IO.Compression... Falling back to Expand-Archive"
        Expand-Archive -Path $path -DestinationPath $steam -Force
    }

    $time = ((Get-Date) - $start).TotalSeconds
    Log "OK" "Millennium extracted in $([Math]::Round($time, 1)) seconds"
}

function AddToEnv {
    $bin = Join-Path -Path $steam -ChildPath "/ext/bin"
    if (-not ($env:PATH -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $bin })) {
        [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$bin", [System.EnvironmentVariableTarget]::User)
    }
}

# ===========================================================================
# 4. FLUJO DE EJECUCIÓN PRINCIPAL
# ===========================================================================

$steam = GetSteam
TerminateSteam

# --- A) Instalar Millennium ---
$datas = FetchGithub($Script:Version)
$path = DownloadArchive
ExtractArchive

if (Test-Path $path) {
    Remove-Item $path -Force -ErrorAction SilentlyContinue
}
AddToEnv

# --- B) Desactivar Auto-updates de Millennium (Requisito Legacy) ---
Log "LOG" "Disabling Millennium Auto-Updates (Legacy requirement)..."
$configDir = Join-Path $steam "ext"
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
$configPath = Join-Path $configDir "config.json"
$configContent = '{"allow_auto_updates": false}'
Set-Content -Path $configPath -Value $configContent

# --- C) Descargar e Instalar Luatools Plugin (piqseu rep) ---
Log "LOG" ($Strings["PluginDownloading"] -f "Luatools ($Script:PluginName)")

$pluginZipPath = Join-Path $steam "ltsteamplugin.zip"
$pluginsDir = Join-Path $steam "plugins"

if (-not (Test-Path $pluginsDir)) { New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null }

try {
    Invoke-WebRequest -Uri $Script:DownloadLink -OutFile $pluginZipPath -UseBasicParsing
    Log "OK" "Luatools plugin downloaded successfully."
    
    Log "LOG" ($Strings["PluginExtracting"] -f "Luatools")
    Expand-Archive -Path $pluginZipPath -DestinationPath $pluginsDir -Force
    Remove-Item $pluginZipPath -Force -ErrorAction SilentlyContinue

    Log "OK" ($Strings["PluginInstalled"] -f "Luatools")
} catch {
    Log "ERR" "Failed to download or extract Luatools plugin."
}

# --- D) Iniciar Steam ---
Log "OK" "Installation Complete!"
Log "INFO" "Next startup might be longer, don't panic or touch anything!"
Log "LOG" $Strings["StartingSteam"]

$exe = Join-Path $steam "steam.exe"
if (Test-Path $exe) {
    Start-Process $exe
} else {
    Log "WARN" "Please start steam manually."
}
