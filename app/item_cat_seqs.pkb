/***************************************************************************************************
Name: item_cat_seqs.pkb                Author: Brendan Furey                       Date: 30-Jun-2024

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

This file has the Item_Cat_Seqs package body
***************************************************************************************************/
CREATE OR REPLACE PACKAGE BODY Item_Cat_Seqs AS

g_items_running_sum_lis   item_running_sums_arr;
g_seq_size                PLS_INTEGER;
g_n_items                 PLS_INTEGER;
g_keep_num                PLS_INTEGER;
g_min_value               PLS_INTEGER;
g_max_price               PLS_INTEGER;
g_keep_start              PLS_INTEGER;
g_keep_factor             PLS_INTEGER;
g_sum_price               PLS_INTEGER;
g_sum_value               PLS_INTEGER;
g_timer_set               PLS_INTEGER;

PROCEDURE Set_Contexts(
            p_seq_type                     VARCHAR2 := NULL,
            p_seq_size                     VARCHAR2 := NULL,
            p_max_price                    VARCHAR2 := NULL,
            p_min_value                    VARCHAR2 := NULL,
            p_keep_num                     VARCHAR2 := NULL,
            p_item_width                   VARCHAR2 := NULL,
            p_top_n                        VARCHAR2 := NULL) IS
  l_name_lis    L1_chr_arr := L1_chr_arr('SEQ_TYPE', 'SEQ_SIZE', 'MAX_PRICE', 'MIN_VALUE', 'KEEP_NUM', 'ITEM_WIDTH', 'TOP_N');
  l_value_lis   L1_chr_arr := L1_chr_arr(p_seq_type, p_seq_size, p_max_price, p_min_value, p_keep_num, p_item_width, p_top_n);
  l_set_str     VARCHAR2(500);
  l_unset_str   VARCHAR2(500);
BEGIN

  FOR i IN 1..l_value_lis.COUNT LOOP
    IF l_value_lis(i) IS NOT NULL THEN
      DBMS_Session.Set_Context('RECURSION_CTX', l_name_lis(i), l_value_lis(i));
      l_set_str := l_set_str  || l_name_lis(i) || ' = ' || l_value_lis(i) || ', ';
    ELSE
      l_unset_str := l_unset_str  || l_name_lis(i) || ' = ' || SYS_Context('RECURSION_CTX', l_name_lis(i)) || ', ';
    END IF;
  END LOOP;
  Utils.W('Just set context values: ' || Substr(l_set_str, 1, Length(l_set_str) - 2));
  Utils.W('Previously set context values: ' || Substr(l_unset_str, 1, Length(l_unset_str) - 2));

END Set_Contexts;

FUNCTION Split_Values(
            p_string                       VARCHAR2,     -- fixed token length string
            p_token_len                    PLS_INTEGER)  -- token length
            RETURN                         L1_chr_arr IS -- list of tokens
  l_start_pos   PLS_INTEGER := 1;
  l_end_pos     PLS_INTEGER;
  l_arr_index   PLS_INTEGER := 1;
  l_arr         L1_chr_arr := L1_chr_arr();
  l_row         VARCHAR2(32767) := p_string;
BEGIN

  WHILE l_start_pos <= Length(l_row) LOOP

    l_arr.EXTEND;
    l_arr_index := l_arr_index + 1;
    l_end_pos := l_start_pos + p_token_len - 1;
    l_arr(l_arr.COUNT) := Substr(l_row, l_start_pos, l_end_pos - l_start_pos + 1);
    l_start_pos := l_end_pos + 1;

  END LOOP;

  RETURN l_arr;

END Split_Values;

FUNCTION Norm_Path(
            p_path                         VARCHAR2,    -- path
            p_token_len                    PLS_INTEGER) -- token length
            RETURN                         VARCHAR2 IS  -- ordered path
  l_arr         L1_chr_arr := L1_chr_arr();
BEGIN

  SELECT COLUMN_VALUE
    BULK COLLECT INTO l_arr
    FROM TABLE(Split_Values(p_string => p_path, p_token_len => p_token_len))
   ORDER BY 1;

  RETURN Utils.Join_Values(p_value_lis => l_arr, p_delim => NULL);

END Norm_Path;

FUNCTION recursion_Context(p_context_name VARCHAR2)
            RETURN                         PLS_INTEGER IS
BEGIN
  RETURN To_Number(SYS_Context('RECURSION_CTX', p_context_name));
END recursion_Context;

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
            RETURN                         VARCHAR2 IS
  l_test_value      PLS_INTEGER := p_tot_value;
  l_test_price      PLS_INTEGER := p_tot_price;
  l_slots_left      PLS_INTEGER := g_seq_size - p_lev - 1;
BEGIN

  IF l_slots_left > 0 THEN 
    l_test_value := p_tot_value + g_items_running_sum_lis(l_slots_left).sum_value;
    l_test_price := p_tot_price + g_items_running_sum_lis(l_slots_left).sum_price;
  END IF;

  IF l_test_value >= g_min_value AND l_test_price <= g_max_price AND p_lev < g_seq_size AND
     CASE p_cat_id_new WHEN p_cat_id THEN p_same_cats + 1 ELSE 1 END <= p_max_items_new AND
     l_slots_left + Least(CASE p_cat_id_new WHEN p_cat_id THEN p_same_cats + 1 ELSE 1 END,
                          p_min_items_new) >= p_min_remain_new AND
     (p_cat_id_new = p_cat_id OR p_same_cats >= p_min_items) AND
     (p_cat_id_new = p_cat_id OR p_cat_id_new = Nvl(p_next_cat_id, p_cat_id_new)) THEN

    RETURN 'Y';
  ELSE
   RETURN 'N';
  END IF;        

END Record_Is_Ok;

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
            RETURN                         VARCHAR2 IS
  l_test_value      PLS_INTEGER := p_tot_value;
  l_test_price      PLS_INTEGER := p_tot_price;
  l_slots_left      PLS_INTEGER := g_seq_size - p_lev - 1;
