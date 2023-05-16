import time

prefix_str = """\
#ifndef ANTLR_TEST_MySQLGrammarCovVisitor_H
#define ANTLR_TEST_MySQLGrammarCovVisitor_H

// DO NOT MODIFY THIS FILE. 
// This code is generated from PYTHON script generate_MySQLGrammarCovVisitor.h. 
// Use ANTLR4 to generate the MySQLParserBaseVisitor.h in ../grammar/ before calling the python generation script.

#include <iostream>
#include <cstring>
#include <filesystem>

#include "../MySQLBaseCommon.h"
#include "./grammar_cov_hash_header.h"
#include "../grammar/MySQLParserBaseVisitor.h"

using namespace std;
using namespace parsers;

//#define DEBUG

class GramCovMap {

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
//    has_new_grammar_bits(this->block_cov_map, this->block_virgin_map, is_debug);
    return has_new_grammar_bits(this->edge_cov_map, this->edge_virgin_map, is_debug, in);
  }
  
  u8 has_new_grammar_bits(u8 *cur_cov_map, u8 *cur_virgin_map,
                                    bool is_debug, const string in) {
  
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
    
      return ret;
      }

  void reset_block_cov_map() { memset(this->block_cov_map, 0, MAP_SIZE); }
  void reset_block_virgin_map() { memset(this->block_virgin_map, 0, MAP_SIZE); }

  void reset_edge_cov_map() {
    memset(this->edge_cov_map, 0, MAP_SIZE);
    edge_prev_cov = 0;
  }
  void reset_edge_virgin_map() {
    memset(this->edge_virgin_map, 0, MAP_SIZE);
    edge_prev_cov = 0;
  }

  void log_cov_map(unsigned int cur_cov) {
    unsigned int offset = (edge_prev_cov ^ cur_cov);
    if (edge_cov_map[offset] < 0xff) {
      edge_cov_map[offset]++;
    }
    edge_prev_cov = (cur_cov >> 1);

    if (block_cov_map[cur_cov] < 0xff) {
      block_cov_map[cur_cov]++;
    }
  }

  void log_edge_cov_map(unsigned int prev_cov, unsigned int cur_cov) {
    unsigned int offset = ((prev_cov >> 1) ^ cur_cov);
    if (edge_cov_map[offset] < 0xff) {
      edge_cov_map[offset]++;
    }
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
    u32 t_bytes = this->count_non_255_bytes(this->edge_virgin_map);
    return ((double)t_bytes * 100.0) / MAP_SIZE;
  }
  inline u32 get_total_edge_cov_size_num() {
    return this->count_non_255_bytes(this->edge_virgin_map);
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

class MySQLGrammarCovVisitor: public parsers::MySQLParserBaseVisitor {
private:
  unsigned char cov_map[262144];
  // A randomly generated but fixed Hash Array.
  HASHARRAYDEFINE;
  
  MySQLParser* p_parser;

public:

  void set_parser(MySQLParser* in) {this->p_parser = in;}
  
  GramCovMap gram_cov;

  MySQLGrammarCovVisitor() {
    memset(cov_map, 0, 262144);
  }

"""

visit_body_str = """\
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\\n\\n\\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
"""

suffix_str = """\

};

#endif
"""

with open("../grammar/MySQLParserBaseVisitor.h", "r") as base_vis, open("./MySQLGrammarCovVisitor.h", "w") as fd:

    fd.write(prefix_str)

    for cur_line in base_vis.readlines():
        if "virtual std::any visit" in cur_line:
            fd.write(cur_line)
            fd.write(visit_body_str)

    fd.write(suffix_str)





