/***************************************************************************************************
Name: item_cat_seqs.sql                Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PARAMETERS
==========
DS        = Dataset code (SML/BRA/ENG)
KEEP_NUM  = Keep number filtering parameter
MIN_VALUE = Minimum value filtering parameter

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
|  item_cat_seqs_pv_rsf.sql   | Runs Post-Validation recursive subquery factor method              | 
|  item_cat_seqs_rsf.sql      | Runs recursive subquery factor methods with pre-emptive filtering  | 
| *item_cat_seqs.sql*         | Runs PL/SQL driven base methods                                    | 
|  item_seqs.sql              | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to run the PL/SQL driven base methods
***************************************************************************************************/
DEFINE DS = &1
DEFINE KEEP_NUM = &2
DEFINE MIN_VALUE = &3
BREAK ON tot_value ON tot_price ON rnk ON category_id

@..\..\install_prereq\initspool item_cat_seqs_&DS._&KEEP_NUM._&MIN_VALUE
@..\set_contexts
VAR TIMER_SET NUMBER
BEGIN
  :TIMER_SET := Timer_Set.Construct('Item_Cat_Seqs');
END;
/
PROMPT Pop_Table_Iterate
BEGIN
  Item_Cat_Seqs.Pop_Table_Iterate(p_keep_num      => &KEEP_NUM, 
                                  p_min_value     => &MIN_VALUE);
END;
/
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM paths_ranked_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Pop_Table_Iterate');
PROMPT Solutions by Category
SELECT prv.tot_value,
       prv.tot_price,
       prv.rnk,
       cat.id                 category_id,
       To_Char(cat.min_items) min_items,
       ' ' || CASE WHEN COUNT(itm.id) = cat.min_items THEN '<-' ELSE '  ' END || COUNT(itm.id) || 
          CASE WHEN COUNT(itm.id) = cat.max_items THEN '->' ELSE '  ' END n_items,
       To_Char(cat.max_items) max_items,
       ListAgg(itm.id, ', ')  item_list
  FROM categories cat
 CROSS JOIN paths_ranked_v prv
 CROSS APPLY TABLE(Item_Cat_Seqs.Split_Values(prv.path, :ITEM_WIDTH)) psv
  LEFT JOIN items itm ON itm.id = psv.COLUMN_VALUE 
   AND itm.category_id = cat.id
 WHERE prv.rnk <= :TOP_N
   AND cat.id != 'AL'
 GROUP BY prv.tot_value,
          prv.tot_price,
          prv.rnk,
          cat.id,
          cat.min_items,
          cat.max_items
 ORDER BY 3, 4
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Solutions by Category');
PROMPT Pop_Table_Iterate_Base
BEGIN
  Item_Cat_Seqs.Pop_Table_Iterate_Base(p_keep_num      => &KEEP_NUM, 
                                       p_min_value     => &MIN_VALUE);
END;
/
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM paths_base_ranked_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Pop_Table_Iterate_Base');

PROMPT Pop_Table_Iterate_Link
BEGIN
  Item_Cat_Seqs.Pop_Table_Iterate_Link(p_keep_num      => &KEEP_NUM, 
                                       p_min_value     => &MIN_VALUE);
END;
/
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM paths_link_ranked_path_v
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Pop_Table_Iterate_Link');
BEGIN
     Item_Cat_Seqs.Set_Contexts(p_keep_num      => &KEEP_NUM, 
                                p_min_value     => &MIN_VALUE);
END;
/
SET TIMING ON
PROMPT paths_link_ranked_item_v - item level
SELECT tot_value,
       tot_price,
       rnk,
       category_id,
       item_id,
       item_name,
       item_value,
       item_price
  FROM paths_link_ranked_item_v
ORDER BY rnk, tot_price, lev DESC
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Pop_Table_Iterate_Link - item level');

PROMPT Pop_Table_Iterate_Base_Link
BEGIN
  Item_Cat_Seqs.Pop_Table_Iterate_Base_Link(p_keep_num      => &KEEP_NUM, 
                                            p_min_value     => &MIN_VALUE);
END;
/
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM paths_base_link_ranked_path_v
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Pop_Table_Iterate_Base_Link');

BEGIN
  Item_Cat_Seqs.Init(p_keep_num      => &KEEP_NUM, 
                     p_min_value     => &MIN_VALUE);
END;
/
PROMPT Array_Iterate
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM array_iterate_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Array_Iterate');
PROMPT Pop_Table_Recurse
BEGIN
  Item_Cat_Seqs.Pop_Table_Recurse(p_keep_num      => &KEEP_NUM, 
                                  p_min_value     => &MIN_VALUE);
END;
/
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM paths_ranked_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Pop_Table_Recurse');
BEGIN
  Item_Cat_Seqs.Init(p_keep_num      => &KEEP_NUM, 
                     p_min_value     => &MIN_VALUE);
END;
/
PROMPT Array_Recurse
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM array_recurse_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Array_Recurse');
SET TIMING OFF
EXEC Utils.W(Timer_Set.Format_Results(:TIMER_SET));
@..\..\install_prereq\endspool
