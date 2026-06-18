# LEGACY installer -- targets the older, legacy-path Millennium (v2.36.4) that
# uses <Steam>\plugins and <Steam>\ext\config.json, paired with the Python
# (legacy) Luatools plugin from madoiscool/ltsteamplugin.
#
# Differences vs. install-plugin.ps1 (the normal/new installer):
#   - Millennium comes from ps.lua.tools/millennium-py.ps1 (pinned v2.36.4)
#   - Plugin installs into <Steam>\plugins  (NOT <Steam>\millennium\plugins)
#   - Config written to <Steam>\ext\config.json
#   - Millennium auto-updates are forced OFF (so it won't upgrade to 3+ and
#     migrate everything off the legacy path)
#   - Plugin source is the Python repo (madoiscool/ltsteamplugin)
#
# Configuration -- edit these before running, or override via env vars:
#   $env:LT_DOWNLOAD_LINK, $env:LT_PLUGIN_NAME, $env:LT_BRANCH, $env:LT_CULTURE
$Script:DownloadLink = $env:LT_DOWNLOAD_LINK
$Script:PluginName   = $env:LT_PLUGIN_NAME
$Script:Branch       = if ($env:LT_BRANCH) { [int]$env:LT_BRANCH } else { 1 }
$Script:Culture      = $env:LT_CULTURE
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # fix SSL/TSL Error
$Script:ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$null = chcp 65001
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Net.Http

