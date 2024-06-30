/***************************************************************************************************
Name: views_sml.sql                    Author: Brendan Furey                       Date: 30-Jun-2024

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
| *views_sml.sql*             | Points dataset views to Small dataset                              |
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

This file has the script to point the dataset views to the Small dataset
***************************************************************************************************/
PROMPT Point view at small tables and set small bind variables
CREATE OR REPLACE VIEW categories(
        id,
        min_items,
        max_items
) AS SELECT
        id,
        min_items,
        max_items
  FROM small_categories
/
CREATE OR REPLACE VIEW items(
        id,
        item_name,
        category_id,
        item_price,
        item_value
) AS
SELECT  id,
        item_name,
        category_id,
        price,
        value
  FROM small_items
/
COLUMN min_items HEADING "Min" FORMAT 990
COLUMN max_items HEADING "Max" FORMAT 990
PROMPT Categories
SELECT  id,
        min_items,
        max_items
  FROM categories
 ORDER BY 1
/
BREAK ON category_id
PROMPT Items
SELECT category_id, id, item_name, item_price, item_value
  FROM items
 ORDER BY 1, 2
/
PROMPT Running sums of item prices
SELECT Row_Number() OVER (ORDER BY item_price, id) index_sum,
       item_price,
       Sum(item_price) OVER (ORDER BY item_price, id) sum_price
  FROM items
ORDER BY 1
/
PROMPT Running sums of item values
SELECT Row_Number() OVER (ORDER BY item_value DESC, id) index_sum,
       item_value,
       Sum(item_value) OVER (ORDER BY item_value DESC, id) sum_value
  FROM items
ORDER BY 1
/
VAR MAX_PRICE NUMBER
VAR ITEM_WIDTH NUMBER
VAR SEQ_SIZE NUMBER
VAR TOP_N NUMBER
VAR KEEP_START NUMBER
VAR KEEP_FACTOR NUMBER
BEGIN
  :MAX_PRICE := 5;
  :ITEM_WIDTH := 1;
  :SEQ_SIZE := 3;
  :TOP_N := 3;
  :KEEP_START := 10;
  :KEEP_FACTOR := 3;
END;
/
COLUMN category_id HEADING "Category" FORMAT A8
COLUMN item_id HEADING "Item" FORMAT A4
COLUMN item_name HEADING "Name" FORMAT A10
COLUMN item_price HEADING "Price" FORMAT 999999990
COLUMN item_value HEADING "Value" FORMAT 999999990
COLUMN tot_price HEADING "Total Price" FORMAT 9999999990
COLUMN tot_value HEADING "Total Value" FORMAT 9999999990
COLUMN path HEADING "Path" FORMAT A4
COLUMN rnk HEADING "Rank" FORMAT 9990

COLUMN min_items HEADING "Min" FORMAT A3
COLUMN n_items HEADING "Actual" FORMAT A7
COLUMN max_items HEADING "Max" FORMAT A3
COLUMN item_list HEADING "Item List" FORMAT A25
   