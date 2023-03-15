# Scripts that transform the SQLite Lemon parser rules to Fuzzer internal representation

Steps:
1. Use the lemon parser from the SQLite repo, copy the original lemon parser rule to the assets folder, rename it as `sqlite_ori_parse.y`.
2. Run the `translate_cov.py` (or `translate.py` script, deprecated) script.
4. Run the `lemon ./sqlite_lemon_parser.y` in the current folder, generate the `sqlite_lemon_parser.h` and `sqlite_lemon_parser.c` files.
5. If step `4` is executed correctly, we can directly copy the `sqlite_lemon_parser.y` file to the `SQLite/docker/src/parser` folder.