BEGIN

  IF l_slots_left > 0 THEN 
    l_test_value := p_tot_value + g_items_running_sum_lis(l_slots_left).sum_value;
    l_test_price := p_tot_price + g_items_running_sum_lis(l_slots_left).sum_price;
  END IF;

  IF l_test_value >= g_min_value AND l_test_price <= g_max_price AND p_lev < g_seq_size AND
     CASE p_cat_id_new WHEN p_cat_id THEN p_same_cats + 1 ELSE 1 END <= p_max_items_new AND
     l_slots_left + Least(CASE p_cat_id_new WHEN p_cat_id THEN p_same_cats + 1 ELSE 1 END,
                          p_min_items_new) >= p_min_remain_new AND
     (p_cat_id_new = p_cat_id OR p_same_cats >= p_min_items) AND
     (p_cat_id_new = p_cat_id OR p_cat_id_new = Nvl(p_next_cat_id, p_cat_id_new)) THEN

    Timer_Set.Increment_Time(g_timer_set, 'Record_Is_Ok - Y');
    RETURN 'Y';
  ELSE
    Timer_Set.Increment_Time(g_timer_set, 'Record_Is_Ok - N');
   RETURN 'N';
  END IF;        

END Record_Is_Ok_TS;

PROCEDURE pop_Item_Running_Sums IS
BEGIN

  DELETE item_running_sums;
  INSERT INTO item_running_sums
  WITH vals AS (
    SELECT ROWNUM rn, sum_value
      FROM (SELECT Sum(item_value) OVER (ORDER BY item_value DESC, id) sum_value
              FROM items
             ORDER BY item_value DESC, id)
  ), prices AS (
    SELECT ROWNUM rn, sum_price
      FROM (SELECT Sum(item_price) OVER (ORDER BY item_price, id) sum_price
              FROM items
             ORDER BY item_price, id)
  )
  SELECT v.rn, sum_value, sum_price
    FROM vals v
    JOIN prices p ON p.rn = v.rn
   WHERE v.rn < g_seq_size;

  SELECT slot_index, sum_value, sum_price
    BULK COLLECT INTO g_items_running_sum_lis
    FROM item_running_sums
   ORDER BY slot_index;

END pop_Item_Running_Sums;

PROCEDURE pop_Items_Ranked IS
BEGIN

  DELETE items_ranked;
  INSERT INTO items_ranked
  SELECT itm.id,
         itm.category_id,
         itm.item_price,
         itm.item_value,
         crs.min_items,
         crs.max_items,
         crs.min_remain,
         crs.next_cat_id,
         Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id),
         Count(*) OVER ()
    FROM items itm
    JOIN category_rsums_v crs
      ON crs.id = itm.category_id;

END pop_Items_Ranked;

PROCEDURE pop_Items_Ranked_Base IS
BEGIN

  DELETE items_ranked_base;
  INSERT INTO items_ranked_base
  WITH cat_base_ids AS (
    SELECT id, Power (max_max_items + 1, cat_rnk - 2) cat_base_id
      FROM category_rsums_v
  )
  SELECT itm.id,
         cbi.cat_base_id,
         itm.item_price,
         itm.item_value,
         crs.min_items,
         crs.max_items,
         crs.min_remain,
         cbi_n.cat_base_id next_cat_base_id,
         Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id),
         Count(*) OVER ()
    FROM items itm
    JOIN category_rsums_v crs
      ON crs.id = itm.category_id
    JOIN cat_base_ids cbi
      ON cbi.id = itm.category_id
    LEFT JOIN cat_base_ids cbi_n
      ON cbi_n.id = crs.next_cat_id;

END pop_Items_Ranked_Base;

PROCEDURE pop_Items_Ranked_Link IS
BEGIN

  DELETE items_ranked_link;
  INSERT INTO items_ranked_link
  SELECT itm.category_id,
         itm.item_price,
         itm.item_value,
         crs.min_items,
         crs.max_items,
         crs.min_remain,
         crs.next_cat_id,
         Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id)
    FROM items itm
    JOIN category_rsums_v crs
      ON crs.id = itm.category_id;

  SELECT Count(*) INTO g_n_items FROM items;

END pop_Items_Ranked_Link;

PROCEDURE pop_Items_Ranked_Base_Link IS
BEGIN

  DELETE items_ranked_base_link;
  INSERT INTO items_ranked_base_link
  WITH cat_base_ids AS (
    SELECT id, Power (max_max_items + 1, cat_rnk - 2) cat_base_id
      FROM category_rsums_v
  )
  SELECT cbi.cat_base_id,
         itm.item_price,
         itm.item_value,
         crs.min_items,
         crs.max_items,
         crs.min_remain,
         cbi_n.cat_base_id,
         Row_Number() OVER (ORDER BY crs.cat_rnk, itm.item_value DESC, itm.id)
    FROM items itm
    JOIN category_rsums_v crs
      ON crs.id = itm.category_id
    JOIN cat_base_ids cbi
      ON cbi.id = itm.category_id
    LEFT JOIN cat_base_ids cbi_n
      ON cbi_n.id = crs.next_cat_id;

  SELECT Count(*) INTO g_n_items FROM items;

END pop_Items_Ranked_Base_Link;

PROCEDURE set_Globals(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER) IS
BEGIN

  g_keep_num  := p_keep_num;
  g_min_value := p_min_value;

END set_Globals;

PROCEDURE init_Common(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER) IS
BEGIN

  set_Globals(p_keep_num  => p_keep_num,
              p_min_value => p_min_value);
  g_max_price := recursion_Context('MAX_PRICE');
  g_seq_size  := recursion_Context('SEQ_SIZE');
  pop_Item_Running_Sums;
  Utils.W(g_items_running_sum_lis.COUNT || ' running sums');

