#ifndef __UTILS_H__
#define __UTILS_H__

#include "define.h"
#include "ast.h"
#include "../parser/bison_parser.h"
#include "../parser/flex_lexer.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/types.h>
#include <dirent.h>
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <random>
#include <string>
#include <vector>

using std::string;

static std::random_device rd; // random device engine, usually based on /dev/random on UNIX-like systems
// initialize Mersennes' twister using rd to generate the seed
static std::mt19937 rng{rd()};

// inline int get_rand_int(int range) {
//     if (range != 0) return rand()%(range);
//     else return 0;
// }
inline int get_rand_int(int range) {
    if (range != 0) {
        std::uniform_int_distribution<int> uid(0, range-1);
        return uid(rng);
    }
    else return 0;
}
//#define vector_rand_ele(a) (a[get_rand_int(a.size())])
#define vector_rand_ele(a) (a.size()!=0?a[get_rand_int(a.size())]:gen_id_name())

Program * parser(const char * sql);
string get_string_by_type(IRTYPE);
void print_ir(IR * ir);
void print_v_ir(vector<IR *> &v_ir_collector);
uint64_t fucking_hash ( const void * key, int len );
void trim_string(string &);
vector<string> get_all_files_in_dir( const char * dir_name );
string magic_string_generator(string& s);

#endif
