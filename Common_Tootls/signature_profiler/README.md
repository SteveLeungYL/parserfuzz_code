# Notes to auto gather function and operator signatures from the DBMSs

## MySQL:

Run the script [link](./scripts/mysql_gather_func_oper_signatures.sql) from the MySQL client, we can gather the function and operator signatures from the MySQL DBMS directly.

```bash
./bin/mysql --socket=/tmp/mysql_0.sock  -u root < ./mysql_gather_func_oper_signatures.sql > ./mysql_func_opr_sign
```

There are a few minor corrections that needed to be applied in the auto generated file. 

1. Change the following function/operator signatures, because the script doesn't capture the full forms of them.

```
asymmetric_verify(algorithm, digest_str, sig_str, pub_key_str,
->
asymmetric_verify(algorithm, digest_str, sig_str, pub_key_str, digest_type)

CASE value WHEN compare_value THEN result [WHEN compare_value THEN
->
CASE value WHEN compare_value THEN result [WHEN compare_value THEN result ...] [ELSE result] END, CASE WHEN condition THEN result [WHEN condition THEN result ...] [ELSE result] END

N % M, N MOD M
->
%, MOD

MOD(N,M), N % M, N MOD M
->
MOD(X,Y)

SUBSTR(str,pos), SUBSTR(str FROM pos), SUBSTR(str,pos,len), SUBSTR(str
->
SUBSTR(str,pos), SUBSTR(str FROM pos), SUBSTR(str,pos,len), SUBSTR(str FROM pos FOR len)

SUBSTRING(str,pos), SUBSTRING(str FROM pos), SUBSTRING(str,pos,len),
->
SUBSTRING(str,pos), SUBSTRING(str FROM pos), SUBSTRING(str,pos,len), SUBSTRING(str FROM pos FOR len)

TRIM([{BOTH | LEADING | TRAILING} [remstr] FROM] str), TRIM([remstr
->
TRIM([{BOTH | LEADING | TRAILING} [remstr] FROM] str), TRIM([remstr FROM] str)

REGEXP_INSTR(expr, pat[, pos[, occurrence[, return_option[,
->
REGEXP_INSTR(expr, pat[, pos[, occurrence[, return_option[, match_type]]]])

CURRENT_DATE, CURRENT_DATE()
->
CURRENT_DATE()

CURRENT_TIME, CURRENT_TIME([fsp])
->
CURRENT_TIME([fsp])

CURRENT_TIMESTAMP, CURRENT_TIMESTAMP([fsp])
->
CURRENT_TIMESTAMP([fsp])

UTC_DATE, UTC_DATE()
->
UTC_DATE()

UTC_TIME, UTC_TIME([fsp])
->
UTC_TIME([fsp])

UTC_TIMESTAMP, UTC_TIMESTAMP([fsp])
->
UTC_TIMESTAMP([fsp])

CURRENT_USER, CURRENT_USER()
->
CURRENT_USER()
```