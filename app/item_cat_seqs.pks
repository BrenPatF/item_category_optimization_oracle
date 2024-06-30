/***************************************************************************************************
Name: item_cat_seqs.pks                Author: Brendan Furey                       Date: 30-Jun-2024

Component package script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

PACKAGES
====================================================================================================
|  Package             | Notes                                                                     |
|==================================================================================================|
|  Item_Seqs           | Sequence generation methods                                               |
| *Item_Cat_Seqs*      | PL/SQL driven base solution methods for the items and categories problem  |
|  TT_Item_Cat_Seqs    | Unit testing the solution methods for the items and categories problem    |
====================================================================================================

This file has the Item_Cat_Seqs package spec
***************************************************************************************************/
CREATE OR REPLACE PACKAGE Item_Cat_Seqs AS

TYPE item_running_sums_rec IS RECORD (
        slot_index              INTEGER,
        sum_value               INTEGER,
        sum_price               INTEGER
);
TYPE item_running_sums_arr IS TABLE OF item_running_sums_rec;

TYPE paths_arr IS TABLE OF paths%ROWTYPE;

PROCEDURE Set_Contexts(
            p_seq_type                     VARCHAR2 := NULL,
            p_seq_size                     VARCHAR2 := NULL,
            p_max_price                    VARCHAR2 := NULL,
            p_min_value                    VARCHAR2 := NULL,
            p_keep_num                     VARCHAR2 := NULL,
            p_item_width                   VARCHAR2 := NULL,
            p_top_n                        VARCHAR2 := NULL);
FUNCTION Split_Values(
            p_string                       VARCHAR2,
            p_token_len                    PLS_INTEGER)
            RETURN                         L1_chr_arr;
FUNCTION Norm_Path(
            p_path                         VARCHAR2,
            p_token_len                    PLS_INTEGER)
            RETURN                         VARCHAR2;

FUNCTION Record_Is_Ok(
            p_lev                          PLS_INTEGER,
            p_tot_value                    PLS_INTEGER,
            p_tot_price                    PLS_INTEGER,
            p_cat_id                       VARCHAR2,
            p_cat_id_new                   VARCHAR2,
            p_same_cats                    VARCHAR2,
            p_next_cat_id                  VARCHAR2,
            p_min_items                    PLS_INTEGER,
            p_min_items_new                PLS_INTEGER,
            p_max_items_new                PLS_INTEGER,
            p_min_remain_new               PLS_INTEGER)
            RETURN                         VARCHAR2;
FUNCTION Record_Is_Ok_TS(
            p_lev                          PLS_INTEGER,
            p_tot_value                    PLS_INTEGER,
            p_tot_price                    PLS_INTEGER,
            p_cat_id                       VARCHAR2,
            p_cat_id_new                   VARCHAR2,
            p_same_cats                    VARCHAR2,
            p_next_cat_id                  VARCHAR2,
            p_min_items                    PLS_INTEGER,
            p_min_items_new                PLS_INTEGER,
            p_max_items_new                PLS_INTEGER,
            p_min_remain_new               PLS_INTEGER)
            RETURN                         VARCHAR2;
PROCEDURE Write_Init_Timer_Set;
PROCEDURE Init(
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_timing                    BOOLEAN := FALSE);
PROCEDURE Init_Loop(            
            p_keep_start                   PLS_INTEGER, 
            p_keep_factor                  PLS_INTEGER);

PROCEDURE Pop_Table_Iterate(
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_pop_temp                  BOOLEAN := TRUE);
PROCEDURE Pop_Table_Iterate_Base(
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER);
PROCEDURE Pop_Table_Iterate_Link(
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_pop_temp                  BOOLEAN := TRUE);
PROCEDURE Pop_Table_Iterate_Base_Link(
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_pop_temp                  BOOLEAN := TRUE);
PROCEDURE Pop_Table_Recurse(
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_timer_set                    PLS_INTEGER := NULL,
            p_lev                          PLS_INTEGER := NULL);
FUNCTION Array_Recurse(
            p_timer_set                    PLS_INTEGER := NULL,
            p_lev                          PLS_INTEGER := NULL)
            RETURN                         paths_arr PIPELINED;
FUNCTION Array_Iterate
            RETURN                         paths_arr PIPELINED;

PROCEDURE Iteratively_Refine_Iterate(            
            p_keep_start                   PLS_INTEGER,
            p_keep_factor                  PLS_INTEGER);
FUNCTION Iteratively_Refine_Recurse
            RETURN                         paths_arr PIPELINED;
FUNCTION Iteratively_Refine_RSF
            RETURN                         paths_arr PIPELINED;

END Item_Cat_Seqs;
/
SHO ERR

