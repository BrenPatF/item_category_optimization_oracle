/***************************************************************************************************
Name: l_dataset.sql                    Author: Brendan Furey                       Date: 30-Jun-2024

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
| *l_dataset.sql*             | Lists a dataset                                                    |
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

This file has the script to list a dataset
***************************************************************************************************/
COLUMN category_id   HEADING "Position"          FORMAT A9
COLUMN item_id       HEADING "Id"                FORMAT A3
COLUMN item_name     HEADING "Player"            FORMAT A30
COLUMN min_items     HEADING "Min Players"       FORMAT 9999999999990
COLUMN max_items     HEADING "Max Players"       FORMAT 9999999999990
COLUMN index_sum     HEADING "Index"             FORMAT 99990
COLUMN item_price    HEADING "Player Price"      FORMAT 99990
COLUMN sum_price     HEADING "Sum Price"         FORMAT 99990
COLUMN item_value    HEADING "Player Value"      FORMAT 99990
COLUMN sum_value     HEADING "Sum Value"         FORMAT 99990

PROMPT Positions
SELECT  id category_id,
        min_items,
        max_items
  FROM categories
 ORDER BY 1
/
BREAK ON category_id
PROMPT Players
SELECT category_id, id item_id, item_name, item_price, item_value
  FROM items
 ORDER BY 1, 2
/
PROMPT Running sums of player prices
SELECT *
  FROM (
SELECT Row_Number() OVER (ORDER BY item_price, id) index_sum,
       item_price,
       Sum(item_price) OVER (ORDER BY item_price, id) sum_price
  FROM items)
 WHERE index_sum < :SEQ_SIZE
ORDER BY 1
/
PROMPT Running sums of player values DESC
SELECT *
  FROM (
SELECT Row_Number() OVER (ORDER BY item_value DESC, id) index_sum,
       item_value,
       Sum(item_value) OVER (ORDER BY item_value DESC, id) sum_value
  FROM items)
 WHERE index_sum < :SEQ_SIZE
ORDER BY 1
/
