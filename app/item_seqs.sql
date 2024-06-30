/***************************************************************************************************
Name: item_seqs.sql                    Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PARAMETERS
==========/***************************************************************************************************
Name: SCRIPT.sql                       Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

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
|  item_cat_seqs.sql          | Runs PL/SQL driven base methods                                    | 
| *item_seqs.sql*             | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to run the sequence generation methods
***************************************************************************************************/

SEQ_TP = Sequence type code:
            MP - Multiset permutation
            MC - Multiset combination
            SP - Set permutation
            SC - Set permutation

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
|  item_cat_seqs.sql          | Runs PL/SQL driven base methods                                    | 
| *item_seqs.sql*             | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to run the sequence generation methods
***************************************************************************************************/
DEFINE DS = &1
DEFINE SEQ_TP = &2
DEFINE SEQ_SIZE = 3
@..\..\install_prereq\initspool item_seqs_&DS._&SEQ_TP
@..\set_contexts
PROMPT Pop_Table_Iterate
BEGIN
  Item_Seqs.Pop_Table_Iterate(p_seq_type => '&SEQ_TP');
END;
/
SELECT path, tot_price, tot_value
  FROM small_paths
 ORDER BY 1
/
PROMPT Pop_Table_Recurse
BEGIN
  Item_Seqs.Pop_Table_Recurse(p_seq_type => '&SEQ_TP');
END;
/
SELECT path, tot_price, tot_value
  FROM small_paths
 WHERE lev = &SEQ_SIZE
 ORDER BY 1
/
PROMPT Array_Iterate
SELECT path, tot_price, tot_value
  FROM Item_Seqs.Array_Iterate(p_seq_type => '&SEQ_TP')
 ORDER BY 1
/
PROMPT Array_Recurse
SELECT path, tot_price, tot_value
  FROM Item_Seqs.Array_Recurse(p_seq_type => '&SEQ_TP')
 WHERE lev = &SEQ_SIZE
 ORDER BY 1
/
PROMPT item_seqs_rsf_v
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
      ON Item_Seqs.Seq_Type_Condition_YN(
                    p_seq_type       => '&SEQ_TP',
                    p_item_id        => itm.id,
                    p_item_id_prior  => trw.item_id,
                    p_path           => trw.path) = 'Y'
       AND trw.lev < &SEQ_SIZE
)
SELECT path, tot_price, tot_value
  FROM tree_walk
 WHERE lev = &SEQ_SIZE
/

@..\..\install_prereq\endspool