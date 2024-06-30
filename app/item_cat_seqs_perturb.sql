/***************************************************************************************************
Name: item_cat_seqs_perturb.sql        Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PARAMETERS
==========
DS        = Dataset code (SML/BRA/ENG)
MAX_PRICE = Maximum price

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
| *item_cat_seqs_perturb.sql* | Runs perturbation analysis                                         | 
|  item_cat_seqs_pv_rsf.sql   | Runs Post-Validation recursive subquery factor method              | 
|  item_cat_seqs_rsf.sql      | Runs recursive subquery factor methods with pre-emptive filtering  | 
|  item_cat_seqs.sql          | Runs PL/SQL driven base methods                                    | 
|  item_seqs.sql              | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to run the perturbation analysis
***************************************************************************************************/
DEFINE DS = &1
DEFINE MAX_PRICE = &2
BREAK ON tot_value ON tot_price ON rnk ON category_id
@..\..\install_prereq\initspool item_cat_seqs_perturb_&DS._&MAX_PRICE
PROMPT Truncate paths
TRUNCATE TABLE paths
/
BEGIN
    :MAX_PRICE := &MAX_PRICE;
END;
/
@..\set_contexts
VAR TIMER_SET NUMBER
BEGIN
  :TIMER_SET := Timer_Set.Construct('Item_Cat_Seqs_Perturb');
END;
/
SET TIMING ON
VAR start_time VARCHAR2(30)
PROMPT Pop_Table_Iterate
BEGIN
  SELECT To_Char(SYSDATE, 'DD/MM/YYYY hh24:mi:ss')
    INTO :start_time
    FROM DUAL;
  Item_Cat_Seqs.Iteratively_Refine_Iterate(p_keep_start      => :KEEP_START, 
                                           p_keep_factor     => :KEEP_FACTOR);
END;
/
SET LINES 220
COLUMN "Summary" FORMAT A200
PROMPT Iteratively_Refine_Iterate - 10'th to 1'st highest values, then corresponding prices
SELECT :MAX_PRICE || ', ' || 
       Max(CASE WHEN rnk = 10 THEN tot_value END) || ', ' ||
       Max(CASE WHEN rnk = 9 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 8 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 7 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 6 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 5 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 4 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 3 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 2 THEN tot_value END)  || ', ' ||
       Max(CASE WHEN rnk = 1 THEN tot_value END)  || '; Prices: ' ||
       Max(CASE WHEN rnk = 10 THEN tot_price END) || ', ' ||
       Max(CASE WHEN rnk = 9 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 8 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 7 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 6 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 5 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 4 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 3 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 2 THEN tot_price END)  || ', ' ||
       Max(CASE WHEN rnk = 1 THEN tot_price END)  || '; ' ||
       86400 * (SYSDATE -  To_Date(:start_time, 'DD/MM/YYYY hh24:mi:ss'))  || ' : Values, Prices, Seconds ' "Summary"
  FROM paths_ranked_v
 WHERE rnk <= :TOP_N
/
PROMPT Iteratively_Refine_Iterate - Best and Worst
WITH nos AS (
    SELECT Max(tot_value) KEEP (DENSE_RANK FIRST ORDER BY rnk) max_tot_value,
           Max(tot_price) KEEP (DENSE_RANK FIRST ORDER BY rnk) max_tot_price,
           Min(tot_value) KEEP (DENSE_RANK LAST ORDER BY rnk) min_tot_value,
           Min(tot_price) KEEP (DENSE_RANK LAST ORDER BY rnk) min_tot_price,
           86400 * (SYSDATE -  To_Date(:start_time, 'DD/MM/YYYY hh24:mi:ss')) secs
      FROM paths_ranked_v
     WHERE rnk <= :TOP_N
)
SELECT :MAX_PRICE || ', ' || Nvl(max_tot_value, 0) || ', ' || Nvl(min_tot_value, 0) || ', ' || secs ||
       ' - BEST (V, P): (' || max_tot_value || ', ' ||
       max_tot_price || '); WORST (V, P): (' ||
       min_tot_value || ', ' ||
       min_tot_price || '); Seconds: ' ||
       secs "Summary"
  FROM nos
/
PROMPT Iteratively_Refine_Iterate
SELECT path,
       tot_value,
       tot_price,
       rnk
  FROM paths_ranked_v
 WHERE rnk <= :TOP_N
ORDER BY rnk, tot_price 
/
EXEC Timer_Set.Increment_Time(:TIMER_SET, 'Iteratively_Refine_Iterate - path level');
SET TIMING OFF
EXEC Utils.W(Timer_Set.Format_Results(:TIMER_SET));
@..\..\install_prereq\endspool
