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
| *setup_bra.sql*             | Sets up Brazil dataset                                             |
|  setup_eng.sql              | Sets up England dataset                                            |
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

This file has the script to set up the Brazil dataset
***************************************************************************************************/
PROMPT Create Brazil tables...
DROP TABLE brazil_positions
/
CREATE TABLE brazil_positions (
        id              VARCHAR2(2) PRIMARY KEY,
        min_players     INTEGER,
        max_players     INTEGER
)
/
DROP TABLE brazil_players
/
CREATE TABLE brazil_players (
        id              VARCHAR2(3) PRIMARY KEY,
        club_name       VARCHAR2(30),
        player_name     VARCHAR2(30),
        position        VARCHAR2(2),
        price           INTEGER,
        avg_points      INTEGER
)  
/
PROMPT Insert Brazil data
DECLARE

  i     PLS_INTEGER := 0;
  PROCEDURE Ins_Position (
                        p_id	        VARCHAR2,
                        p_min_players   PLS_INTEGER,
                        p_max_players   PLS_INTEGER) IS
  BEGIN

    INSERT INTO brazil_positions VALUES (p_id, p_min_players, p_max_players);

  END Ins_Position;

  PROCEDURE Ins_Player (p_club_name    VARCHAR2,
                        p_player_name  VARCHAR2, 
                        p_position     VARCHAR2,
                        p_price        NUMBER,
                        p_avg_points   NUMBER) IS
  BEGIN

    i := i + 1;
    INSERT INTO brazil_players VALUES (LPad (i, 3, '0'), p_club_name, p_player_name, p_position, 100*p_price, 100*p_avg_points);

  END Ins_Player;

