/***************************************************************************************************
Name: c_views.sql                      Author: Brendan Furey                       Date: 30-Jun-2024

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
| *c_views.sql*               | Recreates the method views                                         |
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

This file has the script to recreate the method views
***************************************************************************************************/
PROMPT View rsf_post_valid_v...
CREATE OR REPLACE VIEW rsf_post_valid_v AS
WITH binds AS (
    SELECT To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE')) seq_size,
           To_Number(SYS_Context('RECURSION_CTX', 'MAX_PRICE')) max_price,
           To_Number(SYS_Context('RECURSION_CTX', 'ITEM_WIDTH')) item_width
      FROM DUAL
), tree_walk(item_id, lev, tot_price, tot_value, cat_id, path) AS (
    SELECT '0', 0, 0, 0, CAST (NULL AS VARCHAR2(400)), CAST (NULL AS VARCHAR2(400))
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           itm.category_id,
           trw.path || itm.id
      FROM tree_walk trw
      JOIN items itm
        ON itm.id > trw.item_id
     WHERE trw.lev < To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE'))
), path_split AS (
    SELECT trw.path,
           trw.tot_value,
           trw.tot_price,
           itm.category_id,
           itm.id item_id
      FROM tree_walk trw
     CROSS JOIN binds bin
     CROSS APPLY (SELECT LEVEL item_index FROM DUAL CONNECT BY LEVEL <= bin.seq_size) ind
      JOIN items itm
        ON itm.id = Substr (trw.path, (ind.item_index - 1) * bin.item_width + 1, bin.item_width)
     WHERE trw.lev = bin.seq_size
), infeasible_paths AS (
    SELECT psp.path
      FROM categories cat
      LEFT JOIN path_split psp PARTITION BY (psp.path)
        ON psp.category_id = cat.id
     WHERE cat.id != 'AL'
     GROUP BY psp.path,
              cat.id,
              cat.min_items,
              cat.max_items
    HAVING NOT COUNT(psp.item_id) BETWEEN cat.min_items AND cat.max_items
)
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM tree_walk trw
 CROSS JOIN binds bin
 WHERE trw.path NOT IN (SELECT fpa.path FROM infeasible_paths fpa)
   AND trw.lev = bin.seq_size
   AND trw.tot_price <= bin.max_price
