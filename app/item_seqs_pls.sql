/***************************************************************************************************
Name: item_seqs_pls.sql                Author: Brendan Furey                       Date: 07-Jul-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project, for the
item sequence generation methods

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PARAMETERS
==========
SEQ_TP = Sequence type code:
            MP - Multiset permutation
            MC - Multiset combination
            SP - Set permutation
            SC - Set permutation

====================================================================================================
|  SQL Script               | Description                                                          |
|===================================================================================================
RUN SCRIPTS
====================================================================================================
|  item_seqs_rsf.sql        | Runs recursive subquery factor methods for all 4 types, with path as |
|                           | string                                                               | 
|  item_seqs_rsf_cycle.sql  | Runs analysis queries for CYCLE issues                               | 
|  item_seqs_rsf_nt.sql     | Runs recursive subquery factor methods for all 4 types, with path as |
|                           | nested table array                                                   |
| *item_seqs_pls.sql*       | Runs PL/SQL methods for a single type                                | 
====================================================================================================

This file has the script to run the PL/SQL methods for a single type
***************************************************************************************************/
DEFINE SEQ_TP = &1
DEFINE SEQ_SIZE = 3
@..\..\install_prereq\initspool item_seqs_&SEQ_TP
PROMPT Four PL/SQL methods for sequence type &SEQ_TP
PROMPT ========================================
COLUMN PATH FORMAT A4
COLUMN tot_price FORMAT 9999990
COLUMN tot_value FORMAT 9999990
PROMPT Pop_Table_Iterate - &SEQ_TP
BEGIN
  Item_Seqs.Pop_Table_Iterate(p_seq_type => '&SEQ_TP');
END;
/
SELECT path, tot_price, tot_value
  FROM small_paths
 ORDER BY 1
/
PROMPT Pop_Table_Recurse - &SEQ_TP
BEGIN
  Item_Seqs.Pop_Table_Recurse(p_seq_type => '&SEQ_TP');
END;
/
SELECT path, tot_price, tot_value
  FROM small_paths
 WHERE lev = &SEQ_SIZE
 ORDER BY 1
/
PROMPT Array_Iterate - &SEQ_TP
SELECT path, tot_price, tot_value
  FROM Item_Seqs.Array_Iterate(p_seq_type => '&SEQ_TP')
 ORDER BY 1
/
PROMPT Array_Recurse - &SEQ_TP
SELECT path, tot_price, tot_value
  FROM Item_Seqs.Array_Recurse(p_seq_type => '&SEQ_TP')
 WHERE lev = &SEQ_SIZE
 ORDER BY 1
/
@..\..\install_prereq\endspool
