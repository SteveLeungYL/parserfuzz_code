//
// Created by Yu Liang on 11/17/23.
//

#ifndef SRC_GRAM_COV_H
#define SRC_GRAM_COV_H

#include "../AFL/config.h"
#include <iostream>
#include <fstream>
#include <string>
#include <set>
#include <filesystem>
#include <algorithm>
#include <cstring>

using namespace std;

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

    vector<unsigned long long> cur_path_hash_vec;
    set<unsigned long long> path_hash_set;

    u8 has_new_grammar_bits(bool is_debug = false, const string in = "") {
//    has_new_grammar_bits(this->block_cov_map, this->block_virgin_map, is_debug);
        return has_new_grammar_bits(this->edge_cov_map, this->edge_virgin_map, is_debug, in);
    }
    u8 has_new_grammar_bits(u8 *, u8 *, bool is_debug = false, const string in = "");

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
        this->log_grammar_path(cur_cov);
        return;
    }

    inline void log_grammar_path(unsigned int cur_cov) {
        if(std::find(this->cur_path_hash_vec.begin(), cur_path_hash_vec.end(), cur_cov) == cur_path_hash_vec.end()) {
            this->cur_path_hash_vec.push_back(cur_cov);
        }
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
    inline u64 get_total_path_cov_size_num() {
        return this->path_hash_set.size();
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
    u32 count_non_255_bytes(u8 *mem);

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

        if (!std::filesystem::exists("./gram_cov.txt")) {
            gram_id_out.open("./gram_cov.txt", std::fstream::out |
                                               std::fstream::trunc);
        } else {
            gram_id_out.open("./gram_cov.txt", std::fstream::out |
                                               std::fstream::app);
        }
        gram_id_out << actual_idx << endl;
        gram_id_out.flush();
        gram_id_out.close();

        if (!std::filesystem::exists("./new_gram_file/")) {
            std::filesystem::create_directory("./new_gram_file/");
        }
        fstream map_id_seed_output;
        map_id_seed_output.open(
                "./new_gram_file/" + to_string(actual_idx) + ".txt",
                std::fstream::out | std::fstream::trunc);
        map_id_seed_output << in;
        map_id_seed_output.close();

    }
};

#endif //SRC_GRAM_COV_H
