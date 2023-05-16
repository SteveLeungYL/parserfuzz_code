#ifndef __PARSER_ENTRY_H__
#define __PARSER_ENTRY_H__

#include <vector>
#include <string>

using namespace std;

class IR;

void run_parser(string in, vector<IR*>&);

#endif