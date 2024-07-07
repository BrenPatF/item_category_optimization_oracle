<#**************************************************************************************************
Name: Copy-DataFilesInput.ps1           uthor: Brendan Furey                       Date: 30-Jun-2024

Component Powershell script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

POWERSHELL SCRIPTS
====================================================================================================
|  Powershell Script        | Description                                                          |
|==================================================================================================|
| *Copy-DataFilesInput.ps1* | Copies England dataset file and unit test JSON file to INPUT folder  |
|  Install-Ico.ps1          | Installation driver script                                           |
|  app\Run-All.ps1          | Runs sqlplus scripts for different solution methods for the          |
|                           | optimization problem, with various combinations of parameters for    |
|                           | each of three datasets                                               |
|  app\Run-Perturb.ps1      | Runs a sqlplus script across a range of maximum prices on all three  |
|                           | datasets, using the fastest solution method                          |
|  app\Run-ItemSeqs.ps1     | Runs sqlplus scripts for different solution methods for the          |
|                           | sequence generation problem, for the Small dataset only              |
====================================================================================================

This file has the script to copy the England dataset file and unit test JSON file to the INPUT
folder
**************************************************************************************************#>
$inputPath = "c:/input"
$utFile = "./unit_test/tt_item_cat_seqs.purely_wrap_best_combis_inp.json"
$csvFile = "./fantasy_premier_league_player_stats.csv"

$IsFolder = $true
if (Test-Path $inputPath) {

    if (Test-Path -PathType Container $inputPath) {
        "The item $inputPath is a folder, copy there..."
    } else {
        "The item $inputPath is a file, aborting..."
        $IsFolder = $false
    }

} else {

    "The item $inputPath does not exist, creating folder..."
    New-Item -ItemType Directory -Force -Path $inputPath

}
if ($IsFolder) {
    Copy-Item $utFile $inputPath
    "Copied $utFile to $inputPath"
    Copy-Item $csvFile $inputPath
    "Copied $csvFile to $inputPath"
}