END init_Common;

PROCEDURE Init(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_timing                    BOOLEAN := FALSE) IS
BEGIN
  IF p_do_timing THEN
    g_timer_set := Timer_Set.Construct ('Init, KEEP_NUM-MIN_VALUE: ' || p_keep_num || '-' || p_min_value);
  ELSE
    g_timer_set := NULL;
  END IF;

  init_Common(p_keep_num   => p_keep_num, 
              p_min_value  => p_min_value);
  IF p_do_timing THEN
    Timer_Set.Increment_Time (g_timer_set, 'init_Common');
  END IF;
  pop_Items_Ranked;
  IF p_do_timing THEN
    Timer_Set.Increment_Time (g_timer_set, 'pop_Items_Ranked');
  END IF;

END Init;

PROCEDURE Write_Init_Timer_Set IS
BEGIN
  IF g_timer_set IS NOT NULL THEN
    Utils.W(Timer_Set.Format_Results(g_timer_set));
    Timer_Set.Remove_Timer_Set(g_timer_set);
  END IF;
END Write_Init_Timer_Set;

PROCEDURE Init_Loop(            
            p_keep_start                   PLS_INTEGER, 
            p_keep_factor                  PLS_INTEGER) IS
BEGIN

  g_max_price   := recursion_Context('MAX_PRICE');
  g_seq_size    := recursion_Context('SEQ_SIZE');
  g_keep_start  := p_keep_start;
  g_keep_factor := p_keep_factor;

  pop_Item_Running_Sums;
  Utils.W(g_items_running_sum_lis.COUNT || ' running sums');
  pop_Items_Ranked;

END Init_Loop;

PROCEDURE init_Base(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER) IS
BEGIN

  init_Common(p_keep_num   => p_keep_num, 
              p_min_value  => p_min_value);
  pop_Items_Ranked_Base;

END init_Base;

PROCEDURE init_Link(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER) IS
BEGIN

  init_Common(p_keep_num   => p_keep_num, 
              p_min_value  => p_min_value);
  pop_Items_Ranked_Link;
  DELETE item_links;

END init_Link;

PROCEDURE init_Base_Link(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER) IS
BEGIN

  init_Common(p_keep_num   => p_keep_num, 
              p_min_value  => p_min_value);
  pop_Items_Ranked_Base_Link;
  DELETE item_base_links;

END init_Base_Link;

PROCEDURE insert_Initial_Path(
            p_timer_set                    PLS_INTEGER) IS
BEGIN

  DELETE paths;
  Timer_Set.Increment_Time (p_timer_set, 'Initial delete (' || SQL%ROWCOUNT || ')');
  INSERT INTO paths (
     path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat_id, same_cats, min_items, cats_path, path
  )
  SELECT 0, 0, 0, 0, 0, 'AL', cat_id, 0, 0, '',''
    FROM items_ranked
   WHERE item_rnk = 1;

  Timer_Set.Increment_Time (p_timer_set, 'Initial insert (' || SQL%ROWCOUNT || ')');

END insert_Initial_Path;

PROCEDURE set_Sums(
            p_iter                         PLS_INTEGER) IS
BEGIN

  g_sum_price := 0;
  g_sum_value := 0;
  IF p_iter < g_seq_size then
    g_sum_price := g_items_running_sum_lis(g_seq_size - p_iter).sum_price;
    g_sum_value := g_items_running_sum_lis(g_seq_size - p_iter).sum_value;
  END IF;

END set_Sums;

PROCEDURE insert_Paths(
            p_timer_set                    PLS_INTEGER,
            p_iter                         PLS_INTEGER) IS
  l_n_rows          PLS_INTEGER := 0;
BEGIN
  
  set_Sums(p_iter => p_iter);
  INSERT /*+ gather_plan_statistics INSERT_PATHS */ INTO paths (
    path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat_id, same_cats, min_items, cats_path, path
  )
  WITH path_join AS (
      SELECT Row_Number() OVER (PARTITION BY trw.cats_path || irk.cat_id ORDER BY trw.tot_value + irk.item_value DESC,  trw.tot_price + irk.item_price) path_rnk,
             irk.item_rnk,
             p_iter lev,
             trw.tot_price + irk.item_price tot_price,
             trw.tot_value + irk.item_value tot_value,
             irk.cat_id,
             irk.next_cat_id,
             CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END same_cats,
             irk.min_items,
             trw.cats_path || irk.cat_id cats_path,
             trw.path || irk.item_id path
        FROM paths trw
        JOIN items_ranked irk
          ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (g_seq_size - trw.lev - 1))
       WHERE trw.tot_price + irk.item_price + g_sum_price <= g_max_price
         AND trw.tot_value + irk.item_value + g_sum_value >= g_min_value
         AND trw.lev < g_seq_size
         AND CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
         AND g_seq_size - (trw.lev + 1) + Least(CASE irk.cat_id 
                                                WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
                                                irk.min_items)
             >= irk.min_remain
         AND (irk.cat_id = trw.cat_id OR trw.same_cats >= trw.min_items)
         AND (irk.cat_id = trw.cat_id OR irk.cat_id = Nvl(trw.next_cat_id, irk.cat_id))
  )
  SELECT path_rnk,
         item_rnk,
         lev,
         tot_price,
         tot_value,
         cat_id,
         next_cat_id,
         same_cats,
         min_items,
         cats_path,
         path
    FROM path_join
   WHERE path_rnk <= g_keep_num OR g_keep_num = 0;
  l_n_rows := SQL%ROWCOUNT;
  IF p_iter = 10 THEN
    Utils.W(Utils.Get_XPlan(p_sql_marker => 'INSERT_PATHS'));
  END IF;
  Timer_Set.Increment_Time (p_timer_set, 'Insert paths ' || p_iter || ' (' || l_n_rows || ')');

  DELETE paths WHERE lev = p_iter - 1;
  Timer_Set.Increment_Time (p_timer_set, 'Delete paths ' || p_iter || ' (' || SQL%ROWCOUNT || ')');

