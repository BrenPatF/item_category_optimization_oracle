/***************************************************************************************************
Name: c_temp_tables.sql                Author: Brendan Furey                       Date: 30-Jun-2024

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
| *c_temp_tables.sql*         | Recreates the temporary tables                                     |
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

This file has the script to recreate the temporary tables
***************************************************************************************************/
DROP TABLE paths
/
CREATE GLOBAL TEMPORARY TABLE paths (
        path_rnk                INTEGER,
        item_rnk                INTEGER,
        lev                     INTEGER,
        tot_price               INTEGER,
        tot_value               INTEGER,
        cat_id                  VARCHAR2(5),
        next_cat_id             VARCHAR2(5),
        same_cats               INTEGER,
        min_items               INTEGER,
        cats_path               VARCHAR2(50),
        path                    VARCHAR2(50)
)
ON COMMIT DELETE ROWS
/
DROP TABLE paths_base
/
CREATE GLOBAL TEMPORARY TABLE paths_base (
        path_rnk                INTEGER,
        item_rnk                INTEGER,
        lev                     INTEGER,
        tot_price               INTEGER,
        tot_value               INTEGER,
        cat_base_id             INTEGER,
        next_cat_base_id        INTEGER,
        same_cats               INTEGER,
        min_items               INTEGER,
        cat_base_sum            INTEGER,
        path                    VARCHAR2(50)
)
ON COMMIT DELETE ROWS
/
DROP TABLE paths_link
/
CREATE GLOBAL TEMPORARY TABLE paths_link (
        path_rnk                INTEGER,
        item_rnk                INTEGER,
        lev                     INTEGER,
        tot_price               INTEGER,
        tot_value               INTEGER,
        cat_id                  VARCHAR2(5),
        next_cat_id             VARCHAR2(5),
        same_cats               INTEGER,
        min_items               INTEGER,
        cats_path               VARCHAR2(50),
        prior_iln_id            INTEGER,
        iln_id                  INTEGER
)
ON COMMIT DELETE ROWS
/
DROP SEQUENCE iln_seq
/
CREATE SEQUENCE iln_seq START WITH 1 CACHE 1000
/
DROP TABLE item_links
/
CREATE GLOBAL TEMPORARY TABLE item_links (
        id                      INTEGER,
        item_rnk                INTEGER,
        prior_iln_id            INTEGER
)
ON COMMIT DELETE ROWS
/
DROP TABLE paths_base_link
/
CREATE GLOBAL TEMPORARY TABLE paths_base_link (
        path_rnk                INTEGER,
        item_rnk                INTEGER,
        lev                     INTEGER,
        tot_price               INTEGER,
        tot_value               INTEGER,
        cat_base_id             INTEGER,
        next_cat_base_id        INTEGER,
        same_cats               INTEGER,
        min_items               INTEGER,
        cat_base_sum            INTEGER,
        prior_ibl_id            INTEGER,
        ibl_id                  INTEGER
)
ON COMMIT DELETE ROWS
/
DROP SEQUENCE ibl_seq
/
CREATE SEQUENCE ibl_seq START WITH 1 CACHE 1000
/
DROP TABLE item_base_links
/
CREATE GLOBAL TEMPORARY TABLE item_base_links (
        id                      INTEGER,
        item_rnk                INTEGER,
        prior_ibl_id            INTEGER
)
ON COMMIT DELETE ROWS
/
DROP TABLE small_paths
/
CREATE GLOBAL TEMPORARY TABLE small_paths (
        path                    VARCHAR2(50),
        lev                     INTEGER,
        tot_price               INTEGER,
        tot_value               INTEGER,
        item_id                 VARCHAR2(3)
)
ON COMMIT DELETE ROWS
/
DROP TABLE item_running_sums
/
CREATE GLOBAL TEMPORARY TABLE item_running_sums (
        slot_index              INTEGER,
        sum_value               INTEGER,
        sum_price               INTEGER
)
ON COMMIT DELETE ROWS
/
PROMPT items_ranked
DROP TABLE items_ranked
/
CREATE TABLE items_ranked (
        item_id                 VARCHAR2(3),
        cat_id                  VARCHAR2(5),
        item_price              INTEGER,
        item_value              INTEGER,
        min_items               INTEGER,
        max_items               INTEGER,
        min_remain              INTEGER,
        next_cat_id             VARCHAR2(5),
        item_rnk                INTEGER PRIMARY KEY,
        n_items                 INTEGER
)
ORGANIZATION INDEX
/
REM CREATE UNIQUE INDEX irk_uk ON items_ranked(item_rnk)
REM /
PROMPT items_ranked_base
DROP TABLE items_ranked_base
/
CREATE TABLE items_ranked_base (
        item_id                 VARCHAR2(3),
        cat_base_id             INTEGER,
        item_price              INTEGER,
        item_value              INTEGER,
        min_items               INTEGER,
        max_items               INTEGER,
        min_remain              INTEGER,
        next_cat_base_id        INTEGER,
        item_rnk                INTEGER PRIMARY KEY,
        n_items                 INTEGER
)
ORGANIZATION INDEX
/
PROMPT items_ranked_link
DROP TABLE items_ranked_link
/
CREATE TABLE items_ranked_link (
        cat_id                  VARCHAR2(5),
        item_price              INTEGER,
        item_value              INTEGER,
        min_items               INTEGER,
        max_items               INTEGER,
        min_remain              INTEGER,
        next_cat_id             VARCHAR2(5),
        item_rnk                INTEGER PRIMARY KEY
)
ORGANIZATION INDEX
/
PROMPT items_ranked_link
DROP TABLE items_ranked_base_link
/
CREATE TABLE items_ranked_base_link (
        cat_base_id             INTEGER,
        item_price              INTEGER,
        item_value              INTEGER,
        min_items               INTEGER,
        max_items               INTEGER,
        min_remain              INTEGER,
        next_cat_base_id        INTEGER,
        item_rnk                INTEGER PRIMARY KEY
)
ORGANIZATION INDEX
/

PROMPT Compile specs
@item_seqs.pks
@item_cat_seqs.pks
PROMPT Create views
@c_views
PROMPT Compile bodies
@item_seqs.pkb
@item_cat_seqs.pkb
