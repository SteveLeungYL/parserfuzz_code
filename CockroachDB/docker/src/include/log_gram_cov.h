//
// Created by Yu Liang on 7/3/23.
//

#ifndef SRC_LOG_GRAM_COV_H
#define SRC_LOG_GRAM_COV_H

#include "ast.h"
#include "../AFL/types.h"
#include "../AFL/config.h"

#include <filesystem>
#include <fstream>
#include <mutex>
#include <cstring>

using namespace std;

void log_grammar_coverage(IR* root);

class GramCovMap {

private:
  std::mutex edge_map_mutex;

public:
  GramCovMap() {
    this->block_cov_map = new unsigned char[MAP_SIZE]();
    memset(this->block_cov_map, 0, MAP_SIZE);
    this->block_virgin_map = new unsigned char[MAP_SIZE]();
    memset(this->block_virgin_map, 0xff, MAP_SIZE);

    this->edge_cov_map = new unsigned char[MAP_SIZE]();
    memset(this->edge_cov_map, 0, MAP_SIZE);

    this->edge_virgin_map = new unsigned char[MAP_SIZE]();
    memset(this->edge_virgin_map, 0xff, MAP_SIZE);
    edge_prev_cov = 0;
  }
  ~GramCovMap() {
    delete[](this->block_cov_map);
    delete[](this->block_virgin_map);
    delete[](this->edge_cov_map);
    delete[](this->edge_virgin_map);
  }

  u8 has_new_grammar_bits(bool is_debug = false, const string in = "") {
#ifdef LOGBLOCKCOV
    // Only for debugging purpose.
    has_new_grammar_bits(this->block_cov_map, this->block_virgin_map, true, in);
#endif
    return has_new_grammar_bits(this->edge_cov_map, this->edge_virgin_map, is_debug, in);
  }

  u8 has_new_grammar_bits(u8 *cur_cov_map, u8 *cur_virgin_map,
                          bool is_debug, const string in) {
    edge_map_mutex.lock();

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)

    u64 *current = (u64 *)cur_cov_map;
    u64 *virgin = (u64 *)cur_virgin_map;

    u32 i = (MAP_SIZE >> 3);

#else

    u32 *current = (u32 *)this->cov_map;
    u32 *virgin = (u32 *)this->virgin_map;

    u32 i = (MAP_SIZE >> 2);

#endif /* ^__x86_64__ __arm64__ __aarch64__ */

    u8 ret = 0;

    while (i--) {

      /* Optimize for (*current & *virgin) == 0 - i.e., no bits in current bitmap
         that have not been already cleared from the virgin map - since this will
         almost always be the case. */

      if (unlikely(*current) && unlikely(*current & *virgin)) {

        if (likely(ret < 2) || unlikely(is_debug)) {

          u8 *cur = (u8 *)current;
          u8 *vir = (u8 *)virgin;

          /* Looks like we have not found any new bytes yet; see if any non-zero
             bytes in current[] are pristine in virgin[]. */

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)

          if ((cur[0] && vir[0] == 0xff) || (cur[1] && vir[1] == 0xff) ||
              (cur[2] && vir[2] == 0xff) || (cur[3] && vir[3] == 0xff) ||
              (cur[4] && vir[4] == 0xff) || (cur[5] && vir[5] == 0xff) ||
              (cur[6] && vir[6] == 0xff) || (cur[7] && vir[7] == 0xff)) {
            ret = 2;
            if (unlikely(is_debug)) {
              vector<u8> byte = get_cur_new_byte(cur, vir);
              for (const u8 &cur_byte : byte) {
                this->gram_log_map_id(i, cur_byte, in);
              }
            }
          } else if (unlikely(ret != 2))
            ret = 1;

#else

          if ((cur[0] && vir[0] == 0xff) || (cur[1] && vir[1] == 0xff) ||
              (cur[2] && vir[2] == 0xff) || (cur[3] && vir[3] == 0xff))
            ret = 2;
          else if (unlikely(ret != 2))
            ret = 1;

#endif /* ^__x86_64__ __arm64__ __aarch64__ */
        }
        *virgin &= ~*current;
      }

