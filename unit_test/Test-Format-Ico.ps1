Import-Module ..\powershell_utils\TrapitUtils\TrapitUtils
#'@..\app\views_sml' | sqlplus 'app/app@orclpdb'
Test-FormatDB 'app/app' 'orclpdb' 'item_cat_seqs' $PSScriptRoot `
'BEGIN
    Utils.g_w_is_active := FALSE;
END;
/
@..\app\views_sml
'