# ---------------------------------------------------------------------------
# Locale defaults
# ---------------------------------------------------------------------------
function Get-DefaultStrings {
    param([string]$Culture)

    $tables = @{
        "en" = @{
            Title                 = "Luatools plugin installer (legacy) | .gg/luatools"
            SteamRegNotFound      = "Steam registry key not found. Is Steam installed?"
            SteamKilling          = "Stopping Steam"
            SteamKilled           = "Steam stopped"
            SteamtoolsFound       = "Steamtools already installed"
            SteamtoolsNotFound    = "Steamtools not found"
            SteamtoolsInstalling  = "Installing Steamtools"
            SteamtoolsInstalled   = "Steamtools installed"
            SteamtoolsRetrying    = "Steamtools installation failed, retrying..."
            SteamtoolsFailed      = "Steamtools installation failed after 5 attempts"
            MillenniumNotFound    = "Millennium not found"
            MillenniumCountdown   = "Millennium will be installed in {0} second(s)... Press any key to cancel"
            MillenniumCancelled   = "Installation cancelled by user"
            MillenniumInstalling  = "Installing Millennium (legacy)"
            MillenniumInstalled   = "Millennium installed"
            MillenniumAlready     = "Millennium already installed"
            MillenniumFirstBoot   = "Steam startup may be slower on first boot -- let it sit."
            PluginUpdating        = "Plugin already installed, updating"
            PluginDuplicates      = "Multiple conflicting copies found, cleaning up and reinstalling"
            PluginDownloading     = "Downloading {0}"
            PluginDownloadFailed  = "Failed to download {0}"
            PluginExtracting      = "Extracting {0}"
            PluginExtractFailed   = "Extraction failed, trying built-in Expand-Archive"
            PluginInstalled       = "{0} installed"
            PluginEnabled         = "Plugin enabled"
            RemovingBeta          = "Cleaning up beta flag"
            RemovingCfg           = "Cleaning up steam.cfg"
            RemovingFlags         = "Cleaning up ForceX86 flags and offline mode"
            StartingSteam         = "Starting Steam"
            UpdateCheckDisabled   = "Millennium auto-updates disabled (keeps you on the legacy version)."
            UpdateCheckManual     = "Check for Millennium updates manually if you want the latest."

            ErrorTitle            = "Luatools installer - ERROR"
            ErrorHeader           = "AN ERROR OCCURRED"
            ErrorBody             = "The Luatools plugin installer encountered a problem and could not complete. This is often caused by your ISP blocking the download servers we use."
            ErrorFaq              = "Visit the server (.gg/luatools) for more information & fixes."
            ErrorExit             = "Press any key to exit."
        }

        "pt-BR" = @{
            Title                 = "Instalador do Luatools (legado) | .gg/luatools"
            SteamRegNotFound      = "Steam não encontrada no registro. Sua Steam ta instalada?"
            SteamKilling          = "Parando a Steam"
            SteamKilled           = "Steam Encerrada"
            SteamtoolsFound       = "Steamtools ja instalado"
            SteamtoolsNotFound    = "Steamtools não encontrado"
            SteamtoolsInstalling  = "Instalando Steamtools"
            SteamtoolsInstalled   = "Steamtools instalado"
            SteamtoolsRetrying    = "Falha ao instalar Steamtools, tentando denovo..."
            SteamtoolsFailed      = "Falha ao instalar Steamtools após 5 tentativas"
            MillenniumNotFound    = "Millennium não encontrado"
            MillenniumCountdown   = "Millennium vai ser instalado em {0} segundo(s)... Aperte qualquer tecla pra cancelar"
            MillenniumCancelled   = "Instalação cancelada pelo usuário"
            MillenniumInstalling  = "Instalando Millennium (legado)"
            MillenniumInstalled   = "Millennium instalado"
            MillenniumAlready     = "O Millennium ja está instalado"
            MillenniumFirstBoot   = "A Steam pode demorar um pouco pra abrir pela primeira vez -- deixa rolar."
            PluginUpdating        = "Plugin já instalado, atualizando"
            PluginDuplicates      = "Várias cópias conflitantes encontradas, limpando e reinstalando"
            PluginDownloading     = "Baixando {0}"
            PluginDownloadFailed  = "Falha ao baixar {0}"
            PluginExtracting      = "Extraindo {0}"
            PluginExtractFailed   = "Falha ao extrair, tentando via Expand-Archive"
            PluginInstalled       = "{0} instalado"
            PluginEnabled         = "Plugin habilitado"
            RemovingBeta          = "Limpando flag de beta da Steam"
            RemovingCfg           = "Apagando steam.cfg"
            RemovingFlags         = "Limpando flags do ForceX86 e o modo offline"
            StartingSteam         = "Abrindo a Steam"
            UpdateCheckDisabled   = "Atualizações automáticas do Millennium desabilitadas (mantém você na versão legada)"
            UpdateCheckManual     = "Verifique manualmente por atualizações do Millennium caso você queira a ultima versão"

            ErrorTitle            = "Instalador do Luatools - ERRO"
            ErrorHeader           = "OCORREU UM ERRO"
            ErrorBody             = "O instalador do Luatools encontrou um problema e não pôde ser concluído. Isso geralmente é causado pela tua internet bloqueando nossos servidores de Download"
            ErrorFaq              = "Visite o servidor (.gg/luatools) pra mais informações e detalhes em como consertar"
            ErrorExit             = "Aperte qualquer botão pra sair."
        }

        "es" = @{
            Title                 = "Instalador del plugin de Luatools (legado) | .gg/luatools"
            SteamRegNotFound      = "La clave de registro de Steam no se ha encontrado. Está Steam instalado?"
            SteamKilling          = "Deteniendo Steam"
            SteamKilled           = "Steam se ha detenido"
            SteamtoolsFound       = "Steamtools ya está instalado"
            SteamtoolsNotFound    = "Steamtools no se ha encontrado"
            SteamtoolsInstalling  = "Instalando Steamtools"
            SteamtoolsInstalled   = "Steamtools se ha instalado"
            SteamtoolsRetrying    = "La instalación de Steamtools ha fallado, reintentando..."
            SteamtoolsFailed      = "La instalación de Steamtools ha fallado despues de 5 intentos"
            MillenniumNotFound    = "Millenium no encontrado"
            MillenniumCountdown   = "Millenium sera instalado en {0} segundo(s) ... Presiona cualquier tecla para cancelar"
            MillenniumCancelled   = "Instalación cancelada por el usuario"
            MillenniumInstalling  = "Instalando Millenium (legado)"
            MillenniumInstalled   = "Millenium instalado"
            MillenniumAlready     = "Millenium ya estaba instalado"
            MillenniumFirstBoot   = "La carga de steam puede ser más lenta la primera vez para cargar las dependencias -- espera pacientemente"
            PluginUpdating        = "El plugin ya esta instalado, actualizando"
            PluginDuplicates      = "Se encontraron varias copias en conflicto, limpiando y reinstalando"
            PluginDownloading     = "Descargando {0}"
            PluginDownloadFailed  = "Error al descargar {0}"
            PluginExtracting      = "Extrayendo {0}"
            PluginExtractFailed   = "Extracción fallida, intentando descomprimir archivos"
            PluginInstalled       = "{0} instalado"
            PluginEnabled         = "Plugin establecido"
            RemovingBeta          = "Limpiando indicador beta"
            RemovingCfg           = "Limpiando steam.cfg"
            RemovingFlags         = "Limpiando flags de ForceX86 y el modo sin conexión"
            StartingSteam         = "Iniciando Steam"
            UpdateCheckDisabled   = "Las auto-actualizaciones de Millenium están deshabilitadas (te mantiene en la versión legada)"
            UpdateCheckManual     = "Comprueba las actualizaciones de Millenium manualmente si necesitas la última versión"

            ErrorTitle            = "Error con el instalador Luatools - ERROR"
            ErrorHeader           = "UN ERROR HA OCURRIDO"
            ErrorBody             = "El instalador del plugin Luatools encontró un problema y no pudo completarse. Esto suele ocurrir cuando tu proveedor de internet (ISP) bloquea los servidores de descarga que utilizamos."
            ErrorFaq              = "Visita el servidor (.gg/luatools) para mas información o fixes."
            ErrorExit             = "Presiona cualquier tecla para salir."
        }

        "fr" = @{
            Title                 = "Installateur du plugin Luatools (legacy) | .gg/luatools"
            SteamRegNotFound      = "Clé de registre steam introuvable. Est ce que Steam est installé?"
            SteamKilling          = "Arrêt de Steam"
            SteamKilled           = "Steam arreté"
            SteamtoolsFound       = "Steamtools déjà installé"
            SteamtoolsNotFound    = "Steamtools introuvable"
            SteamtoolsInstalling  = "Installation de Steamtools"
            SteamtoolsInstalled   = "Steamtools installé"
            SteamtoolsRetrying    = "L'instalation de Steamtools a echoué, nouvelle tentative..."
            SteamtoolsFailed      = "L'installation de Steamtools a echoué apres 5 tentatives"
            MillenniumNotFound    = "Millennium introuvable"
            MillenniumCountdown   = "Millennium sera installé dans {0} seconde(s)... Appuyez sur une touche pour annuler"
            MillenniumCancelled   = "Installation annuléee par l'utilisateur"
            MillenniumInstalling  = "Installation de Millennium (legacy)"
            MillenniumInstalled   = "Millennium installé"
            MillenniumAlready     = "Millennium déjà installé"
            MillenniumFirstBoot   = "Le prochain lancement de Steam sera plus long -- laisser le temps."
            PluginUpdating        = "Plugin déjà installé, mise à jour"
            PluginDuplicates      = "Plusieurs copies en conflit trouvées, nettoyage et réinstallation"
            PluginDownloading     = "Installation {0}"
            PluginDownloadFailed  = "Echec de l'installation {0}"
            PluginExtracting      = "Extraction {0}"
            PluginExtractFailed   = "Extraction echouée, tentative avec la fonction native"
            PluginInstalled       = "{0} installé"
            PluginEnabled         = "Plugin activé"
            RemovingBeta          = "Nettoyage de la beta"
            RemovingCfg           = "Nettoyage de steam.cfg"
            RemovingFlags         = "Nettoyage des flags ForceX86 et du mode hors ligne"
            StartingSteam         = "Lancement de Steam"
            UpdateCheckDisabled   = "Les mises à jour de Millennium ont été désactivée (vous garde sur la version legacy)."
            UpdateCheckManual     = "Vérifiez manuellement les mises à jour de Millennium si vous souhaitez la derniere version."

            ErrorTitle            = "Installateur Luatools - ERREUR"
            ErrorHeader           = "UNE ERREUR EST SURVENUE"
            ErrorBody             = "L'installation du plugin Luatools a rencontré un problème et n'a pas pu se terminer. Ça se produit souvent quand votre fournisseur d'internet (ISP) bloque les serveurs de téléchargement."
            ErrorFaq              = "Allez voir le serveur (.gg/luatools) pour plus d'informations & corrections."
            ErrorExit             = "Appuyez sur une touche pour quitter."
        }
    }

    foreach ($key in @($Culture, $Culture.Split('-')[0], "en")) {
        if ($tables.ContainsKey($key)) {
            return $tables[$key]
        }
    }
    return $tables["en"]
}