BEGIN

  DELETE brazil_positions;
  Ins_Position ('CO', 1, 1);
  Ins_Position ('GK', 1, 1);
  Ins_Position ('CB', 2, 3);
  Ins_Position ('WB', 0, 2);
  Ins_Position ('MF', 3, 5);
  Ins_Position ('FW', 1, 3);
  Ins_Position ('AL', 12, 12);

  DELETE brazil_players;
  Ins_Player ('Atlético-PR', 'Éderson', 'FW', 17.12, 10.12);
  Ins_Player ('Vitória', 'Maxi Biancucchi', 'FW', 19.62, 10.05);
  Ins_Player ('Fluminense', 'Rafael Sobis', 'FW', 23.03, 9.55);
  Ins_Player ('Bahia', 'Fernandão', 'FW', 13.28, 8.22);
  Ins_Player ('São Paulo', 'Luis Fabiano', 'FW', 21.54, 7.58);
  Ins_Player ('Botafogo', 'Rafael Marques', 'FW', 19.74, 6.68);
  Ins_Player ('Cruzeiro', 'Dagoberto', 'FW', 22.11, 5.94);
  Ins_Player ('Náutico', 'Rogério', 'FW', 10.62, 5.7);
  Ins_Player ('Flamengo', 'Hernane', 'FW', 13.87, 4.98);
  Ins_Player ('Crisciúma', 'Lins', 'FW', 18.4, 4.9);
  Ins_Player ('Santos', 'Neilton', 'FW', 6.38, 4.88);
  Ins_Player ('Fluminense', 'Samuel', 'FW', 10.01, 4.87);
  Ins_Player ('Ponte Preta', 'Chiquinho', 'FW', 9.97, 4.64);
  Ins_Player ('Atlético-MG', 'Luan', 'FW', 13.18, 4.55);
  Ins_Player ('Ponte Preta', 'William', 'FW', 13.93, 4.44);
  Ins_Player ('Botafogo', 'Vitinho', 'FW', 10.2, 4.04);
  Ins_Player ('Coritiba', 'Deivid', 'FW', 15.9, 3.76);
  Ins_Player ('Grêmio', 'Barcos', 'FW', 18.96, 3.67);
  Ins_Player ('Atlético-MG', 'Jô', 'FW', 13.93, 3.4);
  Ins_Player ('São Paulo', 'Osvaldo', 'FW', 13.64, 3.12);
  Ins_Player ('Cruzeiro', 'Fábio', 'GK', 20.9, 7.94);
  Ins_Player ('Vitória', 'Wilson', 'GK', 12.39, 7.94);
  Ins_Player ('Coritiba', 'Vanderlei', 'GK', 18.58, 7.76);
  Ins_Player ('Atlético-MG', 'Victor', 'GK', 11.63, 4.67);
  Ins_Player ('Bahia', 'Marcelo Lomba', 'GK', 13.64, 4.5);
  Ins_Player ('Botafogo', 'Renan', 'GK', 6.77, 4.37);
  Ins_Player ('Flamengo', 'Felipe', 'GK', 15.26, 4.14);
  Ins_Player ('Grêmio', 'Dida', 'GK', 11.32, 3.75);
  Ins_Player ('Corinthians', 'Cássio', 'GK', 12.51, 3.74);
  Ins_Player ('Vasco', 'Michel Alves', 'GK', 8.99, 3.48);
  Ins_Player ('Crisciúma', 'Bruno', 'GK', 10.66, 3.2);
  Ins_Player ('Internacional', 'Muriel', 'GK', 9.81, 3.1);
  Ins_Player ('Santos', 'Rafael', 'GK', 17.82, 3);
  Ins_Player ('Atlético-PR', 'Weverton', 'GK', 6.16, 2.48);
  Ins_Player ('Fluminense', 'Ricardo Berna', 'GK', 4.6, 2.42);
  Ins_Player ('Portuguesa', 'Gledson', 'GK', 4.52, 2.1);
  Ins_Player ('São Paulo', 'Rogério Ceni', 'GK', 14.2, 1.17);
  Ins_Player ('Portuguesa', 'Ivan', 'WB', 7.55, 13.2);
  Ins_Player ('Vasco', 'Elsinho', 'WB', 14.68, 8.5);
  Ins_Player ('Cruzeiro', 'Egídio', 'WB', 14.82, 7.52);
  Ins_Player ('Fluminense', 'Carlinhos', 'WB', 12.4, 6.93);
  Ins_Player ('Náutico', 'Auremir', 'WB', 7.73, 5.48);
  Ins_Player ('Cruzeiro', 'Mayke', 'WB', 3.74, 5.25);
  Ins_Player ('Portuguesa', 'Luis Ricardo', 'WB', 8.58, 4.67);
  Ins_Player ('Atlético-MG', 'Richarlyson', 'WB', 10.2, 4.67);
  Ins_Player ('Internacional', 'Fabrício', 'WB', 8.76, 4.57);
  Ins_Player ('São Paulo', 'Juan', 'WB', 7.89, 4.57);
  Ins_Player ('São Paulo', 'Paulo Miranda', 'WB', 10.53, 4.54);
  Ins_Player ('Flamengo', 'João Paulo', 'WB', 7.15, 4.53);
  Ins_Player ('São Paulo', 'Rodrigo Caio', 'WB', 11.92, 4.52);
  Ins_Player ('Coritiba', 'Victor Ferraz', 'WB', 13.04, 4.2);
  Ins_Player ('Bahia', 'Jussandro', 'WB', 6.94, 4.1);
  Ins_Player ('Santos', 'Rafael Galhardo', 'WB', 12.88, 4.04);
  Ins_Player ('Goiás', 'William Matheus', 'WB', 5.87, 4.02);
  Ins_Player ('Náutico', 'Maranhão', 'WB', 6.53, 4.02);
  Ins_Player ('Internacional', 'Gabriel', 'WB', 11.81, 3.38);
  Ins_Player ('Goiás', 'Vítor', 'WB', 8.77, 3.36);
  Ins_Player ('Internacional', 'Fred', 'MF', 30.28, 8.92);
  Ins_Player ('Grêmio', 'Zé Roberto', 'MF', 25.93, 8.78);
  Ins_Player ('Internacional', 'Otavinho', 'MF', 7.62, 8.07);
  Ins_Player ('Vasco', 'Carlos Alberto', 'MF', 15.01, 6.75);
  Ins_Player ('Cruzeiro', 'Nilton', 'MF', 22.39, 6.46);
  Ins_Player ('Coritiba', 'Júnior Urso', 'MF', 14.38, 6.22);
  Ins_Player ('Crisciúma', 'João Vitor', 'MF', 13.27, 6.04);
  Ins_Player ('Corinthians', 'Guilherme', 'MF', 8.83, 5.87);
  Ins_Player ('Corinthians', 'Ralf', 'MF', 19.65, 5.7);
  Ins_Player ('Vitória', 'Escudero', 'MF', 16.38, 5.68);
  Ins_Player ('Portuguesa', 'Correa', 'MF', 8.44, 5.6);
  Ins_Player ('Portuguesa', 'Souza', 'MF', 12.62, 5.17);
  Ins_Player ('Coritiba', 'Alex', 'MF', 16.98, 5.08);
  Ins_Player ('Grêmio', 'Souza', 'MF', 13.8, 4.98);
  Ins_Player ('Ponte Preta', 'Cicinho', 'MF', 11.42, 4.72);
  Ins_Player ('Botafogo', 'Fellype Gabriel', 'MF', 8.6, 4.47);
  Ins_Player ('Atlético-PR', 'João Paulo', 'MF', 10.56, 4.38);
  Ins_Player ('Vasco', 'Sandro Silva', 'MF', 10.76, 4.28);
  Ins_Player ('Santos', 'Cícero', 'MF', 14.15, 4.18);
  Ins_Player ('Fluminense', 'Wagner', 'MF', 8.55, 4.13);
  Ins_Player ('Flamengo', 'Jaime De AlMFda', 'CO', 11.56, 8.03);
  Ins_Player ('Cruzeiro', 'Marcelo Oliveira', 'CO', 16.11, 5.43);
  Ins_Player ('Fluminense', 'Abel Braga', 'CO', 17.51, 5.36);
  Ins_Player ('Internacional', 'Dunga', 'CO', 14.22, 4.63);
  Ins_Player ('Vitória', 'Caio Júnior', 'CO', 11.4, 4.45);
  Ins_Player ('Grêmio', 'Vanderlei Luxemburgo', 'CO', 15.77, 4.42);
  Ins_Player ('São Paulo', 'Ney Franco', 'CO', 15.15, 4.39);
  Ins_Player ('Náutico', 'Levi Gomes', 'CO', 7.08, 4.2);
  Ins_Player ('Atlético-PR', 'Ricardo Drubscky', 'CO', 7.96, 3.92);
  Ins_Player ('Coritiba', 'Marquinhos Santos', 'CO', 10.59, 3.89);
  Ins_Player ('Vasco', 'Paulo Autuori', 'CO', 13.13, 3.61);
  Ins_Player ('Portuguesa', 'Edson Pimenta', 'CO', 3.67, 3.26);
  Ins_Player ('Botafogo', 'Oswaldo De Oliveira', 'CO', 10.77, 3.23);
  Ins_Player ('Corinthians', 'Tite', 'CO', 13.68, 3.17);
  Ins_Player ('Santos', 'Claudinei Oliveira', 'CO', 11.92, 3.17);
  Ins_Player ('Bahia', 'Cristóvão Borges', 'CO', 8.27, 2.92);
  Ins_Player ('Crisciúma', 'Vadão', 'CO', 7.04, 2.86);
  Ins_Player ('Goiás', 'Enderson Moreira', 'CO', 6.8, 2.53);
  Ins_Player ('Atlético-MG', 'Cuca', 'CO', 12.62, 2.32);
  Ins_Player ('Ponte Preta', 'Zé Sérgio', 'CO', 6.85, .75);
  Ins_Player ('Fluminense', 'Digão', 'CB', 9.31, 9.27);
  Ins_Player ('Flamengo', 'Samir', 'CB', 2.67, 6.8);
  Ins_Player ('Cruzeiro', 'Dedé', 'CB', 22.54, 6.4);
  Ins_Player ('São Paulo', 'Lúcio', 'CB', 21.71, 6.02);
  Ins_Player ('Grêmio', 'Bressan', 'CB', 10.85, 5.9);
  Ins_Player ('Atlético-PR', 'Manoel', 'CB', 16.99, 5.88);
  Ins_Player ('Ponte Preta', 'Cléber', 'CB', 14.61, 5.78);
  Ins_Player ('Cruzeiro', 'Bruno Rodrigo', 'CB', 15.47, 5.28);
  Ins_Player ('Santos', 'Edu Dracena', 'CB', 16.82, 4.97);
  Ins_Player ('Náutico', 'William Alves', 'CB', 5.56, 4.43);
  Ins_Player ('Fluminense', 'Gum', 'CB', 12.18, 4.22);
  Ins_Player ('Flamengo', 'Wallace', 'CB', 4.29, 4.2);
  Ins_Player ('Náutico', 'João Filipe', 'CB', 5.47, 4.1);
  Ins_Player ('Grêmio', 'Werley', 'CB', 15.9, 4.03);
  Ins_Player ('Corinthians', 'Gil', 'CB', 13.23, 3.98);
  Ins_Player ('Vitória', 'Gabriel Paulista', 'CB', 11.77, 3.94);
  Ins_Player ('Goiás', 'Ernando', 'CB', 10.24, 3.74);
--  DELETE players WHERE player_name > 'Cristóvão Borges';--'Gil';-- 'Cássio';
END;
/
