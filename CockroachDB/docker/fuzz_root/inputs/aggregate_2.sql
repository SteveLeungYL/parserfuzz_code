CREATE TABLE xy(x STRING, y STRING);
INSERT INTO ab(a,b) VALUES (1,2), (3,4);
INSERT INTO xy(x, y) VALUES ('a', 'b'), ('c', 'd');
INSERT INTO index_tab (VALUES ('US_WEST', 3), ('US_EAST', 23), ('US_EAST', -14), ('ASIA', 3294), ('ASIA', -3), ('US_WEST', 31), ('EUROPE', 123), ('US_EAST', -3000));
SELECT max(data) FROM index_tab WHERE region = 'US_WEST' OR region = 'US_EAST';