# ---------------------------------------------------------------------------
# Resolve messages based on locale
# ---------------------------------------------------------------------------
$DetectedCulture = if ($Script:Culture) { $Script:Culture } else { [System.Globalization.CultureInfo]::CurrentUICulture.Name }
$L = Get-DefaultStrings -Culture $DetectedCulture

# ---------------------------------------------------------------------------
# Global error trap -- catches ANY terminating error and shows error page
# MUST be placed after $L is populated so error strings are available
# ---------------------------------------------------------------------------
$Script:OriginalErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Stop"

trap {
    $errMsg = $_.Exception.Message

    # Ensure $L has something even if the hashtable failed
    if (-not $L) { $L = Get-DefaultStrings -Culture "en" }

    $host.UI.RawUI.CursorPosition = @{ X=0; Y=0 }
    $errTitle = if ($L.ContainsKey("ErrorTitle")) { $L["ErrorTitle"] } else { "Luatools installer - ERROR" }
    $host.UI.RawUI.WindowTitle = $errTitle
    Clear-Host

    $width = $host.UI.RawUI.WindowSize.Width

    Write-Host ("=" * $width) -ForegroundColor Red
    Write-Host ""

    $header = if ($L.ContainsKey("ErrorHeader")) { $L["ErrorHeader"] } else { "AN ERROR OCCURRED" }
    $pad = [Math]::Max(0, [int](($width - $header.Length) / 2))
    Write-Host (" " * $pad) -NoNewline
    Write-Host $header -ForegroundColor Red -BackgroundColor Black
    Write-Host ""

    $body = if ($L.ContainsKey("ErrorBody")) { $L["ErrorBody"] } else { "The installer encountered a problem." }
    Write-Host $body -ForegroundColor White
    Write-Host ""

    Write-Host ">>> " -NoNewline -ForegroundColor Yellow
    Write-Host $errMsg -ForegroundColor Gray
    Write-Host ""

    $faq = if ($L.ContainsKey("ErrorFaq")) { $L["ErrorFaq"] } else { "Visit (.gg/luatools)" }
    Write-Host $faq -ForegroundColor Cyan
    Write-Host ""

    Write-Host ("=" * $width) -ForegroundColor Red
    Write-Host ""

    $exitMsg = if ($L.ContainsKey("ErrorExit")) { $L["ErrorExit"] } else { "Press any key to exit." }
    Write-Host $exitMsg -ForegroundColor Yellow
    try { $null = [System.Console]::ReadKey($true) } catch {}

    $ErrorActionPreference = $Script:OriginalErrorAction
    break
}

