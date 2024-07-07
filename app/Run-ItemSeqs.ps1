<#**************************************************************************************************
Name: Run-ItemSeqs.ps1                 Author: Brendan Furey                       Date: 07-Jul-2024
Component Powershell script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

POWERSHELL SCRIPTS
====================================================================================================
|  Powershell Script        | Description                                                          |
|==================================================================================================|
|  Copy-DataFilesInput.ps1  | Copies England dataset file and unit test JSON file to INPUT folder  |
|  Install-Ico.ps1          | Installation driver script                                           |
|  app\Run-All.ps1          | Runs sqlplus scripts for different solution methods for the          |
|                           | optimization problem, with various combinations of parameters for    |
|                           | each of three datasets                                               |
|  app\Run-Perturb.ps1      | Runs a sqlplus script across a range of maximum prices on all three  |
|                           | datasets, using the fastest solution method                          |
| *app\Run-ItemSeqs.ps1*    | Runs sqlplus scripts for different solution methods for the          |
|                           | sequence generation problem, for the Small dataset only              |
====================================================================================================

This file has the script to run sqlplus scripts for different solution methods for the sequence 
generation problem, for the Small dataset only
**************************************************************************************************#>
Date -format "dd-MMM-yy HH:mm:ss"
$startTime = Get-Date

$directories = Get-ChildItem -Directory | Where-Object { $_.Name -match "^item_seqs_\d+$" }
[int]$maxIndex = 0
if ($directories.Count -gt 0) {
    [int[]]$indexLis = $directories | 
        ForEach-Object {
            $_.Name -replace 'item_seqs_', ''
        }
    $maxIndex = ($indexLis | Measure-Object -Maximum).Maximum
}
$nxtIndex = ($maxIndex + 1).ToString("D2")
$newDir = ('item_seqs_' + $nxtIndex)
New-Item ('item_seqs_' + $nxtIndex) -ItemType Directory

$logFile = $PSScriptRoot + '\Run-ItemSeqs_' + $nxtIndex + '.log'
$inputs = [ordered]@{
    sml = [ordered]@{views_sml           = @()
                     item_seqs_rsf       = @()
                     item_seqs_rsf_cycle = @()
                     item_seqs_rsf_nt    = @()
                     item_seqs_pls       = @(@('MP'),@('MC'),@('SP'),@('SC'))}
}

foreach($i in $inputs.Keys){
    Set-Location $newDir
    $i
    [string]$cmdLis = ''
    foreach($v in $inputs[$i]) {
        foreach($k in $v.Keys) {
            if($v[$k].length -eq 0) {
                $cmdLis += ('@..\' + $k + [Environment]::NewLine)
            }
            foreach($p in $v[$k]) {
                $newCmd = ('@..\' + $k + ' ' + $p[0])
                ("newCmd = " + $newCmd)
                $p
                $cmdLis += ($newCmd + [Environment]::NewLine)
            }
        }
    }
    $cmdLis
    $output = $cmdLis | sqlplus 'app/app@orclpdb'
    $output
    Set-Location ..

}
$elapsedTime = (Get-Date) - $startTime
$roundedTime = [math]::Round($elapsedTime.TotalSeconds)

"Total time taken: $roundedTime seconds" | Out-File $logFile -Append -encoding utf8