/
PROMPT View via pre-emptive query, unhinted...
CREATE OR REPLACE VIEW rsf_sql_v AS
WITH item_rsums AS (
    SELECT Row_Number() OVER (ORDER BY item_value DESC, id) index_value,
           Sum(item_value) OVER (ORDER BY item_value DESC, id) sum_value,
           Row_Number() OVER (ORDER BY item_price, id) index_price,
           Sum(item_price) OVER (ORDER BY item_price, id) sum_price
      FROM items
), category_rsums AS (
    SELECT id, min_items, max_items, 
           Sum(CASE WHEN id != 'AL' THEN min_items END) 
               OVER (ORDER BY CASE WHEN min_items > 0 THEN max_items - min_items END DESC, 
                              min_items, 
                              max_items DESC, 
                              id DESC)                      min_remain,
           Lead(CASE WHEN min_items > 0 THEN id END) 
                OVER (ORDER BY CASE WHEN min_items > 0 THEN max_items - min_items END, 
                               min_items DESC, 
                               max_items, 
                               id)                          next_cat,
           Row_Number() 
                      OVER (ORDER BY CASE WHEN min_items > 0 THEN max_items - min_items END, 
                                     min_items DESC, 
                                     max_items, 
                                     id)                    cat_rnk
      FROM categories
), items_ranked AS (
    SELECT itm.id item_id,
           itm.category_id,
           itm.item_price,
           itm.item_value,
           crs.min_items,
           crs.max_items,
           crs.min_remain,
           crs.next_cat,
           Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id) item_rnk,
           Count(*) OVER () n_items,
           To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE')) seq_size,
           To_Number(SYS_Context('RECURSION_CTX', 'MAX_PRICE')) max_price,
           To_Number(Nvl(SYS_Context('RECURSION_CTX', 'MIN_VALUE'), '0')) min_value,
           To_Number(Nvl(SYS_Context('RECURSION_CTX', 'KEEP_NUM'), '0')) keep_num
      FROM items itm
      JOIN category_rsums crs
        ON crs.id = itm.category_id
), tree_walk(path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat, same_cats, min_items, cats_path, path) AS (
    SELECT 0, 0, 0, 0, 0, id, next_cat, 0, 0, CAST (NULL AS VARCHAR2(400)), CAST (NULL AS VARCHAR2(400))
      FROM category_rsums
     WHERE id = 'AL'
     UNION ALL
    SELECT Row_Number() OVER (PARTITION BY trw.cats_path || irk.category_id ORDER BY trw.tot_value + irk.item_value DESC),
           irk.item_rnk,
           trw.lev + 1,
           trw.tot_price + irk.item_price,
           trw.tot_value + irk.item_value,
           irk.category_id,
           irk.next_cat,
           CASE irk.category_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
           irk.min_items,
           trw.cats_path || irk.category_id,
           trw.path || irk.item_id
      FROM tree_walk trw
      JOIN items_ranked irk
        ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (irk.seq_size - trw.lev - 1))
      LEFT JOIN item_rsums ivr
        ON ivr.index_value = (irk.seq_size - trw.lev - 1)
      LEFT JOIN item_rsums ipr
        ON ipr.index_price = (irk.seq_size - trw.lev - 1)
     WHERE trw.tot_price + irk.item_price + Nvl(ipr.sum_price, 0) <= irk.max_price
       AND trw.tot_value + irk.item_value + Nvl(ivr.sum_value, 0) >= irk.min_value
       AND (trw.path_rnk <= irk.keep_num OR irk.keep_num = 0)
       AND trw.lev < irk.seq_size
       AND CASE irk.category_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
       AND irk.seq_size - (trw.lev + 1) + Least(CASE irk.category_id 
                                              WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
                                              irk.min_items)
           >= irk.min_remain
       AND (irk.category_id = trw.cat_id OR trw.same_cats >= trw.min_items)
       AND (irk.category_id = trw.cat_id OR irk.category_id = Nvl(trw.next_cat, irk.category_id))
)
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM tree_walk
 WHERE lev = To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE'))
