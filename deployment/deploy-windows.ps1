<#
.SYNOPSIS
    Script de déploiement automatique de RustDesk pour Windows
.DESCRIPTION
    Télécharge, installe et configure automatiquement RustDesk avec votre serveur personnalisé
.PARAMETER ServerDomain
    Le domaine ou l'IP de votre serveur RustDesk (ex: rustdesk.bh-systems.be ou localhost)
.PARAMETER PublicKey
    La clé publique de votre serveur RustDesk
.PARAMETER Environment
    Environnement: 'dev' (localhost) ou 'prod' (domaine public)
.EXAMPLE
    .\deploy-windows.ps1 -Environment dev
    .\deploy-windows.ps1 -ServerDomain "rustdesk.bh-systems.be" -PublicKey "votre_cle_publique" -Environment prod
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerDomain,
    
    [Parameter(Mandatory=$false)]
    [string]$PublicKey,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'prod')]
    [string]$Environment
)

# Configuration selon l'environnement
if ($Environment -eq 'dev') {
    $ServerDomain = "localhost"
    $PublicKey = "zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE="
    Write-Host "Mode DÉVELOPPEMENT - Serveur: $ServerDomain" -ForegroundColor Yellow
} else {
    if (-not $ServerDomain -or -not $PublicKey) {
        Write-Host "ERREUR: ServerDomain et PublicKey sont requis en mode production" -ForegroundColor Red
        exit 1
    }
    Write-Host "Mode PRODUCTION - Serveur: $ServerDomain" -ForegroundColor Green
}

# Vérifier les privilèges administrateur
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script nécessite des privilèges administrateur. Relancez en tant qu'administrateur." -ForegroundColor Red
    exit 1
}

# URLs de téléchargement RustDesk
$RustDeskUrl = "https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-x86_64.exe"
$TempPath = "$env:TEMP\rustdesk-installer.exe"
$InstallPath = "$env:ProgramFiles\RustDesk"

Write-Host "=== Déploiement RustDesk pour Windows ===" -ForegroundColor Cyan
Write-Host ""

# Étape 1: Vérifier si RustDesk est déjà installé
Write-Host "[1/5] Vérification de l'installation existante..." -ForegroundColor Yellow
$RustDeskInstalled = Test-Path "$InstallPath\rustdesk.exe"

if ($RustDeskInstalled) {
    Write-Host "RustDesk est déjà installé. Arrêt du service..." -ForegroundColor Yellow
    Stop-Service -Name "RustDesk" -ErrorAction SilentlyContinue
    Stop-Process -Name "rustdesk" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} else {
    Write-Host "RustDesk n'est pas installé. Installation en cours..." -ForegroundColor Green
}

# Étape 2: Télécharger RustDesk
Write-Host "[2/5] Téléchargement de RustDesk..." -ForegroundColor Yellow
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $RustDeskUrl -OutFile $TempPath -UseBasicParsing
    Write-Host "Téléchargement terminé." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du téléchargement: $_" -ForegroundColor Red
    exit 1
}

# Étape 3: Installer RustDesk
Write-Host "[3/5] Installation de RustDesk..." -ForegroundColor Yellow
try {
    Start-Process -FilePath $TempPath -ArgumentList "--silent-install" -Wait -NoNewWindow
    Write-Host "Installation terminée." -ForegroundColor Green
    Start-Sleep -Seconds 3
} catch {
    Write-Host "Erreur lors de l'installation: $_" -ForegroundColor Red
    exit 1
}

# Étape 4: Configuration du serveur personnalisé
Write-Host "[4/5] Configuration du serveur personnalisé..." -ForegroundColor Yellow

# Chemin du fichier de configuration RustDesk
$ConfigPath = "$env:AppData\RustDesk\config"
$ConfigFile = "$ConfigPath\RustDesk2.toml"

# Créer le dossier de configuration s'il n'existe pas
if (-not (Test-Path $ConfigPath)) {
    New-Item -ItemType Directory -Path $ConfigPath -Force | Out-Null
}

# Créer le fichier de configuration
$ConfigContent = @"
# RustDesk Configuration
# Généré automatiquement par le script de déploiement

# Serveur ID/Rendezvous
id_server = "$ServerDomain"
relay_server = "$ServerDomain"

# Clé publique du serveur
key = "$PublicKey"

# API Server (optionnel)
api_server = "http://$ServerDomain/api"

# Options de connexion
auto_connect = false
"@

Set-Content -Path $ConfigFile -Value $ConfigContent -Encoding UTF8
Write-Host "Configuration enregistrée dans: $ConfigFile" -ForegroundColor Green

# Configuration alternative via registre (plus fiable pour certaines versions)
Write-Host "Configuration via registre..." -ForegroundColor Yellow
$RegistryPath = "HKLM:\SOFTWARE\RustDesk"

if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}

Set-ItemProperty -Path $RegistryPath -Name "id_server" -Value $ServerDomain -Type String
Set-ItemProperty -Path $RegistryPath -Name "relay_server" -Value $ServerDomain -Type String
Set-ItemProperty -Path $RegistryPath -Name "key" -Value $PublicKey -Type String

Write-Host "Configuration via registre terminée." -ForegroundColor Green

# Étape 5: Démarrer RustDesk
Write-Host "[5/5] Démarrage de RustDesk..." -ForegroundColor Yellow

# Démarrer le service RustDesk
Start-Service -Name "RustDesk" -ErrorAction SilentlyContinue

# Démarrer l'application RustDesk
Start-Sleep -Seconds 2
Start-Process "$InstallPath\rustdesk.exe" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Installation terminée avec succès ! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  - Serveur ID: $ServerDomain" -ForegroundColor White
Write-Host "  - Serveur Relay: $ServerDomain" -ForegroundColor White
Write-Host "  - Clé publique: $PublicKey" -ForegroundColor White
Write-Host ""
Write-Host "RustDesk devrait maintenant être lancé." -ForegroundColor Green
Write-Host "Vérifiez que la connexion au serveur est établie dans l'interface RustDesk." -ForegroundColor Yellow
Write-Host ""

# Nettoyage
Remove-Item $TempPath -Force -ErrorAction SilentlyContinue

# Afficher l'ID de la machine (si disponible)
Write-Host "Pour obtenir l'ID de cette machine, ouvrez RustDesk." -ForegroundColor Cyan
Write-Host "L'ID sera affiché dans la fenêtre principale." -ForegroundColor Cyan
