#include <iostream>
#include <vector>

using namespace std;

namespace duckdb_libpgquery {
	class IR;
	void pg_parser_init();
	void pg_parser_parse_ret_ir(const char *query, std::vector<IR*>& res);
	void pg_parser_cleanup();
}


int main() {

	duckdb_libpgquery::pg_parser_init();

	string a = "select * from v0;";

	vector<duckdb_libpgquery::IR*> ir_vec;

	duckdb_libpgquery::pg_parser_parse_ret_ir(a.c_str(), ir_vec);

	cout << ir_vec.size() << "\n\n\n";

	return 0;
}

