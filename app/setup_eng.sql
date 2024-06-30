/***************************************************************************************************
Name: setup_eng.sql                    Author: Brendan Furey                       Date: 30-Jun-2024

Component SQL script in 'Optimization Problems with Items and Categories in Oracle' project

    GitHub: https://github.com/BrenPatF/item_category_optimization_oracle
    Blog:   https://brenpatf.github.io (Posts OPICO 1-8)

====================================================================================================
|  SQL Script                 | Description                                                        |
|===================================================================================================
INSTALL SCRIPTS
====================================================================================================
|  install_ico.sql            | Installs base components                                           |
|  install_ico_tt.sql         | Installs unit testing components                                   |
|  setup_sml.sql              | Sets up Small dataset                                              |
|  setup_bra.sql              | Sets up Brazil dataset                                             |
| *setup_eng.sql*             | Sets up England dataset                                            |
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
|  item_seqs.sql              | Runs sequence generation methods                                   |
====================================================================================================

This file has the script to set up the England dataset
***************************************************************************************************/
PROMPT Create EPL tables...
PROMPT Table epl_positions
DROP TABLE epl_positions
/
CREATE TABLE epl_positions (
        id              VARCHAR2(2) PRIMARY KEY,
        min_players     INTEGER,
        max_players     INTEGER
)
/
PROMPT External table player_matches_ext pointing to stats.txt
DROP TABLE player_matches_ext
/
CREATE TABLE player_matches_ext (
        yellow_cards        NUMBER,
        net_transfers       NUMBER,
        last_name           VARCHAR2(30),
        goals_conceded      NUMBER,
        saves               NUMBER,
        result              VARCHAR2(30),
        team_name           VARCHAR2(30),
        fl_index            NUMBER,
        first_name          VARCHAR2(30),
        own_goals           NUMBER,
        minutes_played      NUMBER,
        EA_Spots_PPI        NUMBER,
        week                NUMBER,
        bonus               NUMBER,
        clean_sheets        NUMBER,
        assists             NUMBER,
        match_date          VARCHAR2(30),
        penalties_saved     NUMBER,
        penalties_missed    NUMBER,
        value               NUMBER,
        points              NUMBER,
        position            VARCHAR2(30),
        red_cards           NUMBER,
        goals_scored        NUMBER
)
ORGANIZATION EXTERNAL (
	TYPE			oracle_loader
	DEFAULT DIRECTORY	input_dir
	ACCESS PARAMETERS
	(
        RECORDS DELIMITED BY NEWLINE SKIP 1
		FIELDS TERMINATED BY ','
		MISSING FIELD VALUES ARE NULL
	)
	LOCATION ('fantasy_premier_league_player_stats.csv')
)
/
PROMPT Table epl_players
DROP TABLE epl_players
/
CREATE TABLE epl_players (
        id                  INTEGER PRIMARY KEY,
        first_name          VARCHAR2(30),
        last_name           VARCHAR2(30),
        value               INTEGER,
        points              INTEGER,
        position            VARCHAR2(2)
)
/
PROMPT Insert EPL data...
PROMPT Insert EPL positions
DECLARE

  i     PLS_INTEGER := 0;
  PROCEDURE Ins_Position (
                        p_id	        VARCHAR2,
                        p_min_players   PLS_INTEGER,
                        p_max_players   PLS_INTEGER) IS
  BEGIN

    INSERT INTO epl_positions VALUES (p_id, p_min_players, p_max_players);

  END Ins_Position;

BEGIN

  DELETE epl_positions;
  Ins_Position ('GK', 1, 1);
  Ins_Position ('DF', 3, 5);
  Ins_Position ('MF', 2, 5);
  Ins_Position ('FW', 1, 3);
  Ins_Position ('AL', 11, 11);
END;
/
PROMPT Insert EPL PLAYERS
INSERT INTO epl_players (
        id,
        first_name,
        last_name,
        position,
        value,
        points
)
SELECT  Row_Number() OVER (ORDER BY last_name, first_name),
        first_name,
        last_name,
        CASE position WHEN 'Goalkeeper' THEN 'GK' WHEN 'Defender' THEN 'DF' WHEN 'Midfielder' THEN 'MF' WHEN 'Forward' THEN 'FW' END,
        Max (value) KEEP (DENSE_RANK LAST ORDER BY week),
        Sum (points)
  FROM player_matches_ext
 GROUP BY 
        first_name,
        last_name,
        CASE position WHEN 'Goalkeeper' THEN 'GK' WHEN 'Defender' THEN 'DF' WHEN 'Midfielder' THEN 'MF' WHEN 'Forward' THEN 'FW' END
 HAVING Sum (points) > 0
/
SELECT Count(*) FROM epl_players WHERE points > 0
/
