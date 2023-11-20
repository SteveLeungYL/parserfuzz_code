#ifndef __UTILS_H__
#define __UTILS_H__

#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <dirent.h>
#include <iostream>
#include <random>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <vector>
#include <algorithm>

using namespace std;

#define vector_rand_ele(a) (a[get_rand_int(a.size())])

static std::random_device rd; // random device engine, usually based on
                              // /dev/random on UNIX-like systems
// initialize Mersennes' twister using rd to generate the seed
static std::mt19937 rng{rd()};

// #define get_rand_int(range) rand() % (range)
inline int get_rand_int(int range) {
  if (range != 0) {
    std::uniform_int_distribution<int> uid(0, range - 1);
    return uid(rng);
  } else
    return 0;
}

inline int get_rand_int(int start, int end) {
  int range = end - start;
  if (range > 0) {
    std::uniform_int_distribution<int> uid(0, range - 1);
    int res = uid(rng);
    res += start;
    return res;
  } else {
    return 0;
  }
}

inline long long get_rand_long_long(long long range) {

  if (range > 0) {
    std::uniform_int_distribution<long long> uid(0, range-1);
    return uid(rng);
  } else {
    return 0;
  }
}

inline long long get_rand_long_long(long long start, long long end) {
  long long range = end - start;
  if (range > 0) {
    std::uniform_int_distribution<long long> uid(0, range - 1);
    long long res = uid(rng);
    res += start;
    return res;
  } else {
    return 0;
  }
}

inline float get_rand_float(float min, float max) {
  if ((max - min) < 0) {
    return 0.0;
  } else if ((max-min) == 0) {
    return min;
  }
  int rand_int = get_rand_int(RAND_MAX);
  return ((max - min) * ((float)rand_int / RAND_MAX)) + min;
}

inline float get_rand_float(float max) {
  return get_rand_float(0, max);
}

inline double get_rand_double(double min, double max) {
  if ((max - min) < 0) {
    return 0.0;
  } else if ((max-min) == 0) {
    return min;
  }
  int rand_int = get_rand_int(RAND_MAX);
  return ((max - min) * ((double)rand_int / RAND_MAX)) + min;
}

inline double get_rand_double(double max) {
  return get_rand_double(0, max);
}

uint64_t fuzzing_hash(const void *key, int len);
void trim_string(string &);
std::vector<string> get_all_files_in_dir(const char *dir_name);
string magic_string_generator(string &s);
void ensure_semicolon_at_query_end(string &);

vector<string> string_splitter(const string &in, string delimiter);

bool is_str_empty(string input_str);

int findStringCount(const std::string &strHaystack,
                    const std::string &strNeedle);
string::const_iterator findStringIter(const std::string &strHaystack,
                                      const std::string &strNeedle);
bool findStringIn(const std::string &strHaystack, const std::string &strNeedle);

inline string str_toupper(string str_in) {
  std::transform(str_in.begin(), str_in.end(), str_in.begin(),
                 [](unsigned char c){ return std::toupper(c); });

  return str_in;
}

inline uint64_t get_str_hash(const void *key, int len) {
  const uint64_t m = 0xc6a4a7935bd1e995;
  const int r = 47;
  uint64_t h = 0xdeadbeefdeadbeef ^ (len * m);

  const uint64_t *data = (const uint64_t *)key;
  const uint64_t *end = data + (len / 8);

  while (data != end) {
    uint64_t k = *data++;

    k *= m;
    k ^= k >> r;
    k *= m;

    h ^= k;
    h *= m;
  }

  const unsigned char *data2 = (const unsigned char *)data;

  switch (len & 7) {
  case 7:
    h ^= uint64_t(data2[6]) << 48;
  case 6:
    h ^= uint64_t(data2[5]) << 40;
  case 5:
    h ^= uint64_t(data2[4]) << 32;
  case 4:
    h ^= uint64_t(data2[3]) << 24;
  case 3:
    h ^= uint64_t(data2[2]) << 16;
  case 2:
    h ^= uint64_t(data2[1]) << 8;
  case 1:
    h ^= uint64_t(data2[0]);
    h *= m;
  };

  h ^= h >> r;
  h *= m;
  h ^= h >> r;

  return h;
}

/* Execution status fault codes */
enum EXEC_RESULT_CODE {
  FAULT_NONE = 0,
  FAULT_CRASH = 1,
  FAULT_TMOUT = 2,
  FAULT_ERROR = 3,
  FAULT_RESULT_ALL_ERROR = 3,
  FAULT_NOINST = 4,
  FAULT_NOBITS = 5
};

struct ALL_COMP_RES {
  vector<EXEC_RESULT_CODE> v_res;
  EXEC_RESULT_CODE final_res = FAULT_NONE;
  vector<string> v_cmd_str;
  vector<string> v_res_str;
};

#endif
