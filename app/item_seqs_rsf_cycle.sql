/***************************************************************************************************
Name: item_seqs_rsf_cycle.sql          Author: Brendan Furey                       Date: 07-Jul-2024

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
| *item_seqs_rsf_cycle.sql* | Runs analysis queries for CYCLE issues                               | 
|  item_seqs_rsf_nt.sql     | Runs recursive subquery factor methods for all 4 types, with path as |
|                           | nested table array                                                   |
|  item_seqs_pls.sql        | Runs PL/SQL methods for a single type                                | 
====================================================================================================

This file has the script to run the analysis queries for CYCLE issues
***************************************************************************************************/
DEFINE SEQ_SIZE = 3
@..\..\install_prereq\initspool item_seqs_rsf_cycle
PROMPT MP CROSS JOIN, WHERE lev - ORA-32044
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
     CROSS JOIN items itm
     WHERE trw.lev < &SEQ_SIZE
)
SELECT path, tot_price, tot_value
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/
PROMPT MP CROSS JOIN, WHERE lev - CYCLE lev - ok
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
     CROSS JOIN items itm
     WHERE trw.lev < &SEQ_SIZE
) CYCLE lev SET c TO '*' DEFAULT ' '
SELECT path, tot_price, tot_value, c
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/
PROMPT MP CROSS JOIN, WHERE lev - CYCLE lev - all iterations - ok
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
     CROSS JOIN items itm
     WHERE trw.lev < &SEQ_SIZE
) CYCLE lev SET c TO '*' DEFAULT ' '
SELECT path, tot_price, tot_value, c
  FROM tree_walk
/
PROMPT MP JOIN on lev - ok
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
      JOIN items itm
        ON trw.lev < &SEQ_SIZE
)
SELECT path, tot_price, tot_value
  FROM tree_walk
WHERE lev = &SEQ_SIZE
/
PROMPT SP JOIN on path, WHERE lev - ok
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
      JOIN items itm
        ON Nvl(trw.path,'x') NOT LIKE '%' || itm.id || '%'
     WHERE trw.lev < &SEQ_SIZE
)
SELECT path, tot_price, tot_value
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/
PROMPT MC JOIN item_id, WHERE lev - ORA-32044
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
      JOIN items itm
        ON itm.id >= trw.item_id
     WHERE trw.lev < &SEQ_SIZE
)
SELECT path, tot_price, tot_value
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/
PROMPT MC JOIN item_id, WHERE lev - CYCLE lev - ok
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
      JOIN items itm
        ON itm.id >= trw.item_id
     WHERE trw.lev < &SEQ_SIZE
) CYCLE lev SET c TO '*' DEFAULT ' '
SELECT path, tot_price, tot_value, c
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/

PROMPT MC JOIN item_id and lev - ok
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
      JOIN items itm
        ON itm.id >= trw.item_id
       AND trw.lev < &SEQ_SIZE
)
SELECT path, tot_price, tot_value
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/
PROMPT SC JOIN item_id, WHERE lev - ok
WITH tree_walk(item_id, lev, tot_price, tot_value, path) AS (
    SELECT '0', 0, 0, 0, '' path
      FROM DUAL
     UNION ALL
    SELECT itm.id,
           trw.lev + 1,
           trw.tot_price + itm.item_price,
           trw.tot_value + itm.item_value,
           trw.path || itm.id
      FROM tree_walk trw
      JOIN items itm
        ON itm.id > trw.item_id
     WHERE trw.lev < &SEQ_SIZE
)
SELECT path, tot_price, tot_value
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/
@..\..\install_prereq\endspool