 # Self-elevate Powershell instance
 # Get the ID and security principal of the current user account
 $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
 $myWindowsPrincipal=New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
 # Get the security principal for the Administrator role
 $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
 # Check to see if we are currently running "as Administrator"
 if ($myWindowsPrincipal.IsInRole($adminRole))
    {
    # We are running "as Administrator" - so change the title and background color to indicate this
    $Host.UI.RawUI.WindowTitle = "[Admin] SuperNetfix"
    $Host.UI.RawUI.BackgroundColor = "Navy"
    Clear-Host
    }
 else
    {
    # We are not running "as Administrator" - so relaunch as administrator
    # Create a new process object that starts PowerShell
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
    
    # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    
    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";
    
    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);
    
    # Exit from the current, unelevated, process
    exit
    }

#Allow scripts to run on the system
Set-ExeuctionPolicy Unrestricted

Write-Host "[ Welcome to SuperNetfix! ]`n" -ForegroundColor Yellow
Start-Sleep -m 500
Write-Host "This script will perform the following operations.`n" -ForegroundColor Yellow
Start-Sleep -m 500
Write-Host "1. Uninstall all non-miniport system network adapters." -ForegroundColor Yellow
Write-Host "2. Remove all drivers associates with said adapters." -ForegroundColor Yellow
Write-Host "3. Reset all IP configuration values." -ForegroundColor Yellow
Write-Host "4. Reset all network shell values." -ForegroundColor Yellow
Write-Host "5. Scan for hardware changes to find network hardware." -ForegroundColor Yellow
Write-Host "6. Restart the machine after input." -ForegroundColor Yellow
Write-Host "7. Run a network check and log results." -ForegroundColor Yellow
Write-Host "8. List all available network adapters and log them.`n" -ForegroundColor Yellow

For ($i=1; $i -le 50; $i++) {Start-Sleep -m 25; Write-Host -NoNewLine  -ForegroundColor Yellow "."}

Write-Host "`n`nThese changes cannot be rolled back.`nDo you wish to proceed? [y/N] " -NoNewLine -ForegroundColor DarkRed
$continue = Read-Host

if(!(($continue -eq "Y") -or ($continue -eq "y"))) { Write-Host "`nScript terminated per user request.`n" -ForegroundColor Yellow; pause; exit }

#1/2. Uninstall non-miniport networking adapters
Write-Host "`n1/2. Removing all non-miniport networking adapters and their drivers...`n" -ForegroundColor Yellow
Get-NetAdapter -ifIndex $ | Get-NetIPAddress | Remove-NetIPAddress 

#3. Reset ipconfig values
Write-Host "`n3. Resetting all IP configurations...`n" -ForegroundColor Yellow
ipconfig /release
ipconfig /flushdns
ipconfig /renew

#4. Reset network shell
Write-Host "`n4. Resetting netwrok shell values...`n" -ForegroundColor Yellow
netsh int ip reset
netsh winsock reset

#5. Scan for network hardware
Write-Host "`n5. Scanning for hardware changes...`n" -ForegroundColor Yellow
pnputil.exe /scan-devices

#Register the exit program for restart (will fufill objectives 7 and 8)
#The restart log script will self destruct after it completes.
$startupPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\SNFreporting.ps1"
"Write-Host '7. Running TCP/IP Link Test...' -ForegroundColor Yellow; Write-Host" | Out-File -FilePath $startupPath
Add-Content -Path $startupPath -Value "Test-NetConnection -Port 80 -InformationLevel 'Detailed'"
Add-Content -Path $startupPath -Value "Write-Host '8. Finding all available networking devices...' -ForegroundColor Yellow -NoNewLine"
Add-Content -Path $startupPath -Value "Get-NetAdapter -Name * | Format-List -Property Name, InterfaceDescription, HardwareInterface, LinkSpeed, Status, DriverInformation, DriverFileName"
Add-Content -Path $startupPath -Value "Set-ExeuctionPolicy Default"
Add-Content -Path $startupPath -Value "Write-Host 'Script completed successfully! See testing information above to see results.' -ForegroundColor Green; Write-Host; pause; Remove-Item -Path $startupPath"

#6. THIS MUST BE PERFORMED AFTER 7/8 DUE TO RESTART CONFIGURATION
Write-Host "`n6. Restart script injected. Press the return/enter key three times to reboot.`n" -ForegroundColor Green
Read-Host; Write-Host "System " -NoNewLine -ForegroundColor Green; Read-Host; Write-Host "will " -NoNewLine -ForegroundColor Yellow; Read-Host;
Write-Host "reboot." -ForegroundColor Magenta; Start-Sleep -m 500;
Shutdown /r /t 0 /f

Exit
