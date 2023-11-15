import os
import sys
from loguru import logger
import shutil

if len(sys.argv) != 3:
    logger.error(f"Error, failed to parse the input arguments. Example: python3 setup_deuckdb_ir.py assets_dir duckdb_dir")
    exit(1)

base_dir = sys.argv[1]
target_dir = sys.argv[2]

os.chdir(target_dir)

# Generate the bison and flex file first.
_ = os.system("python3 scripts/generate_grammar.py && python3 scripts/generate_flex.py")

os.chdir(os.path.join(target_dir, "third_party/libpg_query/"))

shutil.copy2(os.path.join(base_dir, "grammar_modi.y"), "grammar/grammar.y.tmp")
shutil.copy2(os.path.join(base_dir, "gramparse.hpp"), "include/parser/gramparse.hpp")
shutil.copy2(os.path.join(base_dir, "parser.hpp"), "include/parser/parser.hpp")
shutil.copy2(os.path.join(base_dir, "pg_functions.hpp"), "include/pg_functions.hpp")
shutil.copy2(os.path.join(base_dir, "postgres_parser.hpp"), "include/postgres_parser.hpp")
shutil.copy2(os.path.join(base_dir, "sql_ir_define.hpp"), "include/parser/sql_ir_define.hpp")
shutil.copy2(os.path.join(base_dir, "pg_functions.cpp"), "pg_functions.cpp")
shutil.copy2(os.path.join(base_dir, "postgres_parser.cpp"), "postgres_parser.cpp")
shutil.copy2(os.path.join(base_dir, "src_backend_parser_parser.cpp"), "src_backend_parser_parser.cpp")

# Bison compile the grammar file
os.chdir(os.path.join(target_dir, "third_party/libpg_query/grammar"))
_ = os.system("bison -o grammar_out.cpp -d grammar.y.tmp")
shutil.copy2("grammar_out.cpp", "../src_backend_parser_gram.cpp")
shutil.copy2("grammar_out.hpp", "../include/parser/gram.hpp")

