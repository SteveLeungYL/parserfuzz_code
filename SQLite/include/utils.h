#ifndef __UTILS_H__
#define __UTILS_H__

//#include "define.h"
//#include "ast.h"

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
#include <iostream>

using namespace std;

#define vector_rand_ele(a) \
  (a.size() != 0? \
   a[get_rand_int(a.size())]: \
   (*a.insert(a.begin(),gen_id_name())) \
  )

static std::random_device rd; // random device engine, usually based on /dev/random on UNIX-like systems
// initialize Mersennes' twister using rd to generate the seed
static std::mt19937 rng{rd()};

inline int get_rand_int(int range) {
    if (range != 0) {
        std::uniform_int_distribution<int> uid(0, range-1);
        return uid(rng);
    }
    else return 0;
}
uint64_t fuzzing_hash ( const void * key, int len );
void trim_string(string &);
std::vector<string> get_all_files_in_dir( const char * dir_name );
string magic_string_generator(string& s);
void  ensure_semicolon_at_query_end(string&);
std::vector<string> string_splitter(const string& input_string, string delimiter_re);
std::vector<string> string_splitter2(const string& input_string, const char delimiter_re);
bool is_str_empty(string input_str);


#endif
