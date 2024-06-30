/***************************************************************************************************
Name: install_ico_tt.sql               Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

====================================================================================================
|  SQL Script                 | Description                                                        |
|===================================================================================================
INSTALL SCRIPTS
====================================================================================================
|  install_ico.sql            | Installs base components                                           |
| *install_ico_tt.sql*        | Installs unit testing components                                   |
|  setup_sml.sql              | Sets up Small dataset                                              |
|  setup_bra.sql              | Sets up Brazil dataset                                             |
|  setup_eng.sql              | Sets up England dataset                                            |
====================================================================================================
LISTING SCRIPTS
====================================================================================================
|  l_dataset.sql              | Lists a dataset                                                    |
|  l_dataset_bra.sql          | Lists the Brazil dataset                                           |
|  l_dataset_eng.sql          | Lists the England dataset                                          |
====================================================================================================
RUN SETUP SCRIPTS
====================================================================================================
|  c_temp_tables.sql          | Recreates the temporary tables                                     |
|  c_views.sql                | Recreates the method views                                         |
|  set_contexts.sql           | Sets contexts                                                      |
|  views_sml.sql              | Points dataset views to Small dataset                              |
|  views_bra.sql              | Points dataset views to Brazil dataset                             |
|  views_eng.sql              | Points dataset views to England dataset                            |
====================================================================================================
RUN SCRIPTS
====================================================================================================
|  item_cat_seqs_loop.sql     | Runs iterative refinement methods                                  | 
|  item_cat_seqs_perturb.sql  | Runs perturbation analysis                                         | 
|  item_cat_seqs_pv_rsf.sql   | Runs Post-Validation recursive subquery factor method              | 
|  item_cat_seqs_rsf.sql      | Runs recursive subquery factor methods with pre-emptive filtering  | 
|  item_cat_seqs.sql          | Runs PL/SQL driven base methods                                    | 
|  item_seqs.sql              | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to install the unit testing components
***************************************************************************************************/
@..\install_prereq\initspool install_ico_tt

PROMPT Create package tt_item_cat_seqs
@tt_item_cat_seqs.pks
@tt_item_cat_seqs.pkb

PROMPT Add the tt_units record, reading in JSON file from INPUT_DIR
DECLARE

  l_api_lis L1_Chr_Arr := L1_Chr_Arr(
      'RSF_Post_Valid',
      'RSF_SQL',
      'RSF_SQL_Material',
      'RSF_Irk_IRS_Tabs',
      'RSF_Irk_Tab_Where_Fun',
      'Pop_Table_Iterate',
      'Pop_Table_Iterate_Base',
      'Pop_Table_Iterate_Link',
      'Pop_Table_Iterate_Base_Link',
      'Array_Iterate',
      'Pop_Table_Recurse',
      'Array_Recurse',
      'Iteratively_Refine_Recurse',
      'Iteratively_Refine_Iterate',
      'Iteratively_Refine_RSF'
  );
  PROCEDURE Add_API (p_purely_wrap_api_function_nm  VARCHAR2) IS
  BEGIN
    Trapit.Add_Ttu(
            p_unit_test_package_nm         => 'TT_ITEM_CAT_SEQS',
            p_purely_wrap_api_function_nm  => p_purely_wrap_api_function_nm, 
            p_group_nm                     => 'item_cat_seqs',
            p_active_yn                    => 'Y', 
            p_input_file                   => 'tt_item_cat_seqs.purely_wrap_best_combis_inp.json',
            p_title                        => 'Best Item Category Combis - ' || p_purely_wrap_api_function_nm);
  END Add_API;
BEGIN

  FOR i IN 1..l_api_lis.COUNT LOOP
    Add_API(l_api_lis(i));
  END LOOP;

END;
/
@..\install_prereq\endspool
exit