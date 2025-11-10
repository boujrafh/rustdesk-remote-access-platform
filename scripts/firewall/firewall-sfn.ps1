<#
.SYNOPSIS
    Script de configuration firewall Windows pour environnement SFN sécurisé
.DESCRIPTION
    Autorise UNIQUEMENT les ports RustDesk nécessaires (21115-21119)
.PARAMETER Action
    Action à effectuer: Enable, Disable, Status, Test
.EXAMPLE
    .\firewall-sfn.ps1 -Action Enable
    .\firewall-sfn.ps1 -Action Status
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Enable','Disable','Status','Test')]
    [string]$Action
)

# Vérifier les privilèges administrateur
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script nécessite des privilèges administrateur." -ForegroundColor Red
    exit 1
}

function Enable-SFNFirewall {
    Write-Host "=== Configuration Firewall SFN ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Sauvegarder la configuration actuelle
    Write-Host "[1/4] Sauvegarde de la configuration actuelle..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    netsh advfirewall export "C:\firewall-backup-$timestamp.wfw" | Out-Null
    Write-Host "Backup créé: C:\firewall-backup-$timestamp.wfw" -ForegroundColor Green
    
    # Supprimer les anciennes règles RustDesk
    Write-Host "[2/4] Nettoyage des règles existantes..." -ForegroundColor Yellow
    Get-NetFirewallRule -DisplayName "RustDesk SFN*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    # Bloquer tout par défaut (optionnel, décommentez si nécessaire)
    # Write-Host "[3/4] Application de la politique par défaut: Block..." -ForegroundColor Yellow
    # Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
    
    # Créer les règles RustDesk
    Write-Host "[3/4] Création des règles RustDesk..." -ForegroundColor Yellow
    
    # hbbs - NAT type test
    New-NetFirewallRule -DisplayName "RustDesk SFN - hbbs NAT Test (21115)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 21115 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "RustDesk hbbs NAT type test" | Out-Null
    
    # hbbs - Registration TCP
    New-NetFirewallRule -DisplayName "RustDesk SFN - hbbs Registration TCP (21116)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 21116 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "RustDesk hbbs ID registration TCP" | Out-Null
    
    # hbbs - Registration UDP
    New-NetFirewallRule -DisplayName "RustDesk SFN - hbbs Registration UDP (21116)" `
        -Direction Inbound `
        -Protocol UDP `
        -LocalPort 21116 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "RustDesk hbbs ID registration UDP" | Out-Null
    
    # hbbr - Relay
    New-NetFirewallRule -DisplayName "RustDesk SFN - hbbr Relay (21117)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 21117 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "RustDesk hbbr relay server" | Out-Null
    
    # hbbs - WebSocket
    New-NetFirewallRule -DisplayName "RustDesk SFN - hbbs WebSocket (21118)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 21118 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "RustDesk hbbs WebSocket" | Out-Null
    
    # hbbr - WebSocket Relay
    New-NetFirewallRule -DisplayName "RustDesk SFN - hbbr WebSocket (21119)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 21119 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "RustDesk hbbr WebSocket relay" | Out-Null
    
    # HTTPS API (optionnel)
    New-NetFirewallRule -DisplayName "RustDesk SFN - API HTTPS (443)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 443 `
        -Action Allow `
        -Profile Domain,Private `
        -Description "RustDesk API HTTPS" | Out-Null
    
    Write-Host "[4/4] Activation des règles..." -ForegroundColor Yellow
    Get-NetFirewallRule -DisplayName "RustDesk SFN*" | Enable-NetFirewallRule
    
    Write-Host ""
    Write-Host "✅ Firewall SFN activé avec succès" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ports autorisés:" -ForegroundColor Cyan
    Write-Host "  - 21115 (TCP) : hbbs NAT test" -ForegroundColor White
    Write-Host "  - 21116 (TCP/UDP) : hbbs registration" -ForegroundColor White
    Write-Host "  - 21117 (TCP) : hbbr relay" -ForegroundColor White
    Write-Host "  - 21118 (TCP) : hbbs WebSocket" -ForegroundColor White
    Write-Host "  - 21119 (TCP) : hbbr WebSocket" -ForegroundColor White
    Write-Host "  - 443 (TCP) : API HTTPS" -ForegroundColor White
}

