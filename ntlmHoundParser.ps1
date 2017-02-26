<#
.SYNOPSIS
    NTLMHound is a toolkit for discovering LM and NTLMv1 usage within an Active Directory domain.
.DESCRIPTION
    NTLMHoundParser is a script for preparing a report about NTLM usage based on the data in collected ETW traces (see ntlmHoundLogger.ps1).
.PARAMETER Logpath
    A path to a folder containing collected ETW traces.
.PARAMETER TmfPath
    A path to TMF files. The path could be in UNC format. 
.PARAMETER OutFile
    A path to a report file.
.EXAMPLE
    Parse the collected ETW logs in c:\mylogs using default toolkit TMF files and save the report to ntlmusage.csv
    C:\PS> .\ntlmHoundParser.ps1 -Logpath "c:\mylogs" -TmfPath ".\tmf" -OutFile ".\ntlmusage.csv"
   

.NOTES
    Author: Nikolay Salnikov
    Date:   February 26, 2017
    Version: 1.1
#>
Param(
    [ValidateNotNullOrEmpty()]
    [string]$Logpath = ".\ETL",
    [ValidateNotNullOrEmpty()]
    [string]$TmfPath = ".\tmf",
    [ValidateNotNullOrEmpty()]
    [string]$OutFile = ".\results.csv"

)


New-Item "$Logpath\decoded" -type directory -Force | Out-Null
Get-ChildItem "$Logpath" -Filter *.etl | 
Foreach-Object {
    $fn= $_.FullName
    $rn = $_.Name
    $tracefmt = ".\tracefmt.exe" 
    &$tracefmt $fn -p $TmfPath -o "$Logpath\decoded\$rn.decoded.log" | Out-Null
}

$regex = 'user\s\"(?<user>[\w|\-|\$_.]+)\",\sdomain\s\"(?<domain>[\w|\-|\$_.]+)\",\sworkstation\s\"(?<workstation>[\w|\-|\$_.]+)\",\sNtRespLen\s0x(?<buflen>\w+),\s'

#$content = gc "$Logpath\decoded\*.decoded.log"
#$content |?{$_ -match $regex}|%{$matches['domain']+"\"+$matches['user']+";"+$matches['workstation']+";"+$matches['buflen']} | Sort-Object| Get-Unique | Out-File $OutFile


gc "$Logpath\decoded\*.decoded.log" |?{$_ -match $regex}|%{$matches['domain']+"\"+$matches['user']+";"+$matches['workstation']+";"+$matches['buflen']} | Sort-Object| Get-Unique | Foreach-Object {
        # send the current line to output
        if ($_ -match ";18") 
        {
            #Add LM-NTLMv1 tag
            "$_;LM-or-NTLMv1"
        }
        else {
            #Add NTLMv2 tag
            "$_;NTLMv2"
            }
    } | Out-File $OutFile


Write-Output ("Log processing is completed. Find your report here: $OutFile")