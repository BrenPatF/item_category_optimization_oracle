/***************************************************************************************************
Name: item_cat_seqs_pv_rsf.sql         Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

====================================================================================================
|  SQL Script                 | Description                                                        |
|===================================================================================================
INSTALL SCRIPTS
====================================================================================================
|  install_ico.sql            | Installs base components                                           |
|  install_ico_tt.sql         | Installs unit testing components                                   |
|  setup_sml.sql              | Sets up the Small set                                              |
|  setup_bra.sql              | Sets up the Brazil dataset                                         |
|  setup_eng.sql              | Sets up the England dataset                                        |
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
| *item_cat_seqs_pv_rsf.sql*  | Runs Post-Validation recursive subquery factor method              | 
|  item_cat_seqs_rsf.sql      | Runs recursive subquery factor methods with pre-emptive filtering  | 
|  item_cat_seqs.sql          | Runs PL/SQL driven base methods                                    | 
|  item_seqs.sql              | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to run the Post-Validation recursive subquery factor method
***************************************************************************************************/
BREAK ON tot_value ON tot_price ON rnk ON category_id

@..\..\install_prereq\initspool item_cat_seqs_pv_rsf_sml
VAR TIMER_SET NUMBER
BEGIN
  :TIMER_SET := Timer_Set.Construct('Item_Cat_Seqs_PV_RSF');
END;
/
SET TIMING ON
PROMPT Solution via view rsf_post_valid_v...
EXEC Timer_Set.Init_Time(:TIMER_SET);
SELECT /*+ gather_plan_statistics POST_VALID_V */ path,
       tot_value,
       tot_price,
       rnk
  FROM rsf_post_valid_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'rsf_post_valid_v');
EXECUTE Utils.W(Utils.Get_XPlan (p_sql_marker => 'POST_VALID_V'));

SET TIMING OFF
EXEC Utils.W(Timer_Set.Format_Results(:TIMER_SET));
@..\..\install_prereq\endspool