function Disable-SFNFirewall {
    Write-Host "=== Désactivation Firewall SFN ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Sauvegarder avant suppression
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    netsh advfirewall export "C:\firewall-before-disable-$timestamp.wfw" | Out-Null
    
    # Supprimer toutes les règles RustDesk SFN
    Write-Host "Suppression des règles RustDesk SFN..." -ForegroundColor Yellow
    Get-NetFirewallRule -DisplayName "RustDesk SFN*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    Write-Host ""
    Write-Host "✅ Firewall SFN désactivé" -ForegroundColor Green
    Write-Host "⚠️  ATTENTION: Les ports RustDesk ne sont plus protégés!" -ForegroundColor Red
}

function Show-SFNFirewallStatus {
    Write-Host "=== Statut Firewall SFN ===" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Politique par défaut:" -ForegroundColor Yellow
    Get-NetFirewallProfile | Select-Object Name, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
    
    Write-Host "Règles RustDesk SFN:" -ForegroundColor Yellow
    $rules = Get-NetFirewallRule -DisplayName "RustDesk SFN*" -ErrorAction SilentlyContinue
    
    if ($rules) {
        $rules | ForEach-Object {
            $portFilter = $_ | Get-NetFirewallPortFilter
            [PSCustomObject]@{
                Name = $_.DisplayName
                Enabled = $_.Enabled
                Direction = $_.Direction
                Action = $_.Action
                Protocol = $portFilter.Protocol
                Port = $portFilter.LocalPort
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "Aucune règle RustDesk SFN trouvée" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Ports en écoute (RustDesk):" -ForegroundColor Yellow
    Get-NetTCPConnection -LocalPort 21115,21116,21117,21118,21119,443 -ErrorAction SilentlyContinue | 
        Select-Object LocalAddress, LocalPort, State | 
        Format-Table -AutoSize
}

function Test-SFNFirewall {
    Write-Host "=== Test Firewall SFN ===" -ForegroundColor Cyan
    Write-Host ""
    
    $ports = @(21115, 21116, 21117, 21118, 21119, 443)
    $passed = 0
    $failed = 0
    
    foreach ($port in $ports) {
        $rule = Get-NetFirewallRule -DisplayName "RustDesk SFN*" | 
                Where-Object { ($_ | Get-NetFirewallPortFilter).LocalPort -eq $port } |
                Select-Object -First 1
        
        if ($rule -and $rule.Enabled -eq $true) {
            Write-Host "✅ Port $port : " -NoNewline
            Write-Host "AUTORISÉ" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "❌ Port $port : " -NoNewline
            Write-Host "BLOQUÉ" -ForegroundColor Red
            $failed++
        }
    }
    
    Write-Host ""
    Write-Host "Tests réussis: $passed" -ForegroundColor Green
    Write-Host "Tests échoués: $failed" -ForegroundColor Red
    
    # Test de connectivité locale
    Write-Host ""
    Write-Host "Test de connectivité locale:" -ForegroundColor Yellow
    foreach ($port in $ports) {
        $result = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Write-Host "✅ Port $port : ACCESSIBLE" -ForegroundColor Green
        } else {
            Write-Host "❌ Port $port : NON ACCESSIBLE (service non démarré?)" -ForegroundColor Yellow
        }
    }
}

# Exécution de l'action
switch ($Action) {
    'Enable' {
        Enable-SFNFirewall
    }
    'Disable' {
        Disable-SFNFirewall
    }
    'Status' {
        Show-SFNFirewallStatus
    }
    'Test' {
        Test-SFNFirewall
    }
}