END insert_Paths;

PROCEDURE insert_Initial_Path_Base(
            p_timer_set                    PLS_INTEGER) IS
BEGIN

  DELETE paths_Base;
  Timer_Set.Increment_Time (p_timer_set, 'Initial delete (' || SQL%ROWCOUNT || ')');
  INSERT INTO paths_Base (
     path_rnk, item_rnk, lev, tot_price, tot_value, cat_base_id, next_cat_base_id, same_cats, min_items, cat_base_sum, path
  )
  SELECT 0, 0, 0, 0, 0, 0, cat_base_id, 0, 0, 0, ''
    FROM items_ranked_Base
   WHERE item_rnk = 1;

  Timer_Set.Increment_Time (p_timer_set, 'Initial insert (' || SQL%ROWCOUNT || ')');

END insert_Initial_Path_Base;

PROCEDURE insert_Paths_Base(
            p_timer_set                    PLS_INTEGER,
            p_iter                         PLS_INTEGER) IS
  l_n_rows          PLS_INTEGER := 0;
BEGIN

  set_Sums(p_iter => p_iter);
  INSERT /*+ gather_plan_statistics INSERT_PATHS */ INTO paths_Base (
    path_rnk, item_rnk, lev, tot_price, tot_value, cat_base_id, next_cat_base_id, same_cats, min_items, cat_base_sum, path
  )
  WITH path_join AS (
      SELECT Row_Number() OVER (PARTITION BY trw.cat_base_sum + irk.cat_base_id ORDER BY trw.tot_value + irk.item_value DESC,  trw.tot_price + irk.item_price) path_rnk,
             irk.item_rnk,
             p_iter lev,
             trw.tot_price + irk.item_price tot_price,
             trw.tot_value + irk.item_value tot_value,
             irk.cat_base_id,
             irk.next_cat_base_id,
             CASE irk.cat_base_id WHEN trw.cat_base_id THEN trw.same_cats + 1 ELSE 1 END same_cats,
             irk.min_items,
             trw.cat_base_sum + irk.cat_base_id cat_base_sum,
             trw.path || irk.item_id path
        FROM paths_Base trw
        JOIN items_ranked_Base irk
          ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (g_seq_size - trw.lev - 1))
       WHERE trw.tot_price + irk.item_price + g_sum_price <= g_max_price
         AND trw.tot_value + irk.item_value + g_sum_value >= g_min_value
         AND trw.lev < g_seq_size
         AND CASE irk.cat_base_id WHEN trw.cat_base_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
         AND g_seq_size - (trw.lev + 1) + Least(CASE irk.cat_base_id 
                                                WHEN trw.cat_base_id THEN trw.same_cats + 1 ELSE 1 END,
                                                irk.min_items)
             >= irk.min_remain
         AND (irk.cat_base_id = trw.cat_base_id OR trw.same_cats >= trw.min_items)
         AND (irk.cat_base_id = trw.cat_base_id OR irk.cat_base_id = Nvl(trw.next_cat_base_id, irk.cat_base_id))
  )
  SELECT path_rnk,
         item_rnk,
         lev,
         tot_price,
         tot_value,
         cat_base_id,
         next_cat_base_id,
         same_cats,
         min_items,
         cat_base_sum,
         path
    FROM path_join
   WHERE path_rnk <= g_keep_num OR g_keep_num = 0;
  l_n_rows := SQL%ROWCOUNT;
  IF p_iter = 10 THEN
    Utils.W(Utils.Get_XPlan(p_sql_marker => 'INSERT_PATHS'));
  END IF;
  Timer_Set.Increment_Time (p_timer_set, 'Insert paths_Base ' || p_iter || ' (' || l_n_rows || ')');

  DELETE paths_Base WHERE lev = p_iter - 1;
  Timer_Set.Increment_Time (p_timer_set, 'Delete paths_Base ' || p_iter || ' (' || SQL%ROWCOUNT || ')');

END insert_Paths_Base;

PROCEDURE insert_Initial_Path_Link(
            p_timer_set                    PLS_INTEGER) IS
BEGIN

  DELETE paths_link;
  Timer_Set.Increment_Time (p_timer_set, 'Initial delete (' || SQL%ROWCOUNT || ')');
  INSERT INTO paths_Link (
     path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat_id, same_cats, min_items, cats_path, prior_iln_id, iln_id
  )
  SELECT 0, 0, 0, 0, 0, 'AL', cat_id, 0, 0, '', NULL, 0
    FROM items_ranked_Link
   WHERE item_rnk = 1;

  Timer_Set.Increment_Time (p_timer_set, 'Initial insert (' || SQL%ROWCOUNT || ')');

END insert_Initial_Path_Link;

PROCEDURE insert_Paths_Link(
            p_timer_set                    PLS_INTEGER,
            p_iter                         PLS_INTEGER) IS
  l_n_rows          PLS_INTEGER := 0;
