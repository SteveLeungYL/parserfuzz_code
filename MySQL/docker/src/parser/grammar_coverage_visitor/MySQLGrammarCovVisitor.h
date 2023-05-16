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
#include "../..//AFL/types.h"

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

  virtual std::any visitQuery(MySQLParser::QueryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleStatement(MySQLParser::SimpleStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterStatement(MySQLParser::AlterStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterDatabase(MySQLParser::AlterDatabaseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterEvent(MySQLParser::AlterEventContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterLogfileGroup(MySQLParser::AlterLogfileGroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterLogfileGroupOptions(MySQLParser::AlterLogfileGroupOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterLogfileGroupOption(MySQLParser::AlterLogfileGroupOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterServer(MySQLParser::AlterServerContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterTable(MySQLParser::AlterTableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterTableActions(MySQLParser::AlterTableActionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterCommandList(MySQLParser::AlterCommandListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterCommandsModifierList(MySQLParser::AlterCommandsModifierListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitStandaloneAlterCommands(MySQLParser::StandaloneAlterCommandsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterPartition(MySQLParser::AlterPartitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterList(MySQLParser::AlterListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterCommandsModifier(MySQLParser::AlterCommandsModifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterListItem(MySQLParser::AlterListItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPlace(MySQLParser::PlaceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRestrict(MySQLParser::RestrictContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterOrderList(MySQLParser::AlterOrderListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterAlgorithmOption(MySQLParser::AlterAlgorithmOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterLockOption(MySQLParser::AlterLockOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexLockAndAlgorithm(MySQLParser::IndexLockAndAlgorithmContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWithValidation(MySQLParser::WithValidationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRemovePartitioning(MySQLParser::RemovePartitioningContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAllOrPartitionNameList(MySQLParser::AllOrPartitionNameListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterTablespace(MySQLParser::AlterTablespaceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterUndoTablespace(MySQLParser::AlterUndoTablespaceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUndoTableSpaceOptions(MySQLParser::UndoTableSpaceOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUndoTableSpaceOption(MySQLParser::UndoTableSpaceOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterTablespaceOptions(MySQLParser::AlterTablespaceOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterTablespaceOption(MySQLParser::AlterTablespaceOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitChangeTablespaceOption(MySQLParser::ChangeTablespaceOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterView(MySQLParser::AlterViewContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewTail(MySQLParser::ViewTailContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewSelect(MySQLParser::ViewSelectContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewCheckOption(MySQLParser::ViewCheckOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateStatement(MySQLParser::CreateStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateDatabase(MySQLParser::CreateDatabaseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateDatabaseOption(MySQLParser::CreateDatabaseOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateTable(MySQLParser::CreateTableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableElementList(MySQLParser::TableElementListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableElement(MySQLParser::TableElementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDuplicateAsQueryExpression(MySQLParser::DuplicateAsQueryExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQueryExpressionOrParens(MySQLParser::QueryExpressionOrParensContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateRoutine(MySQLParser::CreateRoutineContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateProcedure(MySQLParser::CreateProcedureContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateFunction(MySQLParser::CreateFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateUdf(MySQLParser::CreateUdfContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoutineCreateOption(MySQLParser::RoutineCreateOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoutineAlterOptions(MySQLParser::RoutineAlterOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoutineOption(MySQLParser::RoutineOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateIndex(MySQLParser::CreateIndexContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexNameAndType(MySQLParser::IndexNameAndTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateIndexTarget(MySQLParser::CreateIndexTargetContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateLogfileGroup(MySQLParser::CreateLogfileGroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLogfileGroupOptions(MySQLParser::LogfileGroupOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLogfileGroupOption(MySQLParser::LogfileGroupOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateServer(MySQLParser::CreateServerContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitServerOptions(MySQLParser::ServerOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitServerOption(MySQLParser::ServerOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateTablespace(MySQLParser::CreateTablespaceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateUndoTablespace(MySQLParser::CreateUndoTablespaceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsDataFileName(MySQLParser::TsDataFileNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsDataFile(MySQLParser::TsDataFileContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTablespaceOptions(MySQLParser::TablespaceOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTablespaceOption(MySQLParser::TablespaceOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionInitialSize(MySQLParser::TsOptionInitialSizeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionUndoRedoBufferSize(MySQLParser::TsOptionUndoRedoBufferSizeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionAutoextendSize(MySQLParser::TsOptionAutoextendSizeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionMaxSize(MySQLParser::TsOptionMaxSizeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionExtentSize(MySQLParser::TsOptionExtentSizeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionNodegroup(MySQLParser::TsOptionNodegroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionEngine(MySQLParser::TsOptionEngineContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionWait(MySQLParser::TsOptionWaitContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionComment(MySQLParser::TsOptionCommentContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionFileblockSize(MySQLParser::TsOptionFileblockSizeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTsOptionEncryption(MySQLParser::TsOptionEncryptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateView(MySQLParser::CreateViewContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewReplaceOrAlgorithm(MySQLParser::ViewReplaceOrAlgorithmContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewAlgorithm(MySQLParser::ViewAlgorithmContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewSuid(MySQLParser::ViewSuidContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateTrigger(MySQLParser::CreateTriggerContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTriggerFollowsPrecedesClause(MySQLParser::TriggerFollowsPrecedesClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateEvent(MySQLParser::CreateEventContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateRole(MySQLParser::CreateRoleContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateSpatialReference(MySQLParser::CreateSpatialReferenceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSrsAttribute(MySQLParser::SrsAttributeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropStatement(MySQLParser::DropStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropDatabase(MySQLParser::DropDatabaseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropEvent(MySQLParser::DropEventContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropFunction(MySQLParser::DropFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropProcedure(MySQLParser::DropProcedureContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropIndex(MySQLParser::DropIndexContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropLogfileGroup(MySQLParser::DropLogfileGroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropLogfileGroupOption(MySQLParser::DropLogfileGroupOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropServer(MySQLParser::DropServerContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropTable(MySQLParser::DropTableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropTableSpace(MySQLParser::DropTableSpaceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropTrigger(MySQLParser::DropTriggerContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropView(MySQLParser::DropViewContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropRole(MySQLParser::DropRoleContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropSpatialReference(MySQLParser::DropSpatialReferenceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropUndoTablespace(MySQLParser::DropUndoTablespaceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRenameTableStatement(MySQLParser::RenameTableStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRenamePair(MySQLParser::RenamePairContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTruncateTableStatement(MySQLParser::TruncateTableStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitImportStatement(MySQLParser::ImportStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCallStatement(MySQLParser::CallStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDeleteStatement(MySQLParser::DeleteStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionDelete(MySQLParser::PartitionDeleteContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDeleteStatementOption(MySQLParser::DeleteStatementOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDoStatement(MySQLParser::DoStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitHandlerStatement(MySQLParser::HandlerStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitHandlerReadOrScan(MySQLParser::HandlerReadOrScanContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInsertStatement(MySQLParser::InsertStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInsertLockOption(MySQLParser::InsertLockOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInsertFromConstructor(MySQLParser::InsertFromConstructorContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFields(MySQLParser::FieldsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInsertValues(MySQLParser::InsertValuesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInsertQueryExpression(MySQLParser::InsertQueryExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitValueList(MySQLParser::ValueListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitValues(MySQLParser::ValuesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitValuesReference(MySQLParser::ValuesReferenceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInsertUpdateList(MySQLParser::InsertUpdateListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLoadStatement(MySQLParser::LoadStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDataOrXml(MySQLParser::DataOrXmlContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitXmlRowsIdentifiedBy(MySQLParser::XmlRowsIdentifiedByContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLoadDataFileTail(MySQLParser::LoadDataFileTailContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLoadDataFileTargetList(MySQLParser::LoadDataFileTargetListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFieldOrVariableList(MySQLParser::FieldOrVariableListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReplaceStatement(MySQLParser::ReplaceStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSelectStatement(MySQLParser::SelectStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSelectStatementWithInto(MySQLParser::SelectStatementWithIntoContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQueryExpression(MySQLParser::QueryExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQueryExpressionBody(MySQLParser::QueryExpressionBodyContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQueryExpressionParens(MySQLParser::QueryExpressionParensContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQueryPrimary(MySQLParser::QueryPrimaryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQuerySpecification(MySQLParser::QuerySpecificationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSubquery(MySQLParser::SubqueryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQuerySpecOption(MySQLParser::QuerySpecOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLimitClause(MySQLParser::LimitClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleLimitClause(MySQLParser::SimpleLimitClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLimitOptions(MySQLParser::LimitOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLimitOption(MySQLParser::LimitOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIntoClause(MySQLParser::IntoClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitProcedureAnalyseClause(MySQLParser::ProcedureAnalyseClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitHavingClause(MySQLParser::HavingClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowClause(MySQLParser::WindowClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowDefinition(MySQLParser::WindowDefinitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowSpec(MySQLParser::WindowSpecContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowSpecDetails(MySQLParser::WindowSpecDetailsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFrameClause(MySQLParser::WindowFrameClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFrameUnits(MySQLParser::WindowFrameUnitsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFrameExtent(MySQLParser::WindowFrameExtentContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFrameStart(MySQLParser::WindowFrameStartContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFrameBetween(MySQLParser::WindowFrameBetweenContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFrameBound(MySQLParser::WindowFrameBoundContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFrameExclusion(MySQLParser::WindowFrameExclusionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWithClause(MySQLParser::WithClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCommonTableExpression(MySQLParser::CommonTableExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGroupByClause(MySQLParser::GroupByClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOlapOption(MySQLParser::OlapOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOrderClause(MySQLParser::OrderClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDirection(MySQLParser::DirectionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFromClause(MySQLParser::FromClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableReferenceList(MySQLParser::TableReferenceListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableValueConstructor(MySQLParser::TableValueConstructorContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExplicitTable(MySQLParser::ExplicitTableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRowValueExplicit(MySQLParser::RowValueExplicitContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSelectOption(MySQLParser::SelectOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLockingClauseList(MySQLParser::LockingClauseListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLockingClause(MySQLParser::LockingClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLockStrengh(MySQLParser::LockStrenghContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLockedRowAction(MySQLParser::LockedRowActionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSelectItemList(MySQLParser::SelectItemListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSelectItem(MySQLParser::SelectItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSelectAlias(MySQLParser::SelectAliasContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWhereClause(MySQLParser::WhereClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableReference(MySQLParser::TableReferenceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitEscapedTableReference(MySQLParser::EscapedTableReferenceContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitJoinedTable(MySQLParser::JoinedTableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNaturalJoinType(MySQLParser::NaturalJoinTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInnerJoinType(MySQLParser::InnerJoinTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOuterJoinType(MySQLParser::OuterJoinTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableFactor(MySQLParser::TableFactorContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSingleTable(MySQLParser::SingleTableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSingleTableParens(MySQLParser::SingleTableParensContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDerivedTable(MySQLParser::DerivedTableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableReferenceListParens(MySQLParser::TableReferenceListParensContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableFunction(MySQLParser::TableFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnsClause(MySQLParser::ColumnsClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitJtColumn(MySQLParser::JtColumnContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOnEmptyOrError(MySQLParser::OnEmptyOrErrorContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOnEmpty(MySQLParser::OnEmptyContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOnError(MySQLParser::OnErrorContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitJtOnResponse(MySQLParser::JtOnResponseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUnionOption(MySQLParser::UnionOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableAlias(MySQLParser::TableAliasContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexHintList(MySQLParser::IndexHintListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexHint(MySQLParser::IndexHintContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexHintType(MySQLParser::IndexHintTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyOrIndex(MySQLParser::KeyOrIndexContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitConstraintKeyType(MySQLParser::ConstraintKeyTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexHintClause(MySQLParser::IndexHintClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexList(MySQLParser::IndexListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexListElement(MySQLParser::IndexListElementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUpdateStatement(MySQLParser::UpdateStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTransactionOrLockingStatement(MySQLParser::TransactionOrLockingStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTransactionStatement(MySQLParser::TransactionStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitBeginWork(MySQLParser::BeginWorkContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTransactionCharacteristic(MySQLParser::TransactionCharacteristicContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSavepointStatement(MySQLParser::SavepointStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLockStatement(MySQLParser::LockStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLockItem(MySQLParser::LockItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLockOption(MySQLParser::LockOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitXaStatement(MySQLParser::XaStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitXaConvert(MySQLParser::XaConvertContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitXid(MySQLParser::XidContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReplicationStatement(MySQLParser::ReplicationStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitResetOption(MySQLParser::ResetOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitMasterResetOptions(MySQLParser::MasterResetOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReplicationLoad(MySQLParser::ReplicationLoadContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitChangeMaster(MySQLParser::ChangeMasterContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitChangeMasterOptions(MySQLParser::ChangeMasterOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitMasterOption(MySQLParser::MasterOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPrivilegeCheckDef(MySQLParser::PrivilegeCheckDefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTablePrimaryKeyCheckDef(MySQLParser::TablePrimaryKeyCheckDefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitMasterTlsCiphersuitesDef(MySQLParser::MasterTlsCiphersuitesDefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitMasterFileDef(MySQLParser::MasterFileDefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitServerIdList(MySQLParser::ServerIdListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitChangeReplication(MySQLParser::ChangeReplicationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFilterDefinition(MySQLParser::FilterDefinitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFilterDbList(MySQLParser::FilterDbListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFilterTableList(MySQLParser::FilterTableListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFilterStringList(MySQLParser::FilterStringListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFilterWildDbTableString(MySQLParser::FilterWildDbTableStringContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFilterDbPairList(MySQLParser::FilterDbPairListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSlave(MySQLParser::SlaveContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSlaveUntilOptions(MySQLParser::SlaveUntilOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSlaveConnectionOptions(MySQLParser::SlaveConnectionOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSlaveThreadOptions(MySQLParser::SlaveThreadOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSlaveThreadOption(MySQLParser::SlaveThreadOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGroupReplication(MySQLParser::GroupReplicationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPreparedStatement(MySQLParser::PreparedStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExecuteStatement(MySQLParser::ExecuteStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExecuteVarList(MySQLParser::ExecuteVarListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCloneStatement(MySQLParser::CloneStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDataDirSSL(MySQLParser::DataDirSSLContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSsl(MySQLParser::SslContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAccountManagementStatement(MySQLParser::AccountManagementStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterUser(MySQLParser::AlterUserContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterUserTail(MySQLParser::AlterUserTailContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUserFunction(MySQLParser::UserFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateUser(MySQLParser::CreateUserContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateUserTail(MySQLParser::CreateUserTailContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDefaultRoleClause(MySQLParser::DefaultRoleClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRequireClause(MySQLParser::RequireClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitConnectOptions(MySQLParser::ConnectOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAccountLockPasswordExpireOptions(MySQLParser::AccountLockPasswordExpireOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropUser(MySQLParser::DropUserContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGrant(MySQLParser::GrantContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGrantTargetList(MySQLParser::GrantTargetListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGrantOptions(MySQLParser::GrantOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExceptRoleList(MySQLParser::ExceptRoleListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWithRoles(MySQLParser::WithRolesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGrantAs(MySQLParser::GrantAsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitVersionedRequireClause(MySQLParser::VersionedRequireClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRenameUser(MySQLParser::RenameUserContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRevoke(MySQLParser::RevokeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOnTypeTo(MySQLParser::OnTypeToContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAclType(MySQLParser::AclTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleOrPrivilegesList(MySQLParser::RoleOrPrivilegesListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleOrPrivilege(MySQLParser::RoleOrPrivilegeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGrantIdentifier(MySQLParser::GrantIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRequireList(MySQLParser::RequireListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRequireListElement(MySQLParser::RequireListElementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGrantOption(MySQLParser::GrantOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSetRole(MySQLParser::SetRoleContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleList(MySQLParser::RoleListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRole(MySQLParser::RoleContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableAdministrationStatement(MySQLParser::TableAdministrationStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitHistogram(MySQLParser::HistogramContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCheckOption(MySQLParser::CheckOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRepairType(MySQLParser::RepairTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInstallUninstallStatment(MySQLParser::InstallUninstallStatmentContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSetStatement(MySQLParser::SetStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitStartOptionValueList(MySQLParser::StartOptionValueListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTransactionCharacteristics(MySQLParser::TransactionCharacteristicsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTransactionAccessMode(MySQLParser::TransactionAccessModeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIsolationLevel(MySQLParser::IsolationLevelContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOptionValueListContinued(MySQLParser::OptionValueListContinuedContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOptionValueNoOptionType(MySQLParser::OptionValueNoOptionTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOptionValue(MySQLParser::OptionValueContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSetSystemVariable(MySQLParser::SetSystemVariableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitStartOptionValueListFollowingOptionType(MySQLParser::StartOptionValueListFollowingOptionTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOptionValueFollowingOptionType(MySQLParser::OptionValueFollowingOptionTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSetExprOrDefault(MySQLParser::SetExprOrDefaultContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitShowStatement(MySQLParser::ShowStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitShowCommandType(MySQLParser::ShowCommandTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNonBlocking(MySQLParser::NonBlockingContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFromOrIn(MySQLParser::FromOrInContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInDb(MySQLParser::InDbContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitProfileType(MySQLParser::ProfileTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOtherAdministrativeStatement(MySQLParser::OtherAdministrativeStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyCacheListOrParts(MySQLParser::KeyCacheListOrPartsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyCacheList(MySQLParser::KeyCacheListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAssignToKeycache(MySQLParser::AssignToKeycacheContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAssignToKeycachePartition(MySQLParser::AssignToKeycachePartitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCacheKeyList(MySQLParser::CacheKeyListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyUsageElement(MySQLParser::KeyUsageElementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyUsageList(MySQLParser::KeyUsageListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFlushOption(MySQLParser::FlushOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLogType(MySQLParser::LogTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFlushTables(MySQLParser::FlushTablesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFlushTablesOptions(MySQLParser::FlushTablesOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPreloadTail(MySQLParser::PreloadTailContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPreloadList(MySQLParser::PreloadListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPreloadKeys(MySQLParser::PreloadKeysContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAdminPartition(MySQLParser::AdminPartitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitResourceGroupManagement(MySQLParser::ResourceGroupManagementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateResourceGroup(MySQLParser::CreateResourceGroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitResourceGroupVcpuList(MySQLParser::ResourceGroupVcpuListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitVcpuNumOrRange(MySQLParser::VcpuNumOrRangeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitResourceGroupPriority(MySQLParser::ResourceGroupPriorityContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitResourceGroupEnableDisable(MySQLParser::ResourceGroupEnableDisableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterResourceGroup(MySQLParser::AlterResourceGroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSetResourceGroup(MySQLParser::SetResourceGroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitThreadIdList(MySQLParser::ThreadIdListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDropResourceGroup(MySQLParser::DropResourceGroupContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUtilityStatement(MySQLParser::UtilityStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDescribeStatement(MySQLParser::DescribeStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExplainStatement(MySQLParser::ExplainStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExplainableStatement(MySQLParser::ExplainableStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitHelpCommand(MySQLParser::HelpCommandContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUseCommand(MySQLParser::UseCommandContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRestartServer(MySQLParser::RestartServerContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprOr(MySQLParser::ExprOrContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprNot(MySQLParser::ExprNotContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprIs(MySQLParser::ExprIsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprAnd(MySQLParser::ExprAndContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprXor(MySQLParser::ExprXorContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPrimaryExprPredicate(MySQLParser::PrimaryExprPredicateContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPrimaryExprCompare(MySQLParser::PrimaryExprCompareContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPrimaryExprAllAny(MySQLParser::PrimaryExprAllAnyContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPrimaryExprIsNull(MySQLParser::PrimaryExprIsNullContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCompOp(MySQLParser::CompOpContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPredicate(MySQLParser::PredicateContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPredicateExprIn(MySQLParser::PredicateExprInContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPredicateExprBetween(MySQLParser::PredicateExprBetweenContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPredicateExprLike(MySQLParser::PredicateExprLikeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPredicateExprRegex(MySQLParser::PredicateExprRegexContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitBitExpr(MySQLParser::BitExprContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprConvert(MySQLParser::SimpleExprConvertContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprVariable(MySQLParser::SimpleExprVariableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprCast(MySQLParser::SimpleExprCastContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprUnary(MySQLParser::SimpleExprUnaryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprOdbc(MySQLParser::SimpleExprOdbcContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprRuntimeFunction(MySQLParser::SimpleExprRuntimeFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprFunction(MySQLParser::SimpleExprFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprCollate(MySQLParser::SimpleExprCollateContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprMatch(MySQLParser::SimpleExprMatchContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprWindowingFunction(MySQLParser::SimpleExprWindowingFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprBinary(MySQLParser::SimpleExprBinaryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprColumnRef(MySQLParser::SimpleExprColumnRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprParamMarker(MySQLParser::SimpleExprParamMarkerContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprSum(MySQLParser::SimpleExprSumContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprConvertUsing(MySQLParser::SimpleExprConvertUsingContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprSubQuery(MySQLParser::SimpleExprSubQueryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprGroupingOperation(MySQLParser::SimpleExprGroupingOperationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprNot(MySQLParser::SimpleExprNotContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprValues(MySQLParser::SimpleExprValuesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprDefault(MySQLParser::SimpleExprDefaultContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprList(MySQLParser::SimpleExprListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprInterval(MySQLParser::SimpleExprIntervalContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprCase(MySQLParser::SimpleExprCaseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprConcat(MySQLParser::SimpleExprConcatContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprLiteral(MySQLParser::SimpleExprLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitArrayCast(MySQLParser::ArrayCastContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitJsonOperator(MySQLParser::JsonOperatorContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSumExpr(MySQLParser::SumExprContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGroupingOperation(MySQLParser::GroupingOperationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowFunctionCall(MySQLParser::WindowFunctionCallContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowingClause(MySQLParser::WindowingClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLeadLagInfo(MySQLParser::LeadLagInfoContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNullTreatment(MySQLParser::NullTreatmentContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitJsonFunction(MySQLParser::JsonFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInSumExpr(MySQLParser::InSumExprContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentListArg(MySQLParser::IdentListArgContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentList(MySQLParser::IdentListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFulltextOptions(MySQLParser::FulltextOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRuntimeFunctionCall(MySQLParser::RuntimeFunctionCallContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGeometryFunction(MySQLParser::GeometryFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTimeFunctionParameters(MySQLParser::TimeFunctionParametersContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFractionalPrecision(MySQLParser::FractionalPrecisionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWeightStringLevels(MySQLParser::WeightStringLevelsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWeightStringLevelListItem(MySQLParser::WeightStringLevelListItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDateTimeTtype(MySQLParser::DateTimeTtypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTrimFunction(MySQLParser::TrimFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSubstringFunction(MySQLParser::SubstringFunctionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFunctionCall(MySQLParser::FunctionCallContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUdfExprList(MySQLParser::UdfExprListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUdfExpr(MySQLParser::UdfExprContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitVariable(MySQLParser::VariableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUserVariable(MySQLParser::UserVariableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSystemVariable(MySQLParser::SystemVariableContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInternalVariableName(MySQLParser::InternalVariableNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWhenExpression(MySQLParser::WhenExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitThenExpression(MySQLParser::ThenExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitElseExpression(MySQLParser::ElseExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCastType(MySQLParser::CastTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprList(MySQLParser::ExprListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCharset(MySQLParser::CharsetContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNotRule(MySQLParser::NotRuleContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNot2Rule(MySQLParser::Not2RuleContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInterval(MySQLParser::IntervalContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIntervalTimeStamp(MySQLParser::IntervalTimeStampContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprListWithParentheses(MySQLParser::ExprListWithParenthesesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitExprWithParentheses(MySQLParser::ExprWithParenthesesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleExprWithParentheses(MySQLParser::SimpleExprWithParenthesesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOrderList(MySQLParser::OrderListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOrderExpression(MySQLParser::OrderExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGroupList(MySQLParser::GroupListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGroupingExpression(MySQLParser::GroupingExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitChannel(MySQLParser::ChannelContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCompoundStatement(MySQLParser::CompoundStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReturnStatement(MySQLParser::ReturnStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIfStatement(MySQLParser::IfStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIfBody(MySQLParser::IfBodyContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitThenStatement(MySQLParser::ThenStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCompoundStatementList(MySQLParser::CompoundStatementListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCaseStatement(MySQLParser::CaseStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitElseStatement(MySQLParser::ElseStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLabeledBlock(MySQLParser::LabeledBlockContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUnlabeledBlock(MySQLParser::UnlabeledBlockContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLabel(MySQLParser::LabelContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitBeginEndBlock(MySQLParser::BeginEndBlockContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLabeledControl(MySQLParser::LabeledControlContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUnlabeledControl(MySQLParser::UnlabeledControlContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLoopBlock(MySQLParser::LoopBlockContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWhileDoBlock(MySQLParser::WhileDoBlockContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRepeatUntilBlock(MySQLParser::RepeatUntilBlockContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSpDeclarations(MySQLParser::SpDeclarationsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSpDeclaration(MySQLParser::SpDeclarationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitVariableDeclaration(MySQLParser::VariableDeclarationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitConditionDeclaration(MySQLParser::ConditionDeclarationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSpCondition(MySQLParser::SpConditionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSqlstate(MySQLParser::SqlstateContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitHandlerDeclaration(MySQLParser::HandlerDeclarationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitHandlerCondition(MySQLParser::HandlerConditionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCursorDeclaration(MySQLParser::CursorDeclarationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIterateStatement(MySQLParser::IterateStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLeaveStatement(MySQLParser::LeaveStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGetDiagnostics(MySQLParser::GetDiagnosticsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSignalAllowedExpr(MySQLParser::SignalAllowedExprContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitStatementInformationItem(MySQLParser::StatementInformationItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitConditionInformationItem(MySQLParser::ConditionInformationItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSignalInformationItemName(MySQLParser::SignalInformationItemNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSignalStatement(MySQLParser::SignalStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitResignalStatement(MySQLParser::ResignalStatementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSignalInformationItem(MySQLParser::SignalInformationItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCursorOpen(MySQLParser::CursorOpenContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCursorClose(MySQLParser::CursorCloseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCursorFetch(MySQLParser::CursorFetchContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSchedule(MySQLParser::ScheduleContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnDefinition(MySQLParser::ColumnDefinitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCheckOrReferences(MySQLParser::CheckOrReferencesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCheckConstraint(MySQLParser::CheckConstraintContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitConstraintEnforcement(MySQLParser::ConstraintEnforcementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableConstraintDef(MySQLParser::TableConstraintDefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitConstraintName(MySQLParser::ConstraintNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFieldDefinition(MySQLParser::FieldDefinitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnAttribute(MySQLParser::ColumnAttributeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnFormat(MySQLParser::ColumnFormatContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitStorageMedia(MySQLParser::StorageMediaContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitGcolAttribute(MySQLParser::GcolAttributeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReferences(MySQLParser::ReferencesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDeleteOption(MySQLParser::DeleteOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyList(MySQLParser::KeyListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyPart(MySQLParser::KeyPartContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyListWithExpression(MySQLParser::KeyListWithExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyPartOrExpression(MySQLParser::KeyPartOrExpressionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitKeyListVariants(MySQLParser::KeyListVariantsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexType(MySQLParser::IndexTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexOption(MySQLParser::IndexOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCommonIndexOption(MySQLParser::CommonIndexOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitVisibility(MySQLParser::VisibilityContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexTypeClause(MySQLParser::IndexTypeClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFulltextIndexOption(MySQLParser::FulltextIndexOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSpatialIndexOption(MySQLParser::SpatialIndexOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDataTypeDefinition(MySQLParser::DataTypeDefinitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDataType(MySQLParser::DataTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNchar(MySQLParser::NcharContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRealType(MySQLParser::RealTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFieldLength(MySQLParser::FieldLengthContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFieldOptions(MySQLParser::FieldOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCharsetWithOptBinary(MySQLParser::CharsetWithOptBinaryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAscii(MySQLParser::AsciiContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUnicode(MySQLParser::UnicodeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWsNumCodepoints(MySQLParser::WsNumCodepointsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTypeDatetimePrecision(MySQLParser::TypeDatetimePrecisionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCharsetName(MySQLParser::CharsetNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCollationName(MySQLParser::CollationNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateTableOptions(MySQLParser::CreateTableOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateTableOptionsSpaceSeparated(MySQLParser::CreateTableOptionsSpaceSeparatedContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateTableOption(MySQLParser::CreateTableOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTernaryOption(MySQLParser::TernaryOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDefaultCollation(MySQLParser::DefaultCollationContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDefaultEncryption(MySQLParser::DefaultEncryptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDefaultCharset(MySQLParser::DefaultCharsetContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionClause(MySQLParser::PartitionClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionDefKey(MySQLParser::PartitionDefKeyContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionDefHash(MySQLParser::PartitionDefHashContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionDefRangeList(MySQLParser::PartitionDefRangeListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSubPartitions(MySQLParser::SubPartitionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionKeyAlgorithm(MySQLParser::PartitionKeyAlgorithmContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionDefinitions(MySQLParser::PartitionDefinitionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionDefinition(MySQLParser::PartitionDefinitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionValuesIn(MySQLParser::PartitionValuesInContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionOption(MySQLParser::PartitionOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSubpartitionDefinition(MySQLParser::SubpartitionDefinitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionValueItemListParen(MySQLParser::PartitionValueItemListParenContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPartitionValueItem(MySQLParser::PartitionValueItemContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDefinerClause(MySQLParser::DefinerClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIfExists(MySQLParser::IfExistsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIfNotExists(MySQLParser::IfNotExistsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitProcedureParameter(MySQLParser::ProcedureParameterContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFunctionParameter(MySQLParser::FunctionParameterContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCollate(MySQLParser::CollateContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTypeWithOptCollate(MySQLParser::TypeWithOptCollateContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSchemaIdentifierPair(MySQLParser::SchemaIdentifierPairContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewRefList(MySQLParser::ViewRefListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUpdateList(MySQLParser::UpdateListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUpdateElement(MySQLParser::UpdateElementContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCharsetClause(MySQLParser::CharsetClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFieldsClause(MySQLParser::FieldsClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFieldTerm(MySQLParser::FieldTermContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLinesClause(MySQLParser::LinesClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLineTerm(MySQLParser::LineTermContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUserList(MySQLParser::UserListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateUserList(MySQLParser::CreateUserListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterUserList(MySQLParser::AlterUserListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitCreateUserEntry(MySQLParser::CreateUserEntryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitAlterUserEntry(MySQLParser::AlterUserEntryContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRetainCurrentPassword(MySQLParser::RetainCurrentPasswordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDiscardOldPassword(MySQLParser::DiscardOldPasswordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReplacePassword(MySQLParser::ReplacePasswordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUserIdentifierOrText(MySQLParser::UserIdentifierOrTextContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUser(MySQLParser::UserContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLikeClause(MySQLParser::LikeClauseContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLikeOrWhere(MySQLParser::LikeOrWhereContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOnlineOption(MySQLParser::OnlineOptionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNoWriteToBinLog(MySQLParser::NoWriteToBinLogContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUsePartition(MySQLParser::UsePartitionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFieldIdentifier(MySQLParser::FieldIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnName(MySQLParser::ColumnNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnInternalRef(MySQLParser::ColumnInternalRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnInternalRefList(MySQLParser::ColumnInternalRefListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitColumnRef(MySQLParser::ColumnRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitInsertIdentifier(MySQLParser::InsertIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexName(MySQLParser::IndexNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIndexRef(MySQLParser::IndexRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableWild(MySQLParser::TableWildContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSchemaName(MySQLParser::SchemaNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSchemaRef(MySQLParser::SchemaRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitProcedureName(MySQLParser::ProcedureNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitProcedureRef(MySQLParser::ProcedureRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFunctionName(MySQLParser::FunctionNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFunctionRef(MySQLParser::FunctionRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTriggerName(MySQLParser::TriggerNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTriggerRef(MySQLParser::TriggerRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewName(MySQLParser::ViewNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitViewRef(MySQLParser::ViewRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTablespaceName(MySQLParser::TablespaceNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTablespaceRef(MySQLParser::TablespaceRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLogfileGroupName(MySQLParser::LogfileGroupNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLogfileGroupRef(MySQLParser::LogfileGroupRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitEventName(MySQLParser::EventNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitEventRef(MySQLParser::EventRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUdfName(MySQLParser::UdfNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitServerName(MySQLParser::ServerNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitServerRef(MySQLParser::ServerRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitEngineRef(MySQLParser::EngineRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableName(MySQLParser::TableNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFilterTableRef(MySQLParser::FilterTableRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableRefWithWildcard(MySQLParser::TableRefWithWildcardContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableRef(MySQLParser::TableRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableRefList(MySQLParser::TableRefListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTableAliasRefList(MySQLParser::TableAliasRefListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitParameterName(MySQLParser::ParameterNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLabelIdentifier(MySQLParser::LabelIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLabelRef(MySQLParser::LabelRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleIdentifier(MySQLParser::RoleIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleRef(MySQLParser::RoleRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPluginRef(MySQLParser::PluginRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitComponentRef(MySQLParser::ComponentRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitResourceGroupRef(MySQLParser::ResourceGroupRefContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitWindowName(MySQLParser::WindowNameContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPureIdentifier(MySQLParser::PureIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifier(MySQLParser::IdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierList(MySQLParser::IdentifierListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierListWithParentheses(MySQLParser::IdentifierListWithParenthesesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitQualifiedIdentifier(MySQLParser::QualifiedIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSimpleIdentifier(MySQLParser::SimpleIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitDotIdentifier(MySQLParser::DotIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUlong_number(MySQLParser::Ulong_numberContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReal_ulong_number(MySQLParser::Real_ulong_numberContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitUlonglong_number(MySQLParser::Ulonglong_numberContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitReal_ulonglong_number(MySQLParser::Real_ulonglong_numberContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLiteral(MySQLParser::LiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSignedLiteral(MySQLParser::SignedLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitStringList(MySQLParser::StringListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTextStringLiteral(MySQLParser::TextStringLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTextString(MySQLParser::TextStringContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTextStringHash(MySQLParser::TextStringHashContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTextLiteral(MySQLParser::TextLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTextStringNoLinebreak(MySQLParser::TextStringNoLinebreakContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTextStringLiteralList(MySQLParser::TextStringLiteralListContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNumLiteral(MySQLParser::NumLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitBoolLiteral(MySQLParser::BoolLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitNullLiteral(MySQLParser::NullLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTemporalLiteral(MySQLParser::TemporalLiteralContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitFloatOptions(MySQLParser::FloatOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitStandardFloatOptions(MySQLParser::StandardFloatOptionsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitPrecision(MySQLParser::PrecisionContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitTextOrIdentifier(MySQLParser::TextOrIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLValueIdentifier(MySQLParser::LValueIdentifierContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleIdentifierOrText(MySQLParser::RoleIdentifierOrTextContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSizeNumber(MySQLParser::SizeNumberContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitParentheses(MySQLParser::ParenthesesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitEqual(MySQLParser::EqualContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitOptionType(MySQLParser::OptionTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitVarIdentType(MySQLParser::VarIdentTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitSetVarIdentType(MySQLParser::SetVarIdentTypeContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierKeyword(MySQLParser::IdentifierKeywordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierKeywordsAmbiguous1RolesAndLabels(MySQLParser::IdentifierKeywordsAmbiguous1RolesAndLabelsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierKeywordsAmbiguous2Labels(MySQLParser::IdentifierKeywordsAmbiguous2LabelsContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLabelKeyword(MySQLParser::LabelKeywordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierKeywordsAmbiguous3Roles(MySQLParser::IdentifierKeywordsAmbiguous3RolesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierKeywordsUnambiguous(MySQLParser::IdentifierKeywordsUnambiguousContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleKeyword(MySQLParser::RoleKeywordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitLValueKeyword(MySQLParser::LValueKeywordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitIdentifierKeywordsAmbiguous4SystemVariables(MySQLParser::IdentifierKeywordsAmbiguous4SystemVariablesContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleOrIdentifierKeyword(MySQLParser::RoleOrIdentifierKeywordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }
  virtual std::any visitRoleOrLabelKeyword(MySQLParser::RoleOrLabelKeywordContext *ctx) override {
    if (ctx->parent == NULL) {
      // ROOT
      visitChildren(ctx);
      return 0;
    } else {
      // Child node.
      unsigned int cur_idx = hash_array[ctx->getRuleIndex()];
      unsigned int parent_idx = hash_array[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()];
#ifdef DEBUG
      cerr << "Parent rule: " << p_parser->getRuleNames()[dynamic_cast<antlr4::ParserRuleContext*>(ctx->parent)->getRuleIndex()] << "\n";
      cerr << "Current rule: " << p_parser->getRuleNames()[ctx->getRuleIndex()] << "\n";
      cerr << "branch hash: " << ((parent_idx >> 1) ^ cur_idx) << "\n\n\n";
#endif
      this->gram_cov.log_edge_cov_map(parent_idx, cur_idx);
      visitChildren(ctx);
      return 0;
    }
  }

};

#endif
