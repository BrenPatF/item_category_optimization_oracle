/***************************************************************************************************
Name: tt_item_cat_seqs.pkb             Author: Brendan Furey                       Date: 30-Jun-2024

Component package script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PACKAGES
====================================================================================================
|  Package             | Notes                                                                     |
|==================================================================================================|
|  Item_Seqs           | Sequence generation methods                                               |
|  Item_Cat_Seqs       | PL/SQL driven base solution methods for the items and categories problem  |
| *TT_Item_Cat_Seqs*   | Unit testing the solution methods for the items and categories problem    |
====================================================================================================

This file has the TT_Item_Cat_Seqs package body
***************************************************************************************************/
CREATE OR REPLACE PACKAGE BODY TT_Item_Cat_Seqs AS

PROCEDURE add_Cats(
            p_cat_2lis                     L2_chr_arr) IS
BEGIN

  FOR i IN 1..p_cat_2lis.COUNT LOOP
    INSERT INTO small_categories VALUES (p_cat_2lis(i)(1), p_cat_2lis(i)(2), p_cat_2lis(i)(3));
  END LOOP;

END add_Cats;

PROCEDURE add_Items(
            p_item_2lis                    L2_chr_arr) IS
BEGIN

  FOR i IN 1..p_item_2lis.COUNT LOOP
    INSERT INTO small_items VALUES (p_item_2lis(i)(1), p_item_2lis(i)(1), p_item_2lis(i)(2), p_item_2lis(i)(3), p_item_2lis(i)(4));
  END LOOP;

END add_Items;

PROCEDURE add_Scalars(
            p_scalar_lis                   L1_chr_arr) IS
BEGIN

  Item_Cat_Seqs.Set_Contexts(
            p_seq_size       => p_scalar_lis(1),
            p_max_price      => p_scalar_lis(2),
            p_top_n          => p_scalar_lis(3),
            p_min_value      => p_scalar_lis(4),
            p_keep_num       => p_scalar_lis(5),
            p_item_width     => '2'); -- for post valid view

END add_Scalars;

/***************************************************************************************************

purely_Wrap_Best_Combis: Base unit test wrapper function for Best Combis views

    Returns the 'actual' outputs, given the inputs for a scenario, with the signature expected for
    the Math Function Unit Testing design pattern, namely:

      Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
      Return Value: 2-level list (type L2_chr_arr) with test outputs as group/record (with record as
                   delimited fields string)

    Called by: Purely_Wrap_Pre_Emptive (passing view best_combis_pre_emptive_v)
               Purely_Wrap_Post_Valid (passing view best_combis_post_valid_v)
***************************************************************************************************/
FUNCTION purely_Wrap_Best_Combis(
              p_view_name                    VARCHAR2,
              p_inp_3lis                     L3_chr_arr,
              p_proc_name                    VARCHAR2 := NULL)
              RETURN                         L2_chr_arr IS
  l_act_2lis        L2_chr_arr := L2_chr_arr();
  l_scalar_lis      L1_chr_arr := p_inp_3lis(3)(1);
  l_result_lis      L1_chr_arr;
  l_n_rows          PLS_INTEGER;
  l_path_len        PLS_INTEGER;
  l_params          VARCHAR2(4000);
BEGIN

  DELETE small_categories;
  DELETE small_items;
  add_Cats(p_cat_2lis       => p_inp_3lis(1));
  add_Items(p_item_2lis     => p_inp_3lis(2));
  add_Scalars(p_scalar_lis  => l_scalar_lis);

  IF p_proc_name IN ('Init_Loop', 'Iteratively_Refine_Iterate') THEN
    l_params := '(' || l_scalar_lis(5) || ', 10)';
  ELSIF p_proc_name = 'Init' OR p_proc_name LIKE 'Pop_Table%' THEN
    l_params := '(' || l_scalar_lis(5) || ', ' || l_scalar_lis(4) || ')';
  END IF;

  IF p_proc_name IS NOT NULL THEN
    EXECUTE IMMEDIATE 'BEGIN Item_Cat_Seqs.' || p_proc_name || l_params || '; END;';
  END IF;

  l_act_2lis.EXTEND;

  l_result_lis := Utils.View_To_List(
                                p_view_name     => p_view_name,
                                p_sel_value_lis => L1_chr_arr('path', 'tot_price', 'tot_value'),
                                p_where         => 'rnk <= ' || l_scalar_lis(3),
                                p_order_by      => 'rnk');

  l_path_len := 2 * To_Number(l_scalar_lis(1));
  l_act_2lis(1) := L1_chr_arr();

  FOR i IN 1..l_result_lis.COUNT LOOP

    l_act_2lis(1).EXTEND;
    l_act_2lis(1)(i) := Item_Cat_Seqs.Norm_Path(p_path      => Substr(l_result_lis(i), 1, l_path_len),
                                                p_token_len => 2) || 
                                                               Substr(l_result_lis(i), l_path_len + 1);

  END LOOP;

  ROLLBACK;
  RETURN l_act_2lis;

END purely_Wrap_Best_Combis;

FUNCTION RSF_Post_Valid(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'rsf_post_valid_v',
              p_inp_3lis    => p_inp_3lis);

END RSF_Post_Valid;

FUNCTION RSF_SQL(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'rsf_sql_v',
              p_inp_3lis    => p_inp_3lis);

END RSF_SQL;

FUNCTION RSF_SQL_Material(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'rsf_sql_material_v',
              p_inp_3lis    => p_inp_3lis);

END RSF_SQL_Material;

FUNCTION RSF_Irk_IRS_Tabs(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'rsf_irk_irs_tabs_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Init');

END RSF_Irk_IRS_Tabs;

FUNCTION RSF_Irk_Tab_Where_Fun(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'rsf_irk_tab_where_fun_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Init');

END RSF_Irk_Tab_Where_Fun;

FUNCTION Pop_Table_Iterate(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'paths_ranked_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Pop_Table_Iterate');

END Pop_Table_Iterate;

FUNCTION Pop_Table_Iterate_Base(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'paths_base_ranked_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Pop_Table_Iterate_Base');

END Pop_Table_Iterate_Base;

FUNCTION Pop_Table_Iterate_Link(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'paths_link_ranked_path_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Pop_Table_Iterate_Link');

END Pop_Table_Iterate_Link;

FUNCTION Pop_Table_Iterate_Base_Link(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'paths_base_link_ranked_path_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Pop_Table_Iterate_Base_Link');

END Pop_Table_Iterate_Base_Link;

FUNCTION Array_Iterate(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'array_iterate_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Init');

END Array_Iterate;

FUNCTION Pop_Table_Recurse(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'paths_ranked_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Pop_Table_Recurse');

END Pop_Table_Recurse;

FUNCTION Array_Recurse(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'array_recurse_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Init');

END Array_Recurse;

FUNCTION Iteratively_Refine_Recurse(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'iteratively_refine_recurse_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Init_Loop');

END Iteratively_Refine_Recurse;

FUNCTION Iteratively_Refine_Iterate(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'paths_ranked_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Iteratively_Refine_Iterate');

END Iteratively_Refine_Iterate;

FUNCTION Iteratively_Refine_RSF(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr IS
BEGIN

    RETURN purely_Wrap_Best_Combis(
              p_view_name   => 'iteratively_refine_rsf_v',
              p_inp_3lis    => p_inp_3lis,
              p_proc_name   => 'Init_Loop');

END Iteratively_Refine_RSF;

END TT_Item_Cat_Seqs;
/
SHO ERR