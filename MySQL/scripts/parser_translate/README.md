1. Copy all the keyword mapping from the MySQL lex.h header. 

```c
// From the following
static const SYMBOL symbols[] = {
...
    {SYM("&&", AND_AND_SYM)},
    {SYM("<", LT)},
    {SYM("<=", LE)},
    {SYM("<>", NE)},
...
// AND
...
    {SYM_HK("DELETE", DELETE_SYM)},
    {SYM_HK("INSERT", INSERT_SYM)},
    {SYM_HK("REPLACE", REPLACE_SYM)},
    {SYM_HK("SELECT", SELECT_SYM)},
    {SYM_HK("UPDATE", UPDATE_SYM)},
...
```

Changed it to the format of CSV: 

```csv
Value,Symbol
"&&","AND_AND_SYM"
"<","LT"
"<=","LE"
"<>","NE"
```




