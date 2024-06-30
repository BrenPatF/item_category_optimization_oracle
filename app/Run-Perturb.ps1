<#**************************************************************************************************
Name: Run-Perturb.ps1                  Author: Brendan Furey                       Date: 30-Jun-2024

Component Powershell script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

POWERSHELL SCRIPTS
====================================================================================================
|  Powershell Script        | Description                                                          |
|==================================================================================================|
|  Copy-DataFilesInput.ps1  | Copies England dataset file and unit test JSON file to INPUT folder  |
|  Install-Ico.ps1          | Installation driver script                                           |
|  app\Run-All.ps1          | Run driver script for different solution methods for the             |
|                           | optimization problem, with various combinations of parameters for    |
|                           | each of three datasets                                               |
| *app\Run-Perturb.ps1*     | Runs a sqlplus script across a range of maximum prices on all three  |
|                           | datasets, using the fastest solution method                          |
====================================================================================================

This file has the script to run a sqlplus script across a range of maximum prices on all three
datasets, using the fastest solution method
**************************************************************************************************#>
Date -format "dd-MMM-yy HH:mm:ss"
$startTime = Get-Date

$directories = Get-ChildItem -Directory | Where-Object { $_.Name -match "^perturb_\d+$" }
[int]$maxIndex = 0
if ($directories.Count -gt 0) {
    [int[]]$indexLis = $directories | 
        ForEach-Object {
            $_.Name -replace 'perturb_', ''
        }
    $maxIndex = ($indexLis | Measure-Object -Maximum).Maximum
}
$nxtIndex = ($maxIndex + 1).ToString("D2")
$newDir = ('perturb_' + $nxtIndex)
New-Item ('perturb_' + $nxtIndex) -ItemType Directory

$logFile = $PSScriptRoot + '\Run-Perturb_' + $nxtIndex + '.log'
$ddl = 'c_temp_tables'
$inputs = [ordered]@{
    sml = [ordered]@{views_sml              = @()
                     item_cat_seqs_perturb  = @(3, 4, 5, 6, 7)}
    bra = [ordered]@{views_bra              = @()
                     item_cat_seqs_perturb  = @(8000, 10000, 12000, 14000, 16000, 18000, 20000, 22000, 24000)}
    eng = [ordered]@{views_eng              = @()
                     item_cat_seqs_perturb  = @(500, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1100)}
}

foreach($i in $inputs.Keys){
    Set-Location $newDir
    $i
    [string]$cmdLis = ('@..\' + $ddl + [Environment]::NewLine)
    $logLis = @()
    foreach($v in $inputs[$i]) {
        foreach($k in $v.Keys) {
            if($v[$k].length -eq 0) {
                $cmdLis += ('@..\' + $k + [Environment]::NewLine)
            }
            foreach($p in $v[$k]) {
                $newCmd = ('@..\' + $k + ' ' + $i + ' ' + $p[0])
                ("newCmd = " + $newCmd)
                $p
                $cmdLis += ($newCmd + [Environment]::NewLine)
                $logLis += ($k + '_' + $i + '_' + $p[0] + '.log')
            }
        }
    }
    $cmdLis
    $output = $cmdLis | sqlplus 'app/app@orclpdb'
#    $output
    Set-Location ..

    foreach($l in $logLis) {
        $f = $newDir + '\' + $l
        $l | Out-File $logFile -Append -encoding utf8
        Get-Content $f | Select-String -Pattern '; Prices' | Out-File $logFile -Append -encoding utf8
    }
}
$elapsedTime = (Get-Date) - $startTime
$roundedTime = [math]::Round($elapsedTime.TotalSeconds)

"Total time taken: $roundedTime seconds" | Out-File $logFile -Append -encoding utf8