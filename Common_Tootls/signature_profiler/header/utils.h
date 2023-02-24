#ifndef SIGNATURE_PROFILER_UTILS_H
#define SIGNATURE_PROFILER_UTILS_H

#include <string>
#include <vector>
#include <random>
#include <algorithm>

using std::string;
using std::vector;

std::vector<string> string_splitter(const string &input_string,
                                    string delimiter_re);

static std::random_device rd; // random device engine, usually based on
                              // /dev/random on UNIX-like systems
// initialize Mersennes' twister using rd to generate the seed
static std::mt19937 rng{rd()};

#define vector_rand_ele_safe(a)                                                \
  (a.size() != 0 ? a[get_rand_int(a.size())] : gen_id_name())

#define vector_rand_ele(a) (a[get_rand_int(a.size())])

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

inline string str_toupper(string str_in) {
  std::transform(str_in.begin(), str_in.end(), str_in.begin(),
                 [](unsigned char c){ return std::toupper(c); });

  return str_in;
}

// remove leading and ending spaces
// reduce 2+ spaces to one
// change ' ;' to ';'
inline void trim_string(string &res) {

  // string::iterator new_end = unique(res.begin(), res.end(), BothAreSpaces);
  // res.erase(new_end, res.end());

  // res.erase(0, res.find_first_not_of(' '));
  // res.erase(res.find_last_not_of(' ') + 1);

  int effect_idx = 0, idx = 0;
  bool prev_is_space = false;
  int sz = res.size();

  // skip leading spaces
  for (; idx < sz && res[idx] == ' '; idx++)
    ;

  // now idx points to the first non-space character
  for (; idx < sz; idx++) {

    char &c = res[idx];

    if (c == ' ') {

      if (prev_is_space)
        continue;

      prev_is_space = true;
      res[effect_idx++] = c;

    } else if (c == ';' || c == ',') {

      if (prev_is_space)
        res[effect_idx - 1] = c;
      else
        res[effect_idx++] = c;

      prev_is_space = false;

    } else {

      prev_is_space = false;
      res[effect_idx++] = c;
    }
  }

  if (effect_idx > 0 && res[effect_idx - 1] == ' ')
    effect_idx--;

  res.resize(effect_idx);
}

inline string::const_iterator findStringIter(const std::string &strHaystack,
                                      const std::string &strNeedle) {
  auto it =
      std::search(strHaystack.begin(), strHaystack.end(), strNeedle.begin(),
                  strNeedle.end(), [](char ch1, char ch2) {
            return std::toupper(ch1) == std::toupper(ch2);
          });
  return it;
}

inline bool findStringIn(const std::string &strHaystack,
                  const std::string &strNeedle) {
  return (findStringIter(strHaystack, strNeedle) != strHaystack.end());
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

inline bool is_str_empty(const string& input_str) {
  for (int i = 0; i < input_str.size(); i++) {
    char c = input_str[i];
    if (!isspace(c) && c != '\n' && c != '\0')
      return false; // Not empty.
  }
  return true; // Empty
}

#endif // SIGNATURE_PROFILER_UTILS_H
