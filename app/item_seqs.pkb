/***************************************************************************************************
Name: item_seqs.pkb                    Author: Brendan Furey                       Date: 30-Jun-2024

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

This file has the Item_Seqs package body
***************************************************************************************************/
CREATE OR REPLACE PACKAGE BODY Item_Seqs AS
g_seq_size    PLS_INTEGER := 3;

FUNCTION Seq_Type_Condition_YN(
            p_seq_type                     VARCHAR2,
            p_item_id                      VARCHAR2,
            p_item_id_prior                VARCHAR2,
            p_path                         VARCHAR2)
            RETURN                         VARCHAR2 IS
  l_ret_yn VARCHAR2(1) := 'N';
BEGIN

  CASE p_seq_type
    WHEN 'MP' THEN 
      l_ret_yn := 'Y';
    WHEN 'MC' THEN 
      IF p_item_id >= p_item_id_prior THEN l_ret_yn := 'Y'; END IF;
    WHEN 'SP' THEN 
      IF Nvl(p_path,'x') NOT LIKE '%' || p_item_id || '%' THEN l_ret_yn := 'Y'; END IF;
    WHEN 'SC' THEN 
      IF p_item_id > p_item_id_prior THEN l_ret_yn := 'Y'; END IF;
  END CASE;
  RETURN l_ret_yn;

END Seq_Type_Condition_YN;

FUNCTION initial_Path
            RETURN                         small_paths%ROWTYPE IS
  l_path_req   small_paths%ROWTYPE;
BEGIN
  SELECT '', 0, 0, 0, '0' INTO l_path_req FROM DUAL;
  RETURN l_path_req;
END initial_Path;

FUNCTION Array_Recurse(
            p_seq_type                     VARCHAR2, 
            p_lev                          PLS_INTEGER := NULL)
            RETURN                         paths_arr PIPELINED IS
BEGIN

  IF p_lev = 0 THEN
    PIPE ROW(initial_Path);
    RETURN;
  END IF;

  FOR rec IN (
    SELECT smp.path || itm.id path,
           smp.lev + 1 lev,
           smp.tot_price + itm.item_price tot_price,
           smp.tot_value + itm.item_value tot_value,
           itm.id item_id
      FROM Array_Recurse(p_seq_type, Nvl(p_lev, g_seq_size) - 1) smp
      JOIN items itm
        ON Item_Seqs.Seq_Type_Condition_YN(
                      p_seq_type       => p_seq_type,
                      p_item_id        => itm.id,
                      p_item_id_prior  => smp.item_id,
                      p_path           => smp.path) = 'Y') LOOP
    PIPE ROW(rec);
  END LOOP;

END Array_Recurse;

PROCEDURE insert_Initial_Path IS
BEGIN
  DELETE small_paths;
  INSERT INTO small_paths (
     path, lev, tot_price, tot_value, item_id
  ) VALUES ('', 0, 0, 0, '0');
END insert_Initial_Path;

PROCEDURE insert_Paths(
            p_seq_type                     VARCHAR2, 
            p_lev                          PLS_INTEGER) IS
BEGIN
  INSERT INTO small_paths (
     path, lev, tot_price, tot_value, item_id
  )
  SELECT smp.path || itm.id,
         p_lev,
         smp.tot_price + itm.item_price,
         smp.tot_value + itm.item_value,
         itm.id
    FROM small_paths smp
    JOIN items itm
      ON Item_Seqs.Seq_Type_Condition_YN(
                  p_seq_type       => p_seq_type,
                  p_item_id        => itm.id,
                  p_item_id_prior  => smp.item_id,
                  p_path           => smp.path) = 'Y';
  DELETE small_paths WHERE lev = p_lev - 1;
END insert_Paths;

PROCEDURE Pop_Table_Recurse(
            p_seq_type                     VARCHAR2, 
            p_lev                          PLS_INTEGER := NULL) IS
BEGIN

  IF p_lev = 0 THEN
    insert_Initial_Path;
    RETURN;
  END IF;
  Pop_Table_Recurse(p_seq_type, Nvl(p_lev, g_seq_size) - 1);
  insert_Paths(p_seq_type => p_seq_type,
               p_lev      => Nvl(p_lev, g_seq_size));

END Pop_Table_Recurse;

FUNCTION Array_Iterate(
            p_seq_type                     VARCHAR2)
            RETURN                         paths_arr PIPELINED IS
  l_paths_lis       paths_arr := paths_arr(initial_Path);
  l_paths_new_lis   paths_arr;
BEGIN

  FOR i IN 1..g_seq_size LOOP
    SELECT smp.path || itm.id,
           smp.lev + 1,
           smp.tot_price + itm.item_price,
           smp.tot_value + itm.item_value,
           itm.id
      BULK COLLECT INTO l_paths_new_lis
      FROM TABLE(l_paths_lis) smp
      JOIN items itm
        ON Item_Seqs.Seq_Type_Condition_YN(
                    p_seq_type       => p_seq_type,
                    p_item_id        => itm.id,
                    p_item_id_prior  => smp.item_id,
                    p_path           => smp.path) = 'Y';

    l_paths_lis := l_paths_new_lis;
  END LOOP;
  FOR i IN 1..l_paths_lis.COUNT LOOP
    PIPE ROW(l_paths_lis(i));
  END LOOP;

END Array_Iterate;

PROCEDURE Pop_Table_Iterate(
            p_seq_type                     VARCHAR2) IS
BEGIN

  insert_initial_Path;

  FOR i IN 1..g_seq_size LOOP
    insert_Paths(p_seq_type => p_seq_type,
                 p_lev      => i);
  END LOOP;

END Pop_Table_Iterate;

END Item_Seqs;
/
SHO ERR