# ---------------------------------------------------------------------------
# Console helpers
# ---------------------------------------------------------------------------
$Host.UI.RawUI.WindowTitle = $L["Title"]

$LogColors = @{
    "OK"   = "Green"
    "INFO" = "Cyan"
    "ERR"  = "Red"
    "WARN" = "Yellow"
    "LOG"  = "Magenta"
    "AUX"  = "DarkGray"
}

function Write-Log {
    param(
        [ValidateSet("OK","INFO","ERR","WARN","LOG","AUX")]
        [string]$Type,
        [string]$Message,
        [switch]$NoNewline
    )
    $color = $LogColors[$Type]
    $ts = Get-Date -Format "HH:mm:ss"
    if ($NoNewline) {
        Write-Host "`r[$ts] " -ForegroundColor Cyan -NoNewline
        Write-Host "[$Type] $Message" -ForegroundColor $color -NoNewline
    } else {
        Write-Host "[$ts] " -ForegroundColor Cyan -NoNewline
        Write-Host "[$Type] $Message" -ForegroundColor $color
    }
}

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
$Script:Name      = "luatools"
$Script:Link      = "https://github.com/piqseu/ltsteamplugin/releases/latest/download/ltsteamplugin.zip"
$MillenniumTimer  = 5

if ($Script:Branch -eq 2) {
    $Script:Name = "steamtools-collection"
    $Script:Link = "https://github.com/clemdotla/steamtools-collection/releases/download/Latest/steamtools-collection.zip"
}
if ($Script:DownloadLink) { $Script:Link = $Script:DownloadLink }
if ($Script:PluginName)   { $Script:Name = $Script:PluginName }

$DisplayName = $Script:Name.Substring(0,1).ToUpper() + $Script:Name.Substring(1).ToLower()

