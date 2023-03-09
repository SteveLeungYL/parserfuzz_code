# Scripts that transform the SQLite Lemon parser rules to Fuzzer internal representation

Steps:
1. Use the lemon parser from the SQLite repo, generate the parser rule file. 

```bash
./lemon -g ./parse.y &> sqlite_parse_rule_only.y
```