BEGIN

  set_Sums(p_iter => p_iter);
  INSERT INTO item_links (
    id, item_rnk, prior_iln_id)
  SELECT iln_id, item_rnk, prior_iln_id
    FROM paths_Link;
  Timer_Set.Increment_Time (p_timer_set, 'Insert item_links  ' || p_iter || ' (' || SQL%ROWCOUNT || ')');

  INSERT /*+ gather_plan_statistics INSERT_ILN */ INTO paths_link (
    path_rnk, item_rnk, lev, tot_price, tot_value, cat_id, next_cat_id, same_cats, min_items, cats_path, prior_iln_id, iln_id
  )
  WITH path_join AS (
      SELECT Row_Number() OVER (PARTITION BY trw.cats_path || irk.cat_id ORDER BY trw.tot_value + irk.item_value DESC,  trw.tot_price + irk.item_price) path_rnk,
             irk.item_rnk,
             p_iter lev,
             trw.tot_price + irk.item_price tot_price,
             trw.tot_value + irk.item_value tot_value,
             irk.cat_id,
             irk.next_cat_id,
             CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END same_cats,
             irk.min_items,
             trw.cats_path || irk.cat_id cats_path,
             trw.iln_id
        FROM paths_link trw
        JOIN items_ranked_link irk
          ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (g_n_items - (g_seq_size - trw.lev - 1))
       WHERE trw.tot_price + irk.item_price + g_sum_price <= g_max_price
         AND trw.tot_value + irk.item_value + g_sum_value >= g_min_value
         AND trw.lev < g_seq_size
         AND CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
         AND g_seq_size - (trw.lev + 1) + Least(CASE irk.cat_id 
                                                WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
                                                irk.min_items)
             >= irk.min_remain
         AND (irk.cat_id = trw.cat_id OR trw.same_cats >= trw.min_items)
         AND (irk.cat_id = trw.cat_id OR irk.cat_id = Nvl(trw.next_cat_id, irk.cat_id))
  )
  SELECT path_rnk,
         item_rnk,
         lev,
         tot_price,
         tot_value,
         cat_id,
         next_cat_id,
         same_cats,
         min_items,
         cats_path,
         iln_id,
         iln_seq.NEXTVAL
    FROM path_join
   WHERE path_rnk <= g_keep_num OR g_keep_num = 0;
  l_n_rows := SQL%ROWCOUNT;
  IF p_iter = 10 THEN
    Utils.W(Utils.Get_XPlan(p_sql_marker => 'INSERT_ILN'));
  END IF;
  Timer_Set.Increment_Time (p_timer_set, 'Insert paths_Link ' || p_iter || ' (' || l_n_rows || ')');

  DELETE paths_Link WHERE lev = p_iter - 1;
  Timer_Set.Increment_Time (p_timer_set, 'Delete paths_Link ' || p_iter || ' (' || SQL%ROWCOUNT || ')');

END insert_Paths_Link;

PROCEDURE insert_Init_Path_Base_Link(
            p_timer_set                    PLS_INTEGER) IS
BEGIN

  DELETE paths_base_link;
  Timer_Set.Increment_Time (p_timer_set, 'Initial delete (' || SQL%ROWCOUNT || ')');
  INSERT INTO paths_base_link (
     path_rnk, item_rnk, lev, tot_price, tot_value, cat_base_id, next_cat_base_id, same_cats, min_items, cat_base_sum, prior_ibl_id, ibl_id
  )
  SELECT 0, 0, 0, 0, 0, 0, cat_base_id, 0, 0, 0, NULL, 0
    FROM items_ranked_base_link
   WHERE item_rnk = 1;

  Timer_Set.Increment_Time (p_timer_set, 'Initial insert (' || SQL%ROWCOUNT || ')');

END insert_Init_Path_Base_Link;

PROCEDURE insert_Paths_Base_Link(
            p_timer_set                    PLS_INTEGER,
            p_iter                         PLS_INTEGER) IS
  l_n_rows          PLS_INTEGER := 0;
BEGIN

  set_Sums(p_iter => p_iter);
  INSERT INTO item_base_links (
    id, item_rnk, prior_ibl_id)
  SELECT ibl_id, item_rnk, prior_ibl_id
    FROM paths_base_link;
  Timer_Set.Increment_Time (p_timer_set, 'Insert item_base_links  ' || p_iter || ' (' || SQL%ROWCOUNT || ')');

  INSERT /*+ gather_plan_statistics INSERT_IBL */ INTO paths_base_link (
    path_rnk, item_rnk, lev, tot_price, tot_value, cat_base_id, next_cat_base_id, same_cats, min_items, cat_base_sum, prior_ibl_id, ibl_id
  )
  WITH path_join AS (
      SELECT Row_Number() OVER (PARTITION BY trw.cat_base_sum + irk.cat_base_id ORDER BY trw.tot_value + irk.item_value DESC,  trw.tot_price + irk.item_price) path_rnk,
             irk.item_rnk,
             p_iter lev,
             trw.tot_price + irk.item_price tot_price,
             trw.tot_value + irk.item_value tot_value,
             irk.cat_base_id,
             irk.next_cat_base_id,
             CASE irk.cat_base_id WHEN trw.cat_base_id THEN trw.same_cats + 1 ELSE 1 END same_cats,
             irk.min_items,
             trw.cat_base_sum + irk.cat_base_id cat_base_sum,
             trw.ibl_id
        FROM paths_base_link trw
        JOIN items_ranked_base_link irk
          ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (g_n_items - (g_seq_size - trw.lev - 1))
       WHERE trw.tot_price + irk.item_price + g_sum_price <= g_max_price
         AND trw.tot_value + irk.item_value + g_sum_value >= g_min_value
         AND trw.lev < g_seq_size
         AND CASE irk.cat_base_id WHEN trw.cat_base_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
         AND g_seq_size - (trw.lev + 1) + Least(CASE irk.cat_base_id 
                                                WHEN trw.cat_base_id THEN trw.same_cats + 1 ELSE 1 END,
                                                irk.min_items)
             >= irk.min_remain
         AND (irk.cat_base_id = trw.cat_base_id OR trw.same_cats >= trw.min_items)
         AND (irk.cat_base_id = trw.cat_base_id OR irk.cat_base_id = Nvl(trw.next_cat_base_id, irk.cat_base_id))
  )
  SELECT path_rnk,
         item_rnk,
         lev,
         tot_price,
         tot_value,
         cat_base_id,
         next_cat_base_id,
         same_cats,
         min_items,
         cat_base_sum,
         ibl_id,
         ibl_seq.NEXTVAL
    FROM path_join
   WHERE path_rnk <= g_keep_num OR g_keep_num = 0;
  l_n_rows := SQL%ROWCOUNT;
  IF p_iter = 10 THEN
    Utils.W(Utils.Get_XPlan(p_sql_marker => 'INSERT_IBL'));
  END IF;
  Timer_Set.Increment_Time (p_timer_set, 'Insert paths_base_Link ' || p_iter || ' (' || l_n_rows || ')');

  DELETE paths_base_Link WHERE lev = p_iter - 1;
  Timer_Set.Increment_Time (p_timer_set, 'Delete paths_base_Link ' || p_iter || ' (' || SQL%ROWCOUNT || ')');