# ---------------------------------------------------------------------------
# Steam path
# ---------------------------------------------------------------------------
function Get-SteamPath {
    $registries = @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )

    foreach ($reg in $registries) {
        if (!(Test-Path $reg)) { continue }

        $path = (Get-ItemProperty -Path $reg -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
        $potentialExe = Join-Path $path "steam.exe"
        if ((Test-Path $path) -and (Test-Path $potentialExe)) {
            return $path
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Steamtools -- REQUIRED, no user choice
# ---------------------------------------------------------------------------
function Test-Steamtools {
    param([string]$SteamPath)
    foreach ($f in @("dwmapi.dll", "xinput1_4.dll")) {
        if (Test-Path (Join-Path $SteamPath $f)) { return $true }
    }
    return $false
}

function Install-Steamtools {
    param([string]$SteamPath)

    Write-Log -Type WARN -Message $L["SteamtoolsInstalling"]

    try {
        # 1. Consultar la API de GitHub para obtener la última versión (latest)
        $apiUrl = "https://api.github.com/repos/OpenSteam001/OpenSteamTool/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

        # 2. Filtrar los assets para encontrar el archivo de lanzamiento estable (ignorando los "-Debug.zip" o el código fuente)
        $asset = $release.assets | Where-Object { $_.name -like "*Release.zip" } | Select-Object -First 1
        
        if (-not $asset) {
            throw "No se encontró el archivo Release.zip en el repositorio."
        }

        $zipPath = Join-Path $SteamPath $asset.name
        
        # 3. Descargar el archivo .zip en la carpeta de Steam
        Write-Log -Type LOG -Message "Descargando $($asset.name)..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -TimeoutSec 60 -UseBasicParsing
        
        if (-not (Test-Path $zipPath)) { throw $L["SteamtoolsFailed"] }

        # 4. Extraer el zip (reemplaza los DLLs directamente en la ruta de Steam)
        Write-Log -Type LOG -Message "Extrayendo archivos de OpenSteamTool..."
        Expand-Archive -Path $zipPath -DestinationPath $SteamPath -Force

        # Limpiar el archivo .zip descargado
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        # 5. Opcional/Recomendado: OpenSteamTool usa la carpeta 'config\lua' para sus scripts en lugar del antiguo 'stplug-in'
        $luaConfigDir = Join-Path $SteamPath "config\lua"
        if (-not (Test-Path $luaConfigDir)) {
            New-Item -Path $luaConfigDir -ItemType Directory -Force | Out-Null
        }

        # 6. Comprobar si se instaló correctamente
        if (Test-Steamtools $SteamPath) {
            Write-Log -Type OK -Message $L["SteamtoolsInstalled"]
            return
        }

        # Si falla el testeo final
        throw $L["SteamtoolsFailed"]
    }
    catch {
        # Si algo falla (descarga, extracción o API rate limit), arrojamos el error
        Write-Log -Type ERR -Message $_.Exception.Message
        throw $L["SteamtoolsFailed"]
    }
}

# ---------------------------------------------------------------------------
# Millennium -- legacy (pinned v2.36.4 via ps.lua.tools/millennium-py.ps1)
# ---------------------------------------------------------------------------
function Test-Millennium {
    param([string]$SteamPath)
    # wsock32.dll is the Millennium proxy DLL dropped at the Steam root by BOTH
    # v2.x and v3.x; millennium.dll / python311.dll only exist on the older v2.x
    # layout. Match on any of them so detection works across versions.
    foreach ($f in @("wsock32.dll", "millennium.dll", "python311.dll")) {
        if (Test-Path -LiteralPath (Join-Path $SteamPath $f)) { return $true }
    }
    return $false
}

function Install-Millennium {
    param([string]$SteamPath)

    Write-Log -Type INFO -Message $L["MillenniumInstalling"]
    $msCode = @'
param(
    [switch]$NoLog,
    [switch]$NoWarn,
    [switch]$DontStart,
    [string]$SteamPath,
    [string]$Version = "v2.36.4"
)

if (!$NoLog) { $Host.UI.RawUI.WindowTitle = "Millennium installer | clem.la" }

Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Log {
    param ([string]$Type, [string]$Message, [boolean]$NoNewline = $false)

    if ($NoLog) {
        return
    }

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

    Write-Host [$Type] $Message -ForegroundColor $foreground -NoNewline:$NoNewline
}

function GetSteam {
    $steam = $null

    if ($SteamPath -and (Test-Path $SteamPath) -and (Test-Path (Join-Path $SteamPath "steam.exe"))) {
        $steam = $SteamPath
    } else {
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
    }

    if (!$steam) {
        Log "ERR" "Steam not found..."
        exit
    }

    Log "OK" "Steam found $steam"
    return $steam
}
function GetTemp {
    if (-not $env:TEMP -or -not (Test-Path $env:TEMP)) {
        if ($env:LOCALAPPDATA -and (Test-Path $env:LOCALAPPDATA)) {
            $env:TEMP = Join-Path $env:LOCALAPPDATA "Temp"
        }
        if (-not $env:TEMP -or -not (Test-Path $env:TEMP)) {
            $env:TEMP = Join-Path $root "temp"
        }
    }

    if (-not (Test-Path $env:TEMP)) {
        New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
    }

    return $env:TEMP
}


$steam = GetSteam
$temp = GetTemp

function FetchGithub() {
    param( [string]$ver ) 

    if ($ver) {
        $api = "tags/$($ver.Trim())"
    } else {
        $api = "latest"
    }

    function Failed() {
        if ($ver) {
            Log "ERR" "No download link found for version $ver"
            Log "AUX" "Fallback to latest version"
            return FetchGithub
        }

        Log "ERR" "No download link found"
        exit
    }

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
        
                Log "OK" "Found download link"
                break
            }
        }
        if (!$datas -or !$datas.link) {
            return Failed
        }
    } catch {
        return Failed
    }


    return $datas
}
function DownloadArchive() {
    # Download into the Steam folder (clean ASCII path) instead of %TEMP%, which
    # breaks on usernames with spaces/non-ASCII chars (8.3 short paths).
    $downloadPath = Join-Path $steam "millennium.zip"
    Log "LOG" "Downloading the archive"
    
    
    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0")
    
    $stream = $client.GetStreamAsync($datas.link).Result
    $fileStream = [System.IO.File]::Create($downloadPath)
    
    $stream.CopyTo($fileStream)
    
    $fileStream.Close()
    $stream.Close()
    $client.Dispose()
    
    $file = Get-Item $downloadPath
    if (
        (Test-Path $downloadPath) -and
        ($file.Length -eq $datas.size) -and
        ((Get-FileHash $file -Algorithm SHA256).Hash -eq $datas.sha)
    ) {
        Log "OK" "Download completed and verified"
    } else {
        Log "ERR" "Download failed"
        exit
    }

    return $downloadPath
}
function TerminateSteam() {
    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if ($steamProcess) {
        Stop-Process -Name "steam" -Force
    }
}
function ExtractArchive() {
    $start = Get-Date

    Log "Log" "Extracting the archive"
    try {
        if (-not (Test-Path $steam)) {
            New-Item -ItemType Directory -Path $steam -Force | Out-Null
        }
        
        $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
        
        foreach ($entry in $zip.Entries) {
            $destinationPath = Join-Path $steam $entry.FullName
            
            if (-not $entry.FullName.EndsWith('/') -and -not $entry.FullName.EndsWith('\')) {
                $parentDir = Split-Path -Path $destinationPath -Parent
                if ($parentDir -and $parentDir.Trim() -ne '') {
                    $pathParts = $parentDir -replace [regex]::Escape($steam), '' -split '[\\/]' | Where-Object { $_ }
                    $currentPath = $steam
                    
                    foreach ($part in $pathParts) {
                        $currentPath = Join-Path $currentPath $part
                        if (Test-Path $currentPath) {
                            $item = Get-Item $currentPath
                            if (-not $item.PSIsContainer) {
                                Remove-Item $currentPath -Force
                            }
                        }
                    }
                    
                    [System.IO.Directory]::CreateDirectory($parentDir) | Out-Null
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true)
                }
            }
        }
        
        $zip.Dispose()
    }
    catch {
        if ($zip) { $zip.Dispose() }
        Log "ERR" "Error while extracting... Falling back to native function"
        Expand-Archive -Path $path -DestinationPath $steam -Force
    }

    $time = ((Get-Date) - $start).TotalSeconds
    Log "OK" "Millennium extracted in $([Math]::Round($time, 1)) seconds"
}

$datas = FetchGithub($Version)
$path = DownloadArchive
TerminateSteam
ExtractArchive

if (Test-Path $path) {
    Remove-Item $path -Force -ErrorAction SilentlyContinue
}

# --------------------

function AddToEnv() {
    $bin = Join-Path -Path $steam -ChildPath "/ext/bin"

    if (-not ($env:PATH -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $bin })) {
        [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$bin", [System.EnvironmentVariableTarget]::User)
    }
}

AddToEnv

if (!$NoLog) { Write-Host } 
Log "OK" "Successfully installed version $($datas.version)"
if (!$NoWarn) { 
    Log "WARN" "Next startup might be longer, don't panic or touch anything!"
}

$exe = Join-Path $steam "steam.exe"
if ((Test-Path $exe) -and (!$DontStart)) {
    Start-Process $exe
} else {
    Log "AUX" "Start steam manually..."
}
'@
    Invoke-Expression "& { $msCode } -NoLog -DontStart -SteamPath '$SteamPath'"

    if (Test-Millennium $SteamPath) {
        Write-Log -Type OK -Message $L["MillenniumInstalled"]
    }
}