/
PROMPT View via pre-emptive query with materialized subqueries...
CREATE OR REPLACE VIEW rsf_sql_material_v AS
WITH item_rsums AS (
    SELECT Row_Number() OVER (ORDER BY item_value DESC, id) index_value,
           Sum(item_value) OVER (ORDER BY item_value DESC, id) sum_value,
           Row_Number() OVER (ORDER BY item_price, id) index_price,
           Sum(item_price) OVER (ORDER BY item_price, id) sum_price
      FROM items
), category_rsums AS (
    SELECT id, min_items, max_items, 
           Sum(CASE WHEN id != 'AL' THEN min_items END) 
               OVER (ORDER BY CASE WHEN min_items > 0 THEN max_items - min_items END DESC, 
                              min_items, 
                              max_items DESC, 
                              id DESC)                      min_remain,
           Lead(CASE WHEN min_items > 0 THEN id END) 
                OVER (ORDER BY CASE WHEN min_items > 0 THEN max_items - min_items END, 
                               min_items DESC, 
                               max_items, 
                               id)                          next_cat,
           Row_Number() 
                      OVER (ORDER BY CASE WHEN min_items > 0 THEN max_items - min_items END, 
                                     min_items DESC, 
                                     max_items, 
                                     id)                    cat_rnk
      FROM categories
), items_ranked AS (
    SELECT /*+ materialize */ itm.id item_id,
           itm.category_id,
           itm.item_price,
           itm.item_value,
           crs.min_items,
           crs.max_items,
           crs.min_remain,
           crs.next_cat,
           Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id) item_rnk,
           Count(*) OVER () n_items,
           To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE')) seq_size,
           To_Number(SYS_Context('RECURSION_CTX', 'MAX_PRICE')) max_price,
           To_Number(Nvl(SYS_Context('RECURSION_CTX', 'MIN_VALUE'), '0')) min_value,
           To_Number(Nvl(SYS_Context('RECURSION_CTX', 'KEEP_NUM'), '0')) keep_num
      FROM items itm
      JOIN category_rsums crs
        ON crs.id = itm.category_id
), tree_walk(path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat, same_cats, min_items, cats_path, path) AS (
    SELECT 0, 0, 0, 0, 0, id, next_cat, 0, 0, CAST (NULL AS VARCHAR2(400)), CAST (NULL AS VARCHAR2(400))
      FROM category_rsums
     WHERE id = 'AL'
     UNION ALL
    SELECT Row_Number() OVER (PARTITION BY trw.cats_path || irk.category_id ORDER BY trw.tot_value + irk.item_value DESC),
           irk.item_rnk,
           trw.lev + 1,
           trw.tot_price + irk.item_price,
           trw.tot_value + irk.item_value,
           irk.category_id,
           irk.next_cat,
           CASE irk.category_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
           irk.min_items,
           trw.cats_path || irk.category_id,
           trw.path || irk.item_id
      FROM tree_walk trw
      JOIN items_ranked irk
        ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (irk.seq_size - trw.lev - 1))
      LEFT JOIN item_rsums ivr
        ON ivr.index_value = (irk.seq_size - trw.lev - 1)
      LEFT JOIN item_rsums ipr
        ON ipr.index_price = (irk.seq_size - trw.lev - 1)
     WHERE trw.tot_price + irk.item_price + Nvl(ipr.sum_price, 0) <= irk.max_price
       AND trw.tot_value + irk.item_value + Nvl(ivr.sum_value, 0) >= irk.min_value
       AND (trw.path_rnk <= irk.keep_num OR irk.keep_num = 0)
       AND trw.lev < irk.seq_size
       AND CASE irk.category_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
       AND irk.seq_size - (trw.lev + 1) + Least(CASE irk.category_id 
                                              WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
                                              irk.min_items)
           >= irk.min_remain
       AND (irk.category_id = trw.cat_id OR trw.same_cats >= trw.min_items)
       AND (irk.category_id = trw.cat_id OR irk.category_id = Nvl(trw.next_cat, irk.category_id))
)
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM tree_walk
 WHERE lev = To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE'))
/
PROMPT View rsf_irk_irs_tabs_v...
CREATE OR REPLACE VIEW rsf_irk_irs_tabs_v AS
WITH tree_walk(path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat_id, same_cats, min_items, cats_path, path, seq_size) AS (
    SELECT 0, 0, 0, 0, 0, 'AL', cat_id, 0, 0, '','', To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE'))
      FROM items_ranked
     WHERE item_rnk = 1
     UNION ALL
    SELECT Row_Number() OVER (PARTITION BY trw.cats_path || irk.cat_id ORDER BY trw.tot_value + irk.item_value DESC),
           irk.item_rnk,
           trw.lev + 1,
           trw.tot_price + irk.item_price,
           trw.tot_value + irk.item_value,
           irk.cat_id,
           irk.next_cat_id,
           CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
           irk.min_items,
           trw.cats_path || irk.cat_id,
           trw.path || irk.item_id,
           trw.seq_size
      FROM tree_walk trw
      JOIN items_ranked irk
        ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (trw.seq_size - trw.lev - 1))
      LEFT JOIN item_running_sums irs
        ON irs.slot_index = trw.seq_size - trw.lev - 1
     WHERE trw.tot_price + irk.item_price + Nvl(irs.sum_price, 0) <= To_Number(SYS_Context('RECURSION_CTX', 'MAX_PRICE'))
       AND trw.tot_value + irk.item_value + Nvl(irs.sum_value, 0) >= To_Number(SYS_Context('RECURSION_CTX', 'MIN_VALUE'))
       AND trw.lev < trw.seq_size
       AND CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
       AND trw.seq_size - (trw.lev + 1) + Least(CASE irk.cat_id 
                                              WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
                                              irk.min_items)
           >= irk.min_remain
       AND (irk.cat_id = trw.cat_id OR trw.same_cats >= trw.min_items)
       AND (irk.cat_id = trw.cat_id OR irk.cat_id = Nvl(trw.next_cat_id, irk.cat_id))
       AND (trw.path_rnk <= To_Number(SYS_Context('RECURSION_CTX', 'KEEP_NUM')) OR To_Number(Nvl(SYS_Context('RECURSION_CTX', 'KEEP_NUM'), '0')) = 0)
)
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM tree_walk
 WHERE lev = seq_size