END insert_Paths_Base_Link;

PROCEDURE Pop_Table_Iterate(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_pop_temp                  BOOLEAN := TRUE) IS
  l_timer_set       PLS_INTEGER := Timer_Set.Construct ('Pop_Table_Iterate');
BEGIN

  IF p_do_pop_temp THEN
    Init(p_keep_num    => p_keep_num, 
         p_min_value   => p_min_value);
  ELSE
    set_Globals(p_keep_num    => p_keep_num, 
                p_min_value   => p_min_value);
  END IF;
  insert_Initial_Path(p_timer_set => l_timer_set);

  FOR i IN 1..g_seq_size LOOP

    insert_Paths(p_timer_set => l_timer_set,
                 p_iter      => i);
  END LOOP;
  Utils.W(Timer_Set.Format_Results(l_timer_set));
  Write_Init_Timer_Set;
END Pop_Table_Iterate;

PROCEDURE Pop_Table_Iterate_Base(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER) IS
  l_timer_set       PLS_INTEGER := Timer_Set.Construct ('Pop_Table_Iterate_Base');
BEGIN

  init_Base(p_keep_num    => p_keep_num, 
             p_min_value   => p_min_value);
  insert_Initial_Path_Base(p_timer_set => l_timer_set);

  FOR i IN 1..g_seq_size LOOP

    insert_Paths_Base(p_timer_set => l_timer_set,
                       p_iter      => i);
  END LOOP;
  Utils.W(Timer_Set.Format_Results(l_timer_set));
  Write_Init_Timer_Set;

END Pop_Table_Iterate_Base;

PROCEDURE Pop_Table_Iterate_Link(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_pop_temp                  BOOLEAN := TRUE) IS
  l_timer_set       PLS_INTEGER := Timer_Set.Construct ('Pop_Table_Iterate_Link');
BEGIN

  IF p_do_pop_temp THEN
    init_Link(p_keep_num    => p_keep_num, 
              p_min_value   => p_min_value);
  ELSE
    set_Globals(p_keep_num    => p_keep_num, 
                p_min_value   => p_min_value);
  END IF;
  insert_Initial_Path_Link(p_timer_set => l_timer_set);

  FOR i IN 1..g_seq_size LOOP

    insert_Paths_Link(p_timer_set => l_timer_set,
                      p_iter      => i);
  END LOOP;
  Utils.W(Timer_Set.Format_Results(l_timer_set));
  Write_Init_Timer_Set;

END Pop_Table_Iterate_Link;

PROCEDURE Pop_Table_Iterate_Base_Link(            
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_do_pop_temp                  BOOLEAN := TRUE) IS
  l_timer_set       PLS_INTEGER := Timer_Set.Construct ('Pop_Table_Iterate_Base_Link');
BEGIN

  IF p_do_pop_temp THEN
    init_Base_Link(p_keep_num    => p_keep_num, 
                   p_min_value   => p_min_value);
  ELSE
    set_Globals(p_keep_num    => p_keep_num, 
                p_min_value   => p_min_value);
  END IF;
  insert_Init_Path_Base_Link(p_timer_set => l_timer_set);

  FOR i IN 1..g_seq_size LOOP

    insert_Paths_Base_Link(p_timer_set => l_timer_set,
                             p_iter      => i);
  END LOOP;
  Utils.W(Timer_Set.Format_Results(l_timer_set));
  Write_Init_Timer_Set;

END Pop_Table_Iterate_Base_Link;

PROCEDURE Pop_Table_Recurse(
            p_keep_num                     PLS_INTEGER, 
            p_min_value                    PLS_INTEGER,
            p_timer_set                    PLS_INTEGER := NULL,
            p_lev                          PLS_INTEGER := NULL) IS
  l_timer_set       PLS_INTEGER := p_timer_set;
BEGIN

  IF p_timer_set IS NULL THEN
    Init(p_keep_num    => p_keep_num, 
         p_min_value   => p_min_value);
    l_timer_set := Timer_Set.Construct ('Pop_Table_Recurse');
  END IF;

  IF p_lev = 0 THEN
    insert_Initial_Path(p_timer_set => l_timer_set);
    RETURN;
  END IF;

  Pop_Table_Recurse(p_keep_num    => p_keep_num, 
                    p_min_value   => p_min_value,
                    p_timer_set   => l_timer_set,
                    p_lev         => Nvl(p_lev, g_seq_size) - 1);
  insert_Paths(p_timer_set => l_timer_set,
               p_iter      => Nvl(p_lev, g_seq_size));

  IF p_lev IS NULL THEN
    Utils.W(Timer_Set.Format_Results(l_timer_set));
    Write_Init_Timer_Set;
  END IF;

END Pop_Table_Recurse;

FUNCTION initial_Path
            RETURN                         paths%ROWTYPE IS
  l_paths_rec       paths%ROWTYPE;
BEGIN

  SELECT 0, 0, 0, 0, 0, 'AL', cat_id, 0, 0, '',''
    INTO l_paths_rec
    FROM items_ranked
   WHERE item_rnk = 1;

  RETURN l_paths_rec;

END initial_Path;

FUNCTION Array_Recurse(
            p_timer_set                    PLS_INTEGER := NULL,
            p_lev                          PLS_INTEGER := NULL)
            RETURN                         paths_arr PIPELINED IS
  l_n_rows          PLS_INTEGER := 0;
  l_timer_set       PLS_INTEGER := p_timer_set;
