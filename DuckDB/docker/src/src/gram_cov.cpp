//
// Created by Yu Liang on 11/17/23.
//

#include "../include/gram_cov.hpp"

u8 GramCovMap::has_new_grammar_bits(u8 *cur_cov_map, u8 *cur_virgin_map,
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

/* Count the number of non-255 bytes set in the bitmap. Used strictly for the
   status screen, several calls per second or so. */
// Copy from afl-fuzz.cpp
u32 GramCovMap::count_non_255_bytes(u8 *mem) {

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