/
PROMPT View rsf_irk_tab_where_fun_v...
CREATE OR REPLACE VIEW rsf_irk_tab_where_fun_v AS
WITH tree_walk(path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat_id, same_cats, min_items, cats_path, path, seq_size) AS (
    SELECT 0, 0, 0, 0, 0, 'AL', cat_id, 0, 0, '','', To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE'))
      FROM items_ranked
     WHERE item_rnk = 1
     UNION ALL
    SELECT Row_Number() OVER (PARTITION BY trw.cats_path || irk.cat_id ORDER BY trw.tot_value + irk.item_value DESC),
           irk.item_rnk,
           trw.lev + 1,
           trw.tot_price + irk.item_price,
           trw.tot_value + irk.item_value,
           irk.cat_id,
           irk.next_cat_id,
           CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
           irk.min_items,
           trw.cats_path || irk.cat_id,
           trw.path || irk.item_id,
           trw.seq_size
      FROM tree_walk trw
      JOIN items_ranked irk
        ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (trw.seq_size - trw.lev - 1))
     WHERE Item_Cat_Seqs.Record_Is_Ok(p_lev             => trw.lev,
                                      p_tot_value       => trw.tot_value + irk.item_value,
                                      p_tot_price       => trw.tot_price + irk.item_price,
                                      p_cat_id          => trw.cat_id,
                                      p_cat_id_new      => irk.cat_id,
                                      p_same_cats       => trw.same_cats,
                                      p_next_cat_id     => trw.next_cat_id,
                                      p_min_items       => trw.min_items,
                                      p_min_items_new   => irk.min_items,
                                      p_max_items_new   => irk.max_items,
                                      p_min_remain_new  => irk.min_remain) = 'Y'
            AND (trw.path_rnk <= To_Number(SYS_Context('RECURSION_CTX', 'KEEP_NUM')) OR To_Number(Nvl(SYS_Context('RECURSION_CTX', 'KEEP_NUM'), '0')) = 0)
)
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM tree_walk
 WHERE lev = seq_size
