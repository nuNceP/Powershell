#Check if PowerCli module is installed
try {
    Get-InstalledModule -Name VMware.PowerCLI > $null
} catch {
    Install-Module -Name VMware.PowerCLI -AllowClobber
    Set-PowerCLIConfiguration -InvalidCertificateAction Prompt
}

#Connessione a server vCenter
$vCenterIP = Read-Host -Prompt "Indirizzo vCenter"

try {
    Connect-VIServer -Server $vCenterIP > $null
} catch {
    Write-Host "Errore di connessione al server"
    break;
}

#Query snapshot VM
$snapCount = 0
$vmCount = 0

Write-Host "`n"

Get-VM | foreach { $vmCount++; If (Get-Snapshot -VM $_.Name) { $snapCount++; Write-Host $_.Name; Write-Host -ForegroundColor red "|__$((Get-Snapshot -VM $_.Name).Name)"} }

If ($snapCount -eq 0 -and $vmCount -gt 0) {
    Write-Host "`nCHECK SUCCESSFUL - No snapshots found on a total of $vmCount VMs`n"
} else {
    Write-Host "`nFound $snapCount snapshot(s) on a total of $vmCount VMs."
}

#Logoff Server
Disconnect-VIServer -Server $vCenterIP -Confirm:$false