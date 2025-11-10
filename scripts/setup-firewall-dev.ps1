# Script de configuration du firewall Windows pour RustDesk (Développement)
# 
# Ce script ouvre les ports nécessaires pour RustDesk sur le réseau local
# ATTENTION: À utiliser uniquement pour le développement/test local
#
# Exécution: PowerShell en mode Administrateur
# .\setup-firewall-dev.ps1

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Configuration Firewall RustDesk - DEV" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier les privilèges administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERREUR: Ce script doit être exécuté en tant qu'Administrateur" -ForegroundColor Red
    Write-Host ""
    Write-Host "Clic droit sur PowerShell → 'Exécuter en tant qu'administrateur'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Privilèges administrateur détectés" -ForegroundColor Green
Write-Host ""

# Supprimer les anciennes règles RustDesk si elles existent
Write-Host "🔍 Suppression des anciennes règles RustDesk..." -ForegroundColor Yellow
Get-NetFirewallRule -DisplayName "RustDesk*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
Write-Host "✅ Anciennes règles supprimées" -ForegroundColor Green
Write-Host ""

# Créer les nouvelles règles
Write-Host "🔧 Création des règles firewall..." -ForegroundColor Yellow
Write-Host ""

# Port 21115 - NAT Type Test (TCP)
Write-Host "  → Port 21115 (TCP) - NAT Type Test"
New-NetFirewallRule `
    -DisplayName "RustDesk - NAT Test (TCP)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 21115 `
    -Action Allow `
    -Profile Domain,Private,Public `
    -Enabled True | Out-Null

# Port 21116 - ID/Rendezvous Server (TCP)
Write-Host "  → Port 21116 (TCP) - ID Server"
New-NetFirewallRule `
    -DisplayName "RustDesk - ID Server (TCP)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 21116 `
    -Action Allow `
    -Profile Domain,Private,Public `
    -Enabled True | Out-Null

# Port 21116 - ID/Rendezvous Server (UDP)
Write-Host "  → Port 21116 (UDP) - ID Server"
New-NetFirewallRule `
    -DisplayName "RustDesk - ID Server (UDP)" `
    -Direction Inbound `
    -Protocol UDP `
    -LocalPort 21116 `
    -Action Allow `
    -Profile Domain,Private,Public `
    -Enabled True | Out-Null

# Port 21117 - Relay Server (TCP)
Write-Host "  → Port 21117 (TCP) - Relay Server"
New-NetFirewallRule `
    -DisplayName "RustDesk - Relay Server (TCP)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 21117 `
    -Action Allow `
    -Profile Domain,Private,Public `
    -Enabled True | Out-Null

# Port 21118 - WebSocket (TCP)
Write-Host "  → Port 21118 (TCP) - WebSocket"
New-NetFirewallRule `
    -DisplayName "RustDesk - WebSocket 1 (TCP)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 21118 `
    -Action Allow `
    -Profile Domain,Private,Public `
    -Enabled True | Out-Null

# Port 21119 - WebSocket (TCP)
Write-Host "  → Port 21119 (TCP) - WebSocket"
New-NetFirewallRule `
    -DisplayName "RustDesk - WebSocket 2 (TCP)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 21119 `
    -Action Allow `
    -Profile Domain,Private,Public `
    -Enabled True | Out-Null

Write-Host ""
Write-Host "✅ Règles firewall créées avec succès" -ForegroundColor Green
Write-Host ""

# Afficher les règles créées
Write-Host "📋 Règles firewall RustDesk actives:" -ForegroundColor Cyan
Get-NetFirewallRule -DisplayName "RustDesk*" | 
    Select-Object DisplayName, Enabled, Direction, Action | 
    Format-Table -AutoSize

Write-Host ""
Write-Host "🔍 Vérification des ports en écoute..." -ForegroundColor Yellow
$ports = netstat -an | Select-String "21115|21116|21117|21118|21119"
if ($ports) {
    Write-Host "✅ Ports RustDesk actifs:" -ForegroundColor Green
    $ports
} else {
    Write-Host "⚠️  Aucun port RustDesk détecté. Vérifiez que Docker est démarré." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌐 Tester la connexion depuis une autre machine:" -ForegroundColor Cyan
Write-Host ""
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"}).IPAddress | Select-Object -First 1
Write-Host "  Depuis Windows:" -ForegroundColor White
Write-Host "    Test-NetConnection -ComputerName $localIP -Port 21116" -ForegroundColor Gray
Write-Host ""
Write-Host "  Depuis Linux:" -ForegroundColor White
Write-Host "    nc -zv $localIP 21116" -ForegroundColor Gray
Write-Host "    telnet $localIP 21116" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Configuration terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Configuration des clients:" -ForegroundColor Cyan
Write-Host "   ID Server:    $localIP" -ForegroundColor White
Write-Host "   Relay Server: $localIP" -ForegroundColor White
Write-Host "   Key:          zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE=" -ForegroundColor White
Write-Host ""