# ---------------------------------------------------------------------------
# Plugin install / update -- legacy <Steam>\plugins path
# ---------------------------------------------------------------------------
function Install-Plugin {
    param([string]$SteamPath, [string]$Name, [string]$Link)

    # Legacy Millennium uses <Steam>\plugins and never touches the newer
    # <Steam>\millennium\plugins path, so everything stays here.
    $pluginsDir = Join-Path $SteamPath "plugins"
    if (-not (Test-Path $pluginsDir)) {
        $null = New-Item -Path $pluginsDir -ItemType Directory -Force
    }

    # Find any folder under <Steam>\plugins whose plugin.json declares our
    # plugin name. The folder may be named anything (e.g. a manual install),
    # so we match on the plugin.json "name" field rather than the folder name.
    $found = [System.Collections.Generic.List[string]]::new()
    foreach ($dir in (Get-ChildItem $pluginsDir -Directory -ErrorAction SilentlyContinue)) {
        $j = Join-Path $dir.FullName "plugin.json"
        if (Test-Path $j) {
            try {
                $m = Get-Content $j -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($m.name -eq $Name) { $found.Add($dir.FullName) }
            } catch {}
        }
    }

    $targetDir = Join-Path $pluginsDir $Name
    if ($found.Count -eq 1) {
        # Single existing install -> update it in place (any folder name).
        Write-Log -Type INFO -Message $L["PluginUpdating"]
        $targetDir = $found[0]
    } elseif ($found.Count -gt 1) {
        # Multiple folders claim this plugin name -> remove every copy and
        # reinstall a single canonical folder to avoid a Millennium collision.
        Write-Log -Type WARN -Message $L["PluginDuplicates"]
        foreach ($dup in $found) {
            Remove-Item $dup -Recurse -Force -ErrorAction SilentlyContinue
        }
        $targetDir = Join-Path $pluginsDir $Name
    }

    $zipPath = Join-Path $SteamPath "$Name.zip"

    Write-Log -Type LOG -Message ($L["PluginDownloading"] -f $Name)
    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [System.TimeSpan]::FromSeconds(60)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Luatools Installer)")

    $stream = $client.GetStreamAsync($Link).Result
    $fileStream = [System.IO.File]::Create($zipPath)
    $stream.CopyTo($fileStream)

    $fileStream.Close()
    $stream.Close()
    $client.Dispose()

    if (-not (Test-Path $zipPath)) {
        throw ($L["PluginDownloadFailed"] -f $Name)
    }

    Write-Log -Type LOG -Message ($L["PluginExtracting"] -f $Name)

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        
        $firstLevelItems = $zip.Entries | ForEach-Object { ($_.FullName -split '[\\/]')[0] } | Select-Object -Unique
        $stripFirstLevel = ($firstLevelItems.Count -eq 1)

        foreach ($entry in $zip.Entries) {
            if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) { continue }
            
            if ($stripFirstLevel) {
                $pathParts = $entry.FullName -split '[\\/]'
                if ($pathParts.Count -gt 1) {
                    $subPath = [string]::Join('\', $pathParts[1..($pathParts.Count-1)])
                } else {
                    continue
                }
            } else {
                $subPath = $entry.FullName
            }

            $dest   = Join-Path $targetDir $subPath
            $parent = Split-Path $dest -Parent

            $relParts = $parent.Substring($targetDir.Length).TrimStart('\','/') -split '[\\/]' | Where-Object { $_ }
            $cursor = $targetDir
            foreach ($part in $relParts) {
                $cursor = Join-Path $cursor $part
                if (Test-Path $cursor) {
                    $item = Get-Item $cursor
                    if (-not $item.PSIsContainer) { Remove-Item $cursor -Force }
                }
            }

            $null = [System.IO.Directory]::CreateDirectory($parent)
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
        }
        $zip.Dispose()
    } catch {
        if ($zip) { $zip.Dispose() }
        Write-Log -Type WARN -Message $L["PluginExtractFailed"]
        
        $tempExtract = Join-Path $env:TEMP "lt_extract_$(Get-Random)"
        Expand-Archive -Path $zipPath -DestinationPath $tempExtract -Force
        
        $extractedItems = Get-ChildItem $tempExtract
        if ($extractedItems.Count -eq 1 -and $extractedItems[0].PSIsContainer) {
            # Move the contents of the inner folder to the target dir
            Move-Item -Path "$($extractedItems[0].FullName)\*" -Destination $targetDir -Force
        } else {
            Move-Item -Path "$tempExtract\*" -Destination $targetDir -Force
        }
        Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $zipPath) { Remove-Item $zipPath -ErrorAction SilentlyContinue }
    Write-Log -Type OK -Message ($L["PluginInstalled"] -f $DisplayName)
}

