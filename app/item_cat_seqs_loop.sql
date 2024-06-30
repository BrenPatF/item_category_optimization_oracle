/***************************************************************************************************
Name: item_cat_seqs_loop.sql           Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PARAMETERS
==========
DS          = Dataset code (SML/BRA/ENG)
KEEP_START  = Keep number start iterative refinement parameter
KEEP_FACTOR = Keep number factor iterative refinement parameter

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
| *item_cat_seqs_loop.sql*    | Runs iterative refinement methods                                  | 
|  item_cat_seqs_perturb.sql  | Runs perturbation analysis                                         | 
|  item_cat_seqs_pv_rsf.sql   | Runs Post-Validation recursive subquery factor method              | 
|  item_cat_seqs_rsf.sql      | Runs recursive subquery factor methods with pre-emptive filtering  | 
|  item_cat_seqs.sql          | Runs PL/SQL driven base methods                                    | 
|  item_seqs.sql              | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to run the iterative refinement methods
***************************************************************************************************/
DEFINE DS = &1
DEFINE KEEP_START = &2
DEFINE KEEP_FACTOR = &3
BREAK ON tot_value ON tot_price ON rnk ON category_id
@..\..\install_prereq\initspool item_cat_seqs_loop_&DS._&KEEP_START._&KEEP_FACTOR
PROMPT Truncate paths
TRUNCATE TABLE paths
/
@..\set_contexts
VAR TIMER_SET NUMBER
BEGIN
  :TIMER_SET := Timer_Set.Construct('Item_Cat_Seqs_Loop');
END;
/
BEGIN
     Item_Cat_Seqs.Init_Loop(p_keep_start      => &KEEP_START, 
                             p_keep_factor     => &KEEP_FACTOR);
END;
/
SET TIMING ON
PROMPT Iteratively_Refine_Recurse - path level
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM iteratively_refine_recurse_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Iteratively_Refine_Recurse - path level');
BEGIN
     Item_Cat_Seqs.Init_Loop(p_keep_start      => &KEEP_START, 
                             p_keep_factor     => &KEEP_FACTOR);
END;
/
PROMPT Iteratively_Refine_Recurse - item level
WITH binds AS (
    SELECT To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE')) seq_size,
           To_Number(SYS_Context('RECURSION_CTX', 'ITEM_WIDTH')) item_width
      FROM DUAL
)
SELECT arl.tot_value,
       arl.tot_price,
       arl.rnk,
       itm.category_id,
       Substr (arl.path, (ind.item_index - 1) * bnd.item_width + 1, bnd.item_width) item_id,
       itm.item_name,
       itm.item_value,
       itm.item_price
  FROM iteratively_refine_recurse_v arl
  CROSS JOIN binds bnd
  CROSS APPLY (SELECT LEVEL item_index FROM DUAL CONNECT BY LEVEL <= bnd.seq_size) ind
  JOIN items itm
    ON itm.id = Substr (arl.path, (ind.item_index - 1) * bnd.item_width + 1, bnd.item_width)
 WHERE arl.rnk <= :TOP_N
ORDER BY arl.rnk, arl.tot_price, ind.item_index
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Iteratively_Refine_Recurse - item level');
PROMPT Pop_Table_Iterate
BEGIN
  Item_Cat_Seqs.Iteratively_Refine_Iterate(p_keep_start      => &KEEP_START, 
                                           p_keep_factor     => &KEEP_FACTOR);
END;
/
PROMPT Iteratively_Refine_Iterate - path level
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM paths_ranked_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Iteratively_Refine_Iterate - path level');
BEGIN
     Item_Cat_Seqs.Init_Loop(p_keep_start      => &KEEP_START, 
                             p_keep_factor     => &KEEP_FACTOR);
END;
/
PROMPT Iteratively_Refine_RSF - path level
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM iteratively_refine_rsf_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Iteratively_Refine_RSF - path level');
SET TIMING OFF
EXEC Utils.W(Timer_Set.Format_Results(:TIMER_SET));
@..\..\install_prereq\endspool