      current++;
      virgin++;
    }

    edge_map_mutex.unlock();
    return ret;
  }

  void reset_block_cov_map() { memset(this->block_cov_map, 0, MAP_SIZE); }
  void reset_block_virgin_map() { memset(this->block_virgin_map, 0xff, MAP_SIZE); }

  void reset_edge_cov_map() {
    edge_map_mutex.lock();
    memset(this->edge_cov_map, 0, MAP_SIZE);
    edge_prev_cov = 0;
    edge_map_mutex.unlock();
  }
  void reset_edge_virgin_map() {
    edge_map_mutex.lock();
    memset(this->edge_virgin_map, 0xff, MAP_SIZE);
    edge_prev_cov = 0;
    edge_map_mutex.unlock();
  }

  void log_cov_map(unsigned int cur_cov) {
    edge_map_mutex.lock();
    unsigned int offset = (edge_prev_cov ^ cur_cov);
    if (edge_cov_map[offset] < 0xff) {
      edge_cov_map[offset]++;
    }
    edge_prev_cov = (cur_cov >> 1);
    edge_map_mutex.unlock();

    if (block_cov_map[cur_cov] < 0xff) {
      block_cov_map[cur_cov]++;
    }
  }

  void log_edge_cov_map(unsigned int prev_cov, unsigned int cur_cov) {
    edge_map_mutex.lock();
    unsigned int offset = ((prev_cov >> 1) ^ cur_cov);
    if (edge_cov_map[offset] < 0xff) {
      edge_cov_map[offset]++;
    }
#ifdef LOGBLOCKCOV
    if (block_cov_map[cur_cov] < 0xff) {
      block_cov_map[cur_cov]++;
    }
#endif
    edge_map_mutex.unlock();
    return;
  }

  inline double get_total_block_cov_size() {
    u32 t_bytes = this->count_non_255_bytes(this->block_virgin_map);
    return ((double)t_bytes * 100.0) / MAP_SIZE;
  }
  inline u32 get_total_block_cov_size_num() {
    return this->count_non_255_bytes(this->block_virgin_map);
  }

  inline double get_total_edge_cov_size() {
    edge_map_mutex.lock();
    u32 t_bytes = this->count_non_255_bytes(this->edge_virgin_map);
    edge_map_mutex.unlock();
    return ((double)t_bytes * 100.0) / MAP_SIZE;
  }
  inline u32 get_total_edge_cov_size_num() {
    edge_map_mutex.lock();
    u32 res = this->count_non_255_bytes(this->edge_virgin_map);
    edge_map_mutex.unlock();
    return res;
  }

  unsigned char *get_edge_cov_map() { return this->edge_cov_map; }

private:
  unsigned char *block_cov_map = nullptr;
  unsigned char *block_virgin_map = nullptr;
  unsigned char *edge_cov_map = nullptr;
  unsigned char *edge_virgin_map = nullptr;
  unsigned int edge_prev_cov;

  /* Count the number of non-255 bytes set in the bitmap. Used strictly for the
   status screen, several calls per second or so. */
  // Copy from afl-fuzz.
  u32 count_non_255_bytes(u8 *mem) {
#define FF(_b) (0xff << ((_b) << 3))
    u32 *ptr = (u32 *)mem;
    u32 i = (MAP_SIZE >> 2);
    u32 ret = 0;

    while (i--) {

      u32 v = *(ptr++);

      /* This is called on the virgin bitmap, so optimize for the most likely
         case. */

      if (v == 0xffffffff)
        continue;
      if ((v & FF(0)) != FF(0))
        ret++;
      if ((v & FF(1)) != FF(1))
        ret++;
      if ((v & FF(2)) != FF(2))
        ret++;
      if ((v & FF(3)) != FF(3))
        ret++;
    }

    return ret;
#undef FF
  }

  inline vector<u8> get_cur_new_byte(u8 *cur, u8 *vir) {
    vector<u8> new_byte_v;
    for (u8 i = 0; i < 8; i++) {
      if (cur[i] && vir[i] == 0xff)
        new_byte_v.push_back(i);
    }
    return new_byte_v;
  }

  inline void gram_log_map_id (u32 i, u8 byte, const string in = "") {
    fstream gram_id_out;
    i = (MAP_SIZE >> 3) - i - 1 ;
    u32 actual_idx = i * 8 + byte;

    if (!filesystem::exists("./gram_cov.txt")) {
      gram_id_out.open("./gram_cov.txt", std::fstream::out |
                                             std::fstream::trunc);
    } else {
      gram_id_out.open("./gram_cov.txt", std::fstream::out |
                                             std::fstream::app);
    }
    gram_id_out << actual_idx << endl;
    gram_id_out.flush();
    gram_id_out.close();

    if (!filesystem::exists("./new_gram_file/")) {
      filesystem::create_directory("./new_gram_file/");
    }
    fstream map_id_seed_output;
    map_id_seed_output.open(
        "./new_gram_file/" + to_string(actual_idx) + ".txt",
        std::fstream::out | std::fstream::trunc);
    map_id_seed_output << in;
    map_id_seed_output.close();

  }
};

#endif // SRC_LOG_GRAM_COV_H
