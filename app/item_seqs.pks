/***************************************************************************************************
Name: item_seqs.pks                    Author: Brendan Furey                       Date: 30-Jun-2024

Component package script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PACKAGES
====================================================================================================
|  Package             | Notes                                                                     |
|==================================================================================================|
| *Item_Seqs*          | Sequence generation methods                                               |
|  Item_Cat_Seqs       | PL/SQL driven base solution methods for the items and categories problem  |
|  TT_Item_Cat_Seqs    | Unit testing the solution methods for the items and categories problem    |
====================================================================================================

This file has the Item_Seqs package spec
***************************************************************************************************/
CREATE OR REPLACE PACKAGE Item_Seqs AS

TYPE paths_arr IS TABLE OF small_paths%ROWTYPE;

FUNCTION Seq_Type_Condition_YN(
            p_seq_type                     VARCHAR2,
            p_item_id                      VARCHAR2,
            p_item_id_prior                VARCHAR2,
            p_path                         VARCHAR2)
            RETURN                         VARCHAR2;

FUNCTION Array_Recurse(
            p_seq_type                     VARCHAR2,
            p_lev                          PLS_INTEGER := NULL)
            RETURN                         paths_arr PIPELINED;
PROCEDURE Pop_Table_Recurse(
            p_seq_type                     VARCHAR2,
            p_lev                          PLS_INTEGER := NULL);

FUNCTION Array_Iterate(
            p_seq_type                     VARCHAR2)
            RETURN                         paths_arr PIPELINED;
PROCEDURE Pop_Table_Iterate(
            p_seq_type                     VARCHAR2);

END Item_Seqs;
/
SHO ERR
