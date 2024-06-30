<#**************************************************************************************************
Name: Run-All.ps1                      Author: Brendan Furey                       Date: 30-Jun-2024

Component Powershell script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

POWERSHELL SCRIPTS
====================================================================================================
|  Powershell Script        | Description                                                          |
|==================================================================================================|
|  Copy-DataFilesInput.ps1  | Copies England dataset file and unit test JSON file to INPUT folder  |
|  Install-Ico.ps1          | Installation driver script                                           |
| *app\Run-All.ps1*         | Run driver script for different solution methods for the             |
|                           | optimization problem, with various combinations of parameters for    |
|                           | each of three datasets                                               |
|  app\Run-Perturb.ps1      | Runs a sqlplus script across a range of maximum prices on all three  |
|                           | datasets, using the fastest solution method                          |
====================================================================================================

This file has the run driver script for different solution methods for the optimization problem,
with various combinations of parameters for each of three datasets 
**************************************************************************************************#>
Date -format "dd-MMM-yy HH:mm:ss"
$startTime = Get-Date
<#**************************************************************************************************
Name: SCRIPT.ps1                       Author: Brendan Furey                       Date: 30-Jun-2024

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
|  app\Run-Perturb.ps1      | Runs a sqlplus script across a range of maximum prices on all three  |
|                           | datasets, using the fastest solution method                          |
====================================================================================================

This file has the script to 
**************************************************************************************************#>
ctories = Get-ChildItem -Directory | Where-Object { $_.Name -match "^results_\d+$" }
[int]$maxIndex = 0
if ($directories.Count -gt 0) {
    [int[]]$indexLis = $directories | 
        ForEach-Object {
            $_.Name -replace 'results_', ''
        }
    $maxIndex = ($indexLis | Measure-Object -Maximum).Maximum
}
$nxtIndex = ($maxIndex + 1).ToString("D2")
$newDir = ('results_' + $nxtIndex)
New-Item ('results_' + $nxtIndex) -ItemType Directory

$logFile = $PSScriptRoot + '\Run-All_' + $nxtIndex + '.log'
$ddl = 'c_temp_tables'
$inputs = [ordered]@{
    sml = [ordered]@{views_sml              = @()
                     item_seqs              = @(@('MP'),@('MC'),@('SP'),@('SC'))
                     item_cat_seqs          = @(,@(10, 0))
                     item_cat_seqs_rsf      = @(,@(10, 0))
                     item_cat_seqs_pv_rsf   = @()
                     item_cat_seqs_loop     = @(,@(10, 3))}
    bra = [ordered]@{views_bra              = @()
                     item_cat_seqs          = @(@(10, 0),@(100, 0),@(100, 10748),@(0, 10748))
                     item_cat_seqs_rsf      = @(@(10, 0),@(100, 0),@(100, 10748),@(0, 10748))
                     item_cat_seqs_loop     = @(,@(10, 3))}
    eng = [ordered]@{views_eng              = @()
                     item_cat_seqs          = @(@(50, 0),@(300, 0),@(300, 1952),@(0, 1952))
                     item_cat_seqs_rsf      = @(@(50, 0),@(300, 0),@(300, 1952),@(0, 1952))
                     item_cat_seqs_loop     = @(,@(50, 3))}
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
                $newCmd = ('@..\' + $k + ' ' + $i + ' ' + $p[0] + ' ' + $p[1])
                ("newCmd = " + $newCmd)
                $p
                $cmdLis += ($newCmd + [Environment]::NewLine)
                if($p[1] -ne $null) {$logLis += ($k + '_' + $i + '_' + $p[0] + '_' + $p[1] + '.log')}
            }
        }
    }
    $cmdLis
    $output = $cmdLis | sqlplus 'app/app@orclpdb'
    Set-Location ..

    foreach($l in $logLis) {
        $f = $newDir + '\' + $l
        $l | Out-File $logFile -Append -encoding utf8
        Get-Content $f | Select-String -Pattern 'Timer Set: Item_Cat_Seqs,' -Context 0, 17 | Out-File $logFile -Append -encoding utf8
        Get-Content $f | Select-String -Pattern 'Timer Set: Item_Cat_Seqs_RSF' -Context 0, 14 | Out-File $logFile -Append -encoding utf8
        Get-Content $f | Select-String -Pattern 'Timer Set: Item_Cat_Seqs_Loop' -Context 0, 12 | Out-File $logFile -Append -encoding utf8
    }
}
$elapsedTime = (Get-Date) - $startTime
$roundedTime = [math]::Round($elapsedTime.TotalSeconds)

"Total time taken: $roundedTime seconds" | Out-File $logFile -Append -encoding utf8