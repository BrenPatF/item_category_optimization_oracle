/***************************************************************************************************
Name: setup_sml.sql                    Author: Brendan Furey                       Date: 30-Jun-2024

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
| *setup_sml.sql*             | Sets up Small dataset                                              |
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

This file has the script to set up the Small dataset
***************************************************************************************************/
PROMPT Create small tables...
DROP TABLE small_categories
/
CREATE TABLE small_categories (
        id            VARCHAR2(5) PRIMARY KEY,
        min_items     INTEGER,
        max_items     INTEGER
)
/
DROP TABLE small_items
/
CREATE TABLE small_items (
        id              VARCHAR2(3) PRIMARY KEY,
        item_name       VARCHAR2(30),
        category_id     VARCHAR2(5),
        price           NUMBER,
        value           NUMBER
)  
/
PROMPT Insert small data
DECLARE

  i     PLS_INTEGER := 0;
  PROCEDURE Ins_category(
                        p_id	        VARCHAR2,
                        p_min_items   PLS_INTEGER,
                        p_max_items   PLS_INTEGER) IS
  BEGIN

    INSERT INTO small_categories VALUES (p_id, p_min_items, p_max_items);

  END Ins_category;

  PROCEDURE Ins_item(p_item_name    VARCHAR2, 
                     p_category     VARCHAR2,
                     p_price        NUMBER,
                     p_value        NUMBER) IS
  BEGIN

    i := i + 1;
    INSERT INTO small_items VALUES (LPad (i, 1, '0'), p_item_name, p_category, p_price, p_value);

  END Ins_item;

BEGIN

  DELETE small_categories;
  Ins_category ('CAT_1', 1, 2);
  Ins_category ('CAT_2', 1, 2);
--  Ins_category ('CAT_3', 0, 2);
  Ins_category ('AL', 3, 3);

  DELETE small_items;

  Ins_item('Item-11', 'CAT_1', 1, 1);
  Ins_item('Item-12', 'CAT_1', 2, 2);
  Ins_item('Item-13', 'CAT_1', 3, 3);

  Ins_item('Item-21', 'CAT_2', 1, 6);
  Ins_item('Item-22', 'CAT_2', 2, 4);
  Ins_item('Item-23', 'CAT_2', 3, 2);
  
--  Ins_item('Item-01', 'CAT_3', 0, 1);
END;
/
BREAK ON category_id
SELECT category_id, id, item_name, price, value
  FROM small_items
 ORDER BY 1, 2
/