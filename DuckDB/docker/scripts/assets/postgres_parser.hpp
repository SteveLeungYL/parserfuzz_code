//===----------------------------------------------------------------------===//
//                         DuckDB
//
// postgres_parser.hpp
//
//
//===----------------------------------------------------------------------===//

#pragma once

#include <string>
#include <vector>
#include "nodes/pg_list.hpp"
#include "pg_simplified_token.hpp"
#include "duckdb/common/vector.hpp"

namespace duckdb_libpgquery {
	class IR;
}

namespace duckdb {

class PostgresParser {
public:
	PostgresParser();
	~PostgresParser();

	bool success;
	duckdb_libpgquery::PGList *parse_tree;
	std::string error_message;
	int error_location;
public:
	void Parse(const std::string &query);
	std::vector<duckdb_libpgquery::IR*> Parse_ret_ir(const std::string &query);

	static duckdb::vector<duckdb_libpgquery::PGSimplifiedToken> Tokenize(const std::string &query);

	static bool IsKeyword(const std::string &text);
	static duckdb::vector<duckdb_libpgquery::PGKeyword> KeywordList();

	static void SetPreserveIdentifierCase(bool downcase);
};

}