BEGIN

  IF p_timer_set IS NULL THEN
    l_timer_set := Timer_Set.Construct ('Array_Recurse');
  END IF;

  IF p_lev = 0 THEN
    PIPE ROW(initial_Path);
    RETURN;
  END IF;

  set_Sums(p_iter => p_lev);
  FOR rec IN (
    WITH path_join AS (
        SELECT /*+ gather_plan_statistics ARRAY_RECURSE */
               Row_Number() OVER (PARTITION BY trw.cats_path || irk.cat_id ORDER BY trw.tot_value + irk.item_value DESC,  trw.tot_price + irk.item_price) path_rnk,
               irk.item_rnk,
               trw.lev + 1 lev,
               trw.tot_price + irk.item_price tot_price,
               trw.tot_value + irk.item_value tot_value,
               irk.cat_id,
               irk.next_cat_id,
               CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END same_cats,
               irk.min_items,
               trw.cats_path || irk.cat_id cats_path,
               trw.path || irk.item_id path
          FROM Array_Recurse(p_timer_set    => l_timer_set,
                             p_lev          => Nvl(p_lev, g_seq_size) - 1) trw
          JOIN items_ranked irk
            ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (g_seq_size - trw.lev - 1))
         WHERE trw.tot_price + irk.item_price + g_sum_price <= g_max_price
           AND trw.tot_value + irk.item_value + g_sum_value >= g_min_value
           AND trw.lev < g_seq_size
           AND CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
           AND g_seq_size - (trw.lev + 1) + Least(CASE irk.cat_id 
                                                  WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
                                                  irk.min_items)
               >= irk.min_remain
           AND (irk.cat_id = trw.cat_id OR trw.same_cats >= trw.min_items)
           AND (irk.cat_id = trw.cat_id OR irk.cat_id = Nvl(trw.next_cat_id, irk.cat_id))
    )
    SELECT path_rnk,
           item_rnk,
           lev,
           tot_price,
           tot_value,
           cat_id,
           next_cat_id,
           same_cats,
           min_items,
           cats_path,
           path
      FROM path_join
     WHERE path_rnk <= g_keep_num OR g_keep_num = 0) LOOP
      PIPE ROW(rec);
    l_n_rows := l_n_rows + 1;
  END LOOP;
  IF p_lev = 10 THEN
    Utils.W(Utils.Get_XPlan(p_sql_marker => 'ARRAY_RECURSE'));
  END IF;

  Timer_Set.Increment_Time(Nvl(p_timer_set, l_timer_set), 'Recurse level: ' || Nvl(p_lev, g_seq_size) || ' (' || l_n_rows || ')');

  IF p_lev IS NULL THEN
    Utils.W(Timer_Set.Format_Results(l_timer_set));
  END IF;
END Array_Recurse;

FUNCTION Array_Iterate 
            RETURN                         paths_arr PIPELINED IS
  l_paths_lis       paths_arr := paths_arr(initial_Path);
  l_paths_new_lis   paths_arr;
  l_timer_set       PLS_INTEGER := Timer_Set.Construct ('Array_Iterate');
BEGIN

  FOR i IN 1..g_seq_size LOOP
    set_Sums(p_iter => i);
    WITH path_join AS (
        SELECT  /*+ gather_plan_statistics ARRAY_ITERATE */
               Row_Number() OVER (PARTITION BY trw.cats_path || irk.cat_id ORDER BY trw.tot_value + irk.item_value DESC,  trw.tot_price + irk.item_price) path_rnk,
               irk.item_rnk,
               trw.lev + 1 lev,
               trw.tot_price + irk.item_price tot_price,
               trw.tot_value + irk.item_value tot_value,
               irk.cat_id,
               irk.next_cat_id,
               CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END same_cats,
               irk.min_items,
               trw.cats_path || irk.cat_id cats_path,
               trw.path || irk.item_id path
          FROM TABLE(l_paths_lis) trw
          JOIN items_ranked irk
            ON irk.item_rnk BETWEEN (trw.item_rnk + 1) AND (irk.n_items - (g_seq_size - trw.lev - 1))
         WHERE trw.tot_price + irk.item_price + g_sum_price <= g_max_price
           AND trw.tot_value + irk.item_value + g_sum_value >= g_min_value
           AND trw.lev < g_seq_size
           AND CASE irk.cat_id WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END <= irk.max_items
           AND g_seq_size - (trw.lev + 1) + Least(CASE irk.cat_id 
                                                  WHEN trw.cat_id THEN trw.same_cats + 1 ELSE 1 END,
                                                  irk.min_items)
               >= irk.min_remain
           AND (irk.cat_id = trw.cat_id OR trw.same_cats >= trw.min_items)
           AND (irk.cat_id = trw.cat_id OR irk.cat_id = Nvl(trw.next_cat_id, irk.cat_id))
    )
    SELECT
           path_rnk,
           item_rnk,
           lev,
           tot_price,
           tot_value,
           cat_id,
           next_cat_id,
           same_cats,
           min_items,
           cats_path,
           path
      BULK COLLECT INTO l_paths_new_lis
      FROM path_join
     WHERE path_rnk <= g_keep_num OR g_keep_num = 0;
    IF i = 10 THEN
      Utils.W(Utils.Get_XPlan(p_sql_marker => 'ARRAY_ITERATE'));
    END IF;

    Timer_Set.Increment_Time(l_timer_set, 'Insert ' || i || ' (' || SQL%ROWCOUNT || ')');

    IF i < g_seq_size THEN
      l_paths_lis := l_paths_new_lis;
      Timer_Set.Increment_Time(l_timer_set, 'Reset paths array ' || i);
    END IF;
  END LOOP;

  FOR i IN 1..l_paths_new_lis.COUNT LOOP
    PIPE ROW(l_paths_new_lis(i));
  END LOOP;
  Timer_Set.Increment_Time(l_timer_set, 'Pipe rows');
  Utils.W(Timer_Set.Format_Results(l_timer_set));