/
PROMPT View rsf_irk_tab_where_fun_ts_v...
CREATE OR REPLACE VIEW rsf_irk_tab_where_fun_ts_v AS
WITH tree_walk(path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat_id, same_cats, min_items, cats_path, path, seq_size) AS (
    SELECT 0, 0, 0, 0, 0, 'AL', cat_id, 0, 0, '','', To_Number(SYS_Context('RECURSION_CTX', 'SEQ_SIZE'))
      FROM items_ranked
     WHERE item_rnk = 1
     UNION ALL
    SELECT Row_Number() OVER (PARTITION BY trw.cats_path || irk.cat_id ORDER BY trw.tot_value + irk.item_value DESC),
           irk.item_rnk,
           trw.lev + 1,
           trw.tot_price + irk.item_price,
           trw.tot_value + irk.item_value,
           irk.cat_id,
           irk.next_cat_id,
           CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
           irk.min_items,
           trw.cats_path || irk.cat_id,
           trw.path || irk.item_id,
           trw.seq_size
      FROM tree_walk trw
      JOIN items_ranked irk
        ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (trw.seq_size - trw.lev - 1))
     WHERE Item_Cat_Seqs.Record_Is_Ok_TS(p_lev             => trw.lev,
                                         p_tot_value       => trw.tot_value + irk.item_value,
                                         p_tot_price       => trw.tot_price + irk.item_price,
                                         p_cat_id          => trw.cat_id,
                                         p_cat_id_new      => irk.cat_id,
                                         p_same_cats       => trw.same_cats,
                                         p_next_cat_id     => trw.next_cat_id,
                                         p_min_items       => trw.min_items,
                                         p_min_items_new   => irk.min_items,
                                         p_max_items_new   => irk.max_items,
                                         p_min_remain_new  => irk.min_remain) = 'Y'
            AND (trw.path_rnk <= To_Number(SYS_Context('RECURSION_CTX', 'KEEP_NUM')) OR To_Number(Nvl(SYS_Context('RECURSION_CTX', 'KEEP_NUM'), '0')) = 0)
)
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM tree_walk
 WHERE lev = seq_size
/
PROMPT View paths_ranked_v...
CREATE OR REPLACE VIEW paths_ranked_v AS
SELECT path,
       tot_price,
       tot_value,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM paths
/
PROMPT View paths_base_ranked_v...
CREATE OR REPLACE VIEW paths_base_ranked_v AS
SELECT path,
       tot_price,
       tot_value,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM paths_base
/
PROMPT View category_rsums_v...
CREATE OR REPLACE VIEW category_rsums_v AS
    SELECT id, min_items, max_items, 
           Sum(CASE WHEN id != 'AL' THEN min_items END) 
             OVER (ORDER BY CASE WHEN id = 'AL' THEN 2 ELSE 1 END, 
                            CASE WHEN min_items > 0 THEN max_items - min_items END DESC, 
                            min_items, 
                            max_items DESC, 
                            id DESC)                      min_remain,
           Lead(CASE WHEN min_items > 0 THEN id END) 
            OVER (ORDER BY CASE WHEN id = 'AL' THEN 2 ELSE 1 END, 
                           CASE WHEN min_items > 0 THEN max_items - min_items END, 
                           min_items DESC, 
                           max_items, 
                           id)                            next_cat_id,
           Row_Number() 
                    OVER (ORDER BY CASE WHEN id = 'AL' THEN 2 ELSE 1 END, 
                                   CASE WHEN min_items > 0 THEN max_items - min_items END, 
                                   min_items DESC, 
                                   max_items, 
                                   id)                    cat_rnk,
           MAX(CASE WHEN id != 'AL' THEN max_items END) OVER () max_max_items
      FROM categories
     WHERE max_items > 0
/
PROMPT View paths_link_ranked_item_v...
CREATE OR REPLACE VIEW paths_link_ranked_item_v AS
WITH paths_ranked AS (
    SELECT iln_id, item_rnk, prior_iln_id, tot_value, tot_price,
           Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
      FROM paths_link
), rsf (iln_id, item_rnk, prior_iln_id, lev, tot_value, tot_price, rnk) AS (
    SELECT iln_id, item_rnk, prior_iln_id, 0, tot_value, tot_price, rnk
      FROM paths_ranked
     WHERE rnk <= To_Number(SYS_Context('RECURSION_CTX', 'TOP_N'))
     UNION ALL
    SELECT iln.id, iln.item_rnk, iln.prior_iln_id, rsf.lev + 1,
           rsf.tot_value, rsf.tot_price, rsf.rnk
      FROM rsf
      JOIN item_links iln
        ON iln.id = rsf.prior_iln_id
     WHERE iln.id > 0
), item_map AS (
    SELECT itm.id item_id,
           itm.category_id,
           itm.item_name,
           itm.item_value,
           itm.item_price,
           Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id) item_rnk
      FROM items itm
      JOIN category_rsums_v crs
        ON crs.id = itm.category_id
)
SELECT rsf.tot_value,
       rsf.tot_price,
       rsf.rnk,
       rsf.lev,
       imp.category_id,
       imp.item_id,
       imp.item_name,
       imp.item_value,
       imp.item_price
  FROM rsf
  JOIN items_ranked_link irk
    ON irk.item_rnk = rsf.item_rnk
  JOIN item_map imp
    ON imp.item_rnk = irk.item_rnk
