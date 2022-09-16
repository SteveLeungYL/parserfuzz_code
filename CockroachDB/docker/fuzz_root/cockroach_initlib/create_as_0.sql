CREATE TABLE stock (item, quantity) AS VALUES ('cups', 10), ('plates', 15), ('forks', 30)
CREATE TABLE runningOut AS SELECT * FROM stock WHERE quantity < 12;
CREATE TABLE itemColors (color) AS VALUES ('blue'), ('red'), ('green');
CREATE TABLE smtng.something AS SELECT * FROM stock;