END Array_Iterate;

PROCEDURE Iteratively_Refine_Iterate(            
            p_keep_start                   PLS_INTEGER,
            p_keep_factor                  PLS_INTEGER) IS
  l_timer_set     PLS_INTEGER := Timer_Set.Construct ('Iteratively_Refine_Iterate');
  l_top_n         PLS_INTEGER := recursion_Context('TOP_N');
  l_do_pop_temp   BOOLEAN := TRUE;
BEGIN

  g_min_value := 0;
  g_keep_num := p_keep_start;
  FOR i IN 1..3 LOOP

    Pop_Table_Iterate(p_keep_num      => g_keep_num, 
                      p_min_value     => g_min_value,
                      p_do_pop_temp   => l_do_pop_temp);
    l_do_pop_temp := FALSE;
    Timer_Set.Increment_Time(l_timer_set, 'PTI ' || i || ': MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);
    BEGIN
      WITH ranking AS (
          SELECT tot_value,
                 Row_Number() OVER (ORDER BY tot_value DESC, tot_price) rnk
            FROM paths
      )
      SELECT tot_value
        INTO g_min_value
        FROM ranking
       WHERE rnk = l_top_n;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        g_min_value := 0;
    END;
    Timer_Set.Increment_Time(l_timer_set, 'SELECT ' || i || ': MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);
    g_keep_num := g_keep_num * p_keep_factor;
    EXIT WHEN g_min_value > 0;

  END LOOP;

  Pop_Table_Iterate(p_keep_num      => g_keep_num, 
                    p_min_value     => g_min_value,
                    p_do_pop_temp   => FALSE);

  Timer_Set.Increment_Time(l_timer_set, 'PTI (final): MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);

  Utils.W(Timer_Set.Format_Results(l_timer_set));

END Iteratively_Refine_Iterate;

FUNCTION Iteratively_Refine_Recurse
            RETURN                         paths_arr PIPELINED IS
  l_timer_set                   PLS_INTEGER := Timer_Set.Construct ('Iteratively_Refine_Recurse');
  l_n_rows                      PLS_INTEGER := 0;
  l_top_n                       PLS_INTEGER := recursion_Context('TOP_N');
BEGIN

  g_min_value := 0;
  g_keep_num := g_keep_start;

  FOR i IN 1..3 LOOP

    set_Globals(p_keep_num      => g_keep_num, 
                p_min_value     => g_min_value);
    Timer_Set.Increment_Time(l_timer_set, 'set_Globals ' || i || ': MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);

    BEGIN
      SELECT tot_value
        INTO g_min_value
        FROM array_recurse_v
       WHERE rnk = l_top_n;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        g_min_value := 0;
    END;
    Timer_Set.Increment_Time(l_timer_set, 'SELECT ' || i || ': MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);
    g_keep_num := g_keep_num * g_keep_factor;
    EXIT WHEN g_min_value > 0;
  END LOOP;

  set_Globals(p_keep_num      => g_keep_num, 
              p_min_value     => g_min_value);
  Timer_Set.Increment_Time(l_timer_set, 'set_Globals: MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);
  FOR rec IN (SELECT *
                FROM TABLE(Item_Cat_Seqs.Array_Recurse)
             ) LOOP

    PIPE ROW (rec);
    l_n_rows := l_n_rows + 1;

  END LOOP;

  Timer_Set.Increment_Time(l_timer_set, 'Pipe ' || l_n_rows || ' rows: MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);

  Utils.W(Timer_Set.Format_Results(l_timer_set));

END Iteratively_Refine_Recurse;

FUNCTION Iteratively_Refine_RSF
            RETURN                         paths_arr PIPELINED IS
  l_timer_set                   PLS_INTEGER := Timer_Set.Construct ('Iteratively_Refine_RSF');
  l_n_rows                      PLS_INTEGER := 0;
  l_top_n                       PLS_INTEGER := recursion_Context('TOP_N');
  l_rec                         paths%ROWTYPE;
BEGIN

  g_min_value := 0;
  g_keep_num := g_keep_start;
  FOR i IN 1..3 LOOP

    Set_Contexts(p_keep_num      => g_keep_num, 
                 p_min_value     => g_min_value);

    BEGIN
      SELECT tot_value
        INTO g_min_value
        FROM rsf_irk_irs_tabs_v
       WHERE rnk = l_top_n;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        g_min_value := 0;
    END;
    Timer_Set.Increment_Time(l_timer_set, 'SELECT ' || i || ': MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);
    g_keep_num := g_keep_num * g_keep_factor;
    EXIT WHEN g_min_value > 0;
  END LOOP;

  Set_Contexts(p_keep_num      => g_keep_num, 
               p_min_value     => g_min_value);
  Timer_Set.Increment_Time(l_timer_set, 'Set_Contexts: MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);
  FOR rec IN (SELECT /*+ gather_plan_statistics RSF_IRK_IRS_TABS_V */
                     *
                FROM rsf_irk_irs_tabs_v
             ) LOOP

    l_rec.path := rec.path;
    l_rec.tot_value := rec.tot_value;
    l_rec.tot_price := rec.tot_price;
    PIPE ROW (l_rec);
    l_n_rows := l_n_rows + 1;

  END LOOP;

  Timer_Set.Increment_Time(l_timer_set, 'Pipe ' || l_n_rows || ' rows: MIN_VALUE / KEEP_NUM = ' || g_min_value || ' / ' || g_keep_num);
  Utils.W(Utils.Get_XPlan(p_sql_marker => 'RSF_IRK_IRS_TABS_V'));

  Utils.W(Timer_Set.Format_Results(l_timer_set));

END Iteratively_Refine_RSF;

END Item_Cat_Seqs;
/
SHO ERR