/
PROMPT View paths_link_ranked_path_v...
CREATE OR REPLACE VIEW paths_link_ranked_path_v AS
SELECT ListAgg(item_id) WITHIN GROUP (ORDER BY lev DESC) path,
       tot_value,
       tot_price,
       rnk
  FROM paths_link_ranked_item_v
 GROUP BY tot_value,
          tot_price,
          rnk
/
PROMPT View paths_base_link_ranked_item_v...
CREATE OR REPLACE VIEW paths_base_link_ranked_item_v AS
WITH paths_ranked AS (
    SELECT ibl_id, item_rnk, prior_ibl_id, tot_value, tot_price,
           Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
      FROM paths_base_link
), rsf (ibl_id, item_rnk, prior_ibl_id, lev, tot_value, tot_price, rnk) AS (
    SELECT ibl_id, item_rnk, prior_ibl_id, 0, tot_value, tot_price, rnk
      FROM paths_ranked
     WHERE rnk <= To_Number(SYS_Context('RECURSION_CTX', 'TOP_N'))
     UNION ALL
    SELECT ibl.id, ibl.item_rnk, ibl.prior_ibl_id, rsf.lev + 1,
           rsf.tot_value, rsf.tot_price, rsf.rnk
      FROM rsf
      JOIN item_base_links ibl
        ON ibl.id = rsf.prior_ibl_id
     WHERE ibl.id > 0
), item_map AS (
    SELECT itm.id item_id,
           itm.category_id,
           itm.item_name,
           itm.item_value,
           itm.item_price,
           Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id) item_rnk
      FROM items itm
      JOIN category_rsums_v crs
        ON crs.id = itm.category_id
)
SELECT rsf.tot_value,
       rsf.tot_price,
       rsf.rnk,
       rsf.lev,
       imp.category_id,
       imp.item_id,
       imp.item_name,
       imp.item_value,
       imp.item_price
  FROM rsf
  JOIN items_ranked_base_link irk
    ON irk.item_rnk = rsf.item_rnk
  JOIN item_map imp
    ON imp.item_rnk = irk.item_rnk
/
PROMPT View paths_base_link_ranked_path_v...
CREATE OR REPLACE VIEW paths_base_link_ranked_path_v AS
SELECT ListAgg(item_id) WITHIN GROUP (ORDER BY lev DESC) path,
       tot_value,
       tot_price,
       rnk
  FROM paths_base_link_ranked_item_v
 GROUP BY tot_value,
          tot_price,
          rnk
/
PROMPT View array_recurse_v...
CREATE OR REPLACE VIEW array_recurse_v AS
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM TABLE(Item_Cat_Seqs.Array_Recurse)
/
PROMPT View array_iterate_v...
CREATE OR REPLACE VIEW array_iterate_v AS
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM TABLE(Item_Cat_Seqs.Array_Iterate)
/
PROMPT View iteratively_refine_recurse_v...
CREATE OR REPLACE VIEW iteratively_refine_recurse_v AS
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM TABLE(Item_Cat_Seqs.Iteratively_Refine_Recurse)
/
PROMPT View iteratively_refine_rsf_v...
CREATE OR REPLACE VIEW iteratively_refine_rsf_v AS
SELECT path,
       tot_value,
       tot_price,
       Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
  FROM TABLE(Item_Cat_Seqs.Iteratively_Refine_RSF)
/