# ---------------------------------------------------------------------------
# Config -- legacy <Steam>\ext\config.json, with updates forced OFF
# ---------------------------------------------------------------------------
function Enable-Plugin {
    param([string]$SteamPath, [string]$Name)

    # Legacy Millennium reads its config from <Steam>\ext\config.json. We also
    # force general.checkForMillenniumUpdates = false so Millennium won't
    # auto-upgrade to 3+ and migrate plugins off the legacy <Steam>\plugins path.
    $configPath = Join-Path $SteamPath "ext\config.json"

    if (-not (Test-Path $configPath)) {
        $config = @{
            general = @{ checkForMillenniumUpdates = $false }
            plugins = @{ enabledPlugins = @($Name) }
        }
        New-Item -Path (Split-Path $configPath) -ItemType Directory -Force | Out-Null
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
    }
    else {
        $config = (Get-Content $configPath -Raw -Encoding UTF8) | ConvertFrom-Json

        # Ensure general.checkForMillenniumUpdates is present and OFF.
        if (-not $config.general) {
            $config | Add-Member -MemberType NoteProperty -Name "general" -Value ([PSCustomObject]@{}) -Force
        }
        $config.general | Add-Member -MemberType NoteProperty -Name "checkForMillenniumUpdates" -Value $false -Force

        # Ensure plugins.enabledPlugins contains our plugin name.
        if (-not $config.plugins) {
            $config | Add-Member -MemberType NoteProperty -Name "plugins" -Value ([PSCustomObject]@{ enabledPlugins = @() }) -Force
        }
        if (-not $config.plugins.enabledPlugins) {
            $config.plugins | Add-Member -MemberType NoteProperty -Name "enabledPlugins" -Value @() -Force
        }

        $pluginsList = @($config.plugins.enabledPlugins)
        if ($pluginsList -notcontains $Name) {
            $pluginsList += $Name
            $config.plugins.enabledPlugins = $pluginsList
        }

        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
    }

    Write-Log -Type OK -Message $L["PluginEnabled"]
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
function Remove-BetaFlag {
    param([string]$SteamPath)
    $beta = Join-Path $SteamPath "package\beta"
    if (Test-Path $beta) {
        Write-Log -Type AUX -Message $L["RemovingBeta"]
        Remove-Item $beta -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Reset-SteamFlags {
    param([string]$SteamPath)
    Write-Log -Type AUX -Message $L["RemovingFlags"]

    # Clear ForceX86 (32-bit) registry flags
    @("HKCU:\Software\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKLM:\SOFTWARE\WOW6432Node\Valve\Steam") | ForEach-Object {
        Remove-ItemProperty -Path $_ -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue
    }

    # Reset Steam offline mode for all accounts (WantsOfflineMode "1" -> "0")
    $loginUsersPath = Join-Path $SteamPath "config\loginusers.vdf"
    if (Test-Path $loginUsersPath) {
        $content = Get-Content -Path $loginUsersPath -Raw
        if ($content -match '"WantsOfflineMode"\s+"1"') {
            $newContent = $content -replace '("WantsOfflineMode"\s+)"1"', '$1"0"'
            Set-Content -Path $loginUsersPath -Value $newContent -Encoding UTF8
        }
    }
}

function Remove-SteamCfg {
    param([string]$SteamPath)
    $cfg = Join-Path $SteamPath "steam.cfg"
    if (Test-Path $cfg) {
        Write-Log -Type AUX -Message $L["RemovingCfg"]
        Remove-Item $cfg -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
function Main {

    $steamPath = Get-SteamPath

    if (-not $steamPath) {
        Write-Log -Type WARN -Message "Steam no está instalado. Descargando SteamSetup..."
        $installer = Join-Path $env:TEMP "SteamSetup.exe"
        $url = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
        
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing

        if (-not (Test-Path $installer)) {
            throw "Error: No se pudo descargar el instalador de Steam."
        }

        Write-Log -Type LOG -Message "Instalando Steam de forma silenciosa..."
        Start-Process -FilePath $installer -ArgumentList "/S" -Wait

        Remove-Item $installer -Force -ErrorAction SilentlyContinue
        Write-Log -Type OK -Message "La instalación de Steam ha finalizado."
        
        $steamPath = Get-SteamPath
        if (-not $steamPath) {
            throw "Error: Steam se instaló pero la ruta sigue sin encontrarse."
        }
    }

    Write-Log -Type INFO -Message $L["SteamKilling"]
    while (Get-Process steam -ErrorAction SilentlyContinue) {
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Milliseconds 500
    }

    if (Test-Steamtools $steamPath) {
        Write-Log -Type INFO -Message $L["SteamtoolsFound"]
    } else {
        Write-Log -Type ERR -Message $L["SteamtoolsNotFound"]
        Install-Steamtools $steamPath
    }

    $millenniumWasInstalled = Test-Millennium $steamPath
    Install-Millennium $steamPath

    Install-Plugin $steamPath $Script:Name $Script:Link

    Remove-BetaFlag $steamPath
    Remove-SteamCfg $steamPath
    Reset-SteamFlags $steamPath

    Enable-Plugin $steamPath $Script:Name

    Write-Host
    if (-not $millenniumWasInstalled) {
        Write-Log -Type WARN -Message $L["MillenniumFirstBoot"]
    }
    Write-Log -Type WARN -Message $L["UpdateCheckDisabled"]

    $luaConfigDir = Join-Path $steamPath "config\lua"
    if (-not (Test-Path $luaConfigDir)) {
        Write-Log -Type AUX -Message "Creando carpeta config\lua"
        New-Item -Path $luaConfigDir -ItemType Directory -Force | Out-Null
    }

    $stplugDir = Join-Path $steamPath "config\stplug-in"
    if (-not (Test-Path $stplugDir)) {
        New-Item -Path $stplugDir -ItemType Directory -Force | Out-Null
    }

    Write-Log -Type AUX -Message "Configurando Sincronizador en segundo plano..."
    $syncScriptPath = Join-Path ([System.Environment]::GetFolderPath("MyDocuments")) ".steam-sync.ps1"
    
    $syncCode = @"
`$origen = '$stplugDir'
`$destino = '$luaConfigDir'

`$watcher = New-Object System.IO.FileSystemWatcher
`$watcher.Path = `$origen
`$watcher.Filter = '*.*'
`$watcher.IncludeSubdirectories = `$true
`$watcher.EnableRaisingEvents = `$true

`$action = {
    `$rutaArchivo = `$Event.SourceEventArgs.FullPath
    `$nombreArchivo = `$Event.SourceEventArgs.Name
    `$rutaDestino = Join-Path `$destino `$nombreArchivo
    
    Start-Sleep -Seconds 1 
    
    `$parentDest = Split-Path `$rutaDestino -Parent
    if (-not (Test-Path `$parentDest)) { New-Item -Path `$parentDest -ItemType Directory -Force | Out-Null }
    
    Copy-Item -Path `$rutaArchivo -Destination `$rutaDestino -Force
}

Register-ObjectEvent `$watcher "Created" -Action `$action

while (`$true) { Start-Sleep -Seconds 5 }
"@

    Set-Content -Path $syncScriptPath -Value $syncCode -Encoding UTF8
    
    try {
        $fileAttr = Get-Item $syncScriptPath
        $fileAttr.Attributes = 'Hidden'
    } catch {}

    $taskAction = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$syncScriptPath`""
    $null = schtasks /create /tn "Sincronizador PowerShell" /tr $taskAction /sc onlogon /f 2>&1
    $null = schtasks /run /tn "Sincronizador PowerShell" 2>&1

    Write-Log -Type INFO -Message $L["StartingSteam"]
    Start-Process (Join-Path $steamPath "steam.exe") -ArgumentList "-clearbeta"
    $ErrorActionPreference = $Script:OriginalErrorAction
}

Main

# By clem
# Waike contributed a lot
# Legacy variant
