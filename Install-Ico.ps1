<#**************************************************************************************************
Name: Install-Ico.ps1                  Author: Brendan Furey                       Date: 30-Jun-2024

Component Powershell script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

POWERSHELL SCRIPTS
====================================================================================================
|  Powershell Script        | Description                                                          |
|==================================================================================================|
|  Copy-DataFilesInput.ps1  | Copies England dataset file and unit test JSON file to INPUT folder  |
| *Install-Ico.ps1*         | Installation driver script                                           |
|  app\Run-All.ps1          | Run driver script for different solution methods for the             |
|                           | optimization problem, with various combinations of parameters for    |
|                           | each of three datasets                                               |
|  app\Run-Perturb.ps1      | Runs a sqlplus script across a range of maximum prices on all three  |
|                           | datasets, using the fastest solution method                          |
====================================================================================================

This file has the installation driver script
**************************************************************************************************#>
Date -format "dd-MMM-yy HH:mm:ss"
"First try to copy files to input folder..."
. ./Copy-DataFilesInput
if (-not $IsFolder) {
    "Could not copy files, so aborting main script..."
    exit
}
$installs = @(@{folder = 'install_prereq'; script = 'drop_utils_users'; schema = 'sys'},
              @{folder = 'install_prereq'; script = 'install_sys'; schema = 'sys'},
              @{folder = 'install_prereq\lib'; script = 'install_lib_all'; schema = 'lib'},
              @{folder = 'install_prereq\app'; script = 'c_syns_all'; schema = 'app'},
              @{folder = 'app'; script = 'install_ico'; schema = 'app'},
              @{folder = 'app'; script = 'install_ico_tt'; schema = 'app'})
$installs

Foreach($i in $installs){
    sl ($PSScriptRoot + '/' + $i.folder)
    $script = '@./' + $i.script
    $sysdba = ''
    if ($i.schema -eq 'sys') {
        $sysdba = ' AS SYSDBA'
    }
    $conn = $i.schema + '/' + $i.schema + '@orclpdb' + $sysdba
    'Executing: ' + $script + ' for connection ' + $conn
    & sqlplus $conn $script
}
sl $PSScriptRoot
