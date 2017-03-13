<#
.SYNOPSIS
    NTLMHound is a toolkit for discovering LM and NTLMv1 usage within Active Directory domain.
.DESCRIPTION
    NTLM Hound Logger is a script for NTLM ETW Log collection
.PARAMETER Mode
    Mode for running the script. Possible values:
    1. Enable ETW tracing for a defined timeframe and collect logs
    2. Disable ETW tracing and collect logs
.PARAMETER Timeframe
    Time frame in minutes for collecting ETW logs 
.PARAMETER Logpath
    A path to a location where the resulting ETW logs will be stored.
.EXAMPLE
    Enable NTLM ETW Log collection for 5 minutes and put the resulting logs to c:\ntlmlogs
    C:\PS> .\ntlmHoundLogger.ps1 -Mode 1 -Timeframe 5 -Logpath c:\ntlmlogs
    
    Disable NTLM ETW Log collection 
    C:\PS> .\ntlmHoundLogger.ps1 -Mode 2

.NOTES
    Author: Nikolay Salnikov
    Date:   February 26, 2017
    Version: 1.1
#>


Param(
    [Parameter(HelpMessage="Choose Mode for running the script. 1 - enable ETW tracing, 2 - disable ETW tracing")]
    [ValidateNotNullOrEmpty()]
    [string]$Mode = '1',
    [Parameter(HelpMessage="Time frame in minutes for ETW tracing")]
    [ValidateNotNullOrEmpty()]
    [string]$Timeframe = "1",
    [Parameter(HelpMessage="A file path to a folder where to store the resulting files")]
    [ValidateNotNullOrEmpty()]
    [string]$Logpath = ".\ETL"
)



Function Start-Countdown 
{   
    Param(
        [Int32]$Seconds = 10
    )
    ForEach ($Count in (1..$Seconds))
    {   Write-Progress -Id 1 -Activity "Trace collection is in progress..." -Status "Collecting for $Seconds seconds, $($Seconds - $Count) left" -PercentComplete (($Count / $Seconds) * 100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Id 1 -Activity "Trace collection is in progress..." -Status "Completed" -PercentComplete 100 -Completed
}


function Test-RegistryValue {
param (

 [parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Path,

[parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Value
)

try {
Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
 return $true
 }

catch {
return $false
}

}


#$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
#$regvaluename = "NtLmInfoLevel"
#$regvalue= 0xc0015003
#$collect = "n"

if ($mode -eq "1")
{
Write-Output("Running mode 1: Enable NTLM ETW tracing for $Timeframe minute(s) and save the resulting logs to $Logpath")
}
elseif ($mode -eq "2")
{
Write-Output("Running mode 2: Disable ETW tracing")
}
else
{
Write-Output("Possible options for Mode parameter:")
Write-Output("1. Enable ETW Tracing")
Write-Output("2. Disable ETW Tracing")
}


if ($mode -eq "1")
{
Start-Process -FilePath ".\tracelog.exe" -ArgumentList "-stop ntlm"


while (!(Test-Path $Logpath))
{
Write-Output ("The specified path doesn't exist. A new folder will be created.")
New-Item $Logpath -type directory | Out-Null
}

Write-Output ("Enabling tracing...")
Start-Process -FilePath ".\tracelog.exe" -ArgumentList "-kd -rt -start ntlm -guid #5BBB6C18-AA45-49b1-A15F-085F7ED0AA90 -f $LogPath\ntlm.etl -flags 0x15003 -ft 1"
Write-Output ("Done.")

Write-Output ("Collecting data...")
Start-Countdown(([int]$Timeframe*60).ToString())
Write-Output ("Finished.")

Write-Output ("Disabling tracing...")
Start-Process -FilePath ".\tracelog.exe" -ArgumentList "-stop ntlm"
Write-Output ("Done.")
Write-Output ("Find collected logs here: $Logpath")

}


elseif ($mode -eq "2")
{
Write-Output ("Disabling tracing...")
Start-Process -FilePath ".\tracelog.exe" -ArgumentList "-stop ntlm"
Write-Output ("Done.")
}





