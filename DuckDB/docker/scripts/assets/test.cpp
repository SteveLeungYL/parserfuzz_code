#include <iostream>
#include <vector>
#include "sql_ir_define.hpp"

using namespace std;

using namespace duckdb_libpgquery;

namespace duckdb_libpgquery {
	class IR;
	void pg_parser_init();
	void pg_parser_parse_ret_ir(const char *query, std::vector<IR*>& res);
	void pg_parser_cleanup();
}


int main() {

	pg_parser_init();

	string a = "select * from v0;";

	vector<IR*> ir_vec;

	duckdb_libpgquery::pg_parser_parse_ret_ir(a.c_str(), ir_vec);

	cout << ir_vec.size() << "\n\n\n";

	cout << ir_vec.back()->to_string() << "\n\n\n";

	ir_vec.back()->deep_drop();

	return 0;
}



