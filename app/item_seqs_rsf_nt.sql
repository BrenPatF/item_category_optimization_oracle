/***************************************************************************************************
Name: item_seqs_rsf_nt.sql             Author: Brendan Furey                       Date: 07-Jul-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project, for the
item sequence generation methods

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

====================================================================================================
|  SQL Script               | Description                                                          |
|===================================================================================================
RUN SCRIPTS
====================================================================================================
|  item_seqs_rsf.sql        | Runs recursive subquery factor methods for all 4 types, with path as |
|                           | string                                                               | 
|  item_seqs_rsf_cycle.sql  | Runs analysis queries for CYCLE issues                               | 
| *item_seqs_rsf_nt.sql*    | Runs recursive subquery factor methods for all 4 types, with path as |
|                           | nested table array                                                   |
|  item_seqs_pls.sql        | Runs PL/SQL methods for a single type                                | 
====================================================================================================

This file has the script to run the recursive subquery factor methods for all 4 types, with path as
nested table array 
***************************************************************************************************/
DEFINE SEQ_SIZE = 3
DEFINE N_ITEMS = 6
@..\..\install_prereq\initspool item_seqs_rsf_nt
CREATE OR REPLACE TYPE char_nt AS TABLE OF VARCHAR2(4000)
/
COLUMN tot_price HEADING "Total Price" FORMAT 9999999990
COLUMN tot_value HEADING "Total Value" FORMAT 9999999990
COLUMN path HEADING "Path" FORMAT A30
PROMPT MP: Multiset Permutation [Items may repeat, order matters] - Nested Table 
WITH tree_walk(item_id, lev, tot_price, tot_value, path, path_uid) AS (
    SELECT '0', 0, 0, 0, char_nt(), 0
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path MULTISET UNION char_nt(itm.id),
           trw.lev * &N_ITEMS + ROWNUM
      FROM tree_walk trw
      JOIN items itm
        ON trw.lev < &SEQ_SIZE
)
SELECT ListAgg(pth.COLUMN_VALUE, '') path,
       trw.tot_price, trw.tot_value
  FROM tree_walk trw
 CROSS APPLY TABLE(trw.path) pth
 WHERE lev = &SEQ_SIZE
 GROUP BY trw.path_uid, trw.tot_price, trw.tot_value
 ORDER BY 1
/
PROMPT MC: Multiset Combination [Items may repeat, order does not matter] - Nested Table 
WITH tree_walk(item_id, lev, tot_price, tot_value, path, path_uid) AS (
    SELECT '0', 0, 0, 0, char_nt(), 0
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path MULTISET UNION char_nt(itm.id),
           trw.lev * &N_ITEMS + ROWNUM
      FROM tree_walk trw
      JOIN items itm
        ON itm.id >= trw.item_id
       AND trw.lev < &SEQ_SIZE
)
SELECT ListAgg(pth.COLUMN_VALUE, '') path,
       trw.tot_price, trw.tot_value
  FROM tree_walk trw
 CROSS APPLY TABLE(trw.path) pth
 WHERE lev = &SEQ_SIZE
 GROUP BY trw.path_uid, trw.tot_price, trw.tot_value
 ORDER BY 1
/
PROMPT SP: Set Permutation [Items may not repeat, order matters] - Nested Table 
WITH tree_walk(item_id, lev, tot_price, tot_value, path, path_uid) AS (
    SELECT '0', 0, 0, 0, char_nt(), 0
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path MULTISET UNION char_nt(itm.id),
           trw.lev * &N_ITEMS + ROWNUM
      FROM tree_walk trw
      JOIN items itm
        ON NOT EXISTS (SELECT 1
                         FROM TABLE(trw.path) pth
                        WHERE pth.COLUMN_VALUE = itm.id)
     WHERE trw.lev < &SEQ_SIZE
) CYCLE lev SET c TO '*' DEFAULT ' '
SELECT ListAgg(pth.COLUMN_VALUE, '') path,
       trw.tot_price, trw.tot_value
  FROM tree_walk trw
 CROSS APPLY TABLE(trw.path) pth
 WHERE lev = &SEQ_SIZE
 GROUP BY trw.path_uid, trw.tot_price, trw.tot_value
 ORDER BY 1
/
PROMPT SC: Set Combination [Items may not repeat, order does not matter] - Nested Table 
WITH tree_walk(item_id, lev, tot_price, tot_value, path, path_uid) AS (
    SELECT '0', 0, 0, 0, char_nt(), 0
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path MULTISET UNION char_nt(itm.id),
           trw.lev * &N_ITEMS + ROWNUM
      FROM tree_walk trw
      JOIN items itm
        ON itm.id > trw.item_id
     WHERE trw.lev < &SEQ_SIZE
)
SELECT ListAgg(pth.COLUMN_VALUE, '') path,
       trw.tot_price, trw.tot_value
  FROM tree_walk trw
 CROSS APPLY TABLE(trw.path) pth
 WHERE lev = &SEQ_SIZE
 GROUP BY trw.path_uid, trw.tot_price, trw.tot_value
 ORDER BY 1
/
@..\..\install_prereq\endspool