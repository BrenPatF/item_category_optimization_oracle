CREATE OR REPLACE PACKAGE TT_Item_Cat_Seqs AS
/***************************************************************************************************
Name: tt_item_cat_seqs.pks             Author: Brendan Furey                       Date: 30-Jun-2024

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

This file has the TT_Item_Cat_Seqs package spec
***************************************************************************************************/
FUNCTION RSF_Post_Valid(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION RSF_SQL(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION RSF_SQL_Material(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION RSF_Irk_IRS_Tabs(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION RSF_Irk_Tab_Where_Fun(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Pop_Table_Iterate(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Pop_Table_Iterate_Base(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Pop_Table_Iterate_Link(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Pop_Table_Iterate_Base_Link(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Array_Iterate(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Pop_Table_Recurse(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Array_Recurse(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Iteratively_Refine_Recurse(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Iteratively_Refine_Iterate(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;
FUNCTION Iteratively_Refine_RSF(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;

END TT_Item_Cat_Seqs;
/
