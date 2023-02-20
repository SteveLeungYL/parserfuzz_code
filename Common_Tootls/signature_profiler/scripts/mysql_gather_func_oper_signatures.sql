SET GLOBAL log_bin_trust_function_creators = 1;

CREATE DATABASE IF NOT EXISTS test;
use test;

DROP FUNCTION IF EXISTS get_from_delimiter_split_string;
DROP FUNCTION IF EXISTS grab_signature;

CREATE FUNCTION get_from_delimiter_split_string (
    in_array TEXT,
    in_delimiter char(1),
    in_index int
)
    RETURNS TEXT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
RETURN REPLACE( -- remove the delimiters after doing the following:
  SUBSTRING( -- pick the string
    SUBSTRING_INDEX(in_array, in_delimiter, in_index + 1), -- from the string up to index+1 counts of the delimiter
    LENGTH(
      SUBSTRING_INDEX(in_array, in_delimiter, in_index) -- keeping only everything after index counts of the delimiter
    ) + 1
  ),
  in_delimiter,
  ''
);

DELIMITER //
CREATE FUNCTION grab_signature(in_text TEXT)
    RETURNS TEXT

BEGIN
        DECLARE res TEXT;
        IF in_text LIKE 'Syntax:%' THEN SET res = get_from_delimiter_split_string(in_text, '\n', 1);
ELSE SET res = get_from_delimiter_split_string(in_text, '\n', 0);
END IF;
RETURN res;
END //
DELIMITER ;

SELECT help_category.name AS 'TYPE', grab_signature(description) FROM mysql.help_topic left join mysql.help_category on help_category.help_category_id = help_topic.help_category_id where help_topic.help_category_id in (5, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 33, 34, 35, 36, 37, 38, 39)\G