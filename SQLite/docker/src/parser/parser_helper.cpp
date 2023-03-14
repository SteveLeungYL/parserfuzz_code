//
// Created by Yu Liang on 3/13/23.
//

#include <cassert>
#include "parser_helper.h"
#include "sqlite_lemon_parser.h"

/* Character classes for tokenizing
**
** In the sqlite3GetToken() function, a switch() on aiClass[c] is implemented
** using a lookup table, whereas a switch() directly on c uses a binary search.
** The lookup table is much faster.  To maximize speed, and to ensure that
** a lookup table is used, all of the classes need to be small integers and
** all of them need to be used within the switch.
*/
#define CC_X          0    /* The letter 'x', or start of BLOB literal */
#define CC_KYWD0      1    /* First letter of a keyword */
#define CC_KYWD       2    /* Alphabetics or '_'.  Usable in a keyword */
#define CC_DIGIT      3    /* Digits */
#define CC_DOLLAR     4    /* '$' */
#define CC_VARALPHA   5    /* '@', '#', ':'.  Alphabetic SQL variables */
#define CC_VARNUM     6    /* '?'.  Numeric SQL variables */
#define CC_SPACE      7    /* Space characters */
#define CC_QUOTE      8    /* '"', '\'', or '`'.  String literals, quoted ids */
#define CC_QUOTE2     9    /* '['.   [...] style quoted ids */
#define CC_PIPE      10    /* '|'.   Bitwise OR or concatenate */
#define CC_MINUS     11    /* '-'.  Minus or SQL-style comment */
#define CC_LT        12    /* '<'.  Part of < or <= or <> */
#define CC_GT        13    /* '>'.  Part of > or >= */
#define CC_EQ        14    /* '='.  Part of = or == */
#define CC_BANG      15    /* '!'.  Part of != */
#define CC_SLASH     16    /* '/'.  / or c-style comment */
#define CC_LP        17    /* '(' */
#define CC_RP        18    /* ')' */
#define CC_SEMI      19    /* ';' */
#define CC_PLUS      20    /* '+' */
#define CC_STAR      21    /* '*' */
#define CC_PERCENT   22    /* '%' */
#define CC_COMMA     23    /* ',' */
#define CC_AND       24    /* '&' */
#define CC_TILDA     25    /* '~' */
#define CC_DOT       26    /* '.' */
#define CC_ID        27    /* unicode characters usable in IDs */
#define CC_ILLEGAL   28    /* Illegal character */
#define CC_NUL       29    /* 0x00 */
#define CC_BOM       30    /* First byte of UTF8 BOM:  0xEF 0xBB 0xBF */

# define sqlite3Toupper(x)  ((x)&~(sqlite3CtypeMap[(unsigned char)(x)]&0x20))
# define sqlite3Isspace(x)   (sqlite3CtypeMap[(unsigned char)(x)]&0x01)
# define sqlite3Isalnum(x)   (sqlite3CtypeMap[(unsigned char)(x)]&0x06)
# define sqlite3Isalpha(x)   (sqlite3CtypeMap[(unsigned char)(x)]&0x02)
# define sqlite3Isdigit(x)   (sqlite3CtypeMap[(unsigned char)(x)]&0x04)
# define sqlite3Isxdigit(x)  (sqlite3CtypeMap[(unsigned char)(x)]&0x08)
# define sqlite3Tolower(x)   (sqlite3UpperToLower[(unsigned char)(x)])
# define sqlite3Isquote(x)   (sqlite3CtypeMap[(unsigned char)(x)]&0x80)
# define IdChar(C)  ((sqlite3CtypeMap[(unsigned char)C]&0x46)!=0)
# define charMap(X) sqlite3UpperToLower[(unsigned char)X]

static const unsigned char sqlite3UpperToLower[] = {
    0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53,
    54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99,100,101,102,103,
    104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,
    122, 91, 92, 93, 94, 95, 96, 97, 98, 99,100,101,102,103,104,105,106,107,
    108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,
    126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,
    144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,
    162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,
    180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,
    198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,
    216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,
    234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,
    252,253,254,255
};

/* aKWHash[i] is the hash value for the i-th keyword */
static const unsigned char aKWHash[127] = {
    84,  92, 134,  82, 105,  29,   0,   0,  94,   0,  85,  72,   0,
    53,  35,  86,  15,   0,  42,  97,  54,  89, 135,  19,   0,   0,
    140,   0,  40, 129,   0,  22, 107,   0,   9,   0,   0, 123,  80,
    0,  78,   6,   0,  65, 103, 147,   0, 136, 115,   0,   0,  48,
    0,  90,  24,   0,  17,   0,  27,  70,  23,  26,   5,  60, 142,
    110, 122,   0,  73,  91,  71, 145,  61, 120,  74,   0,  49,   0,
    11,  41,   0, 113,   0,   0,   0, 109,  10, 111, 116, 125,  14,
    50, 124,   0, 100,   0,  18, 121, 144,  56, 130, 139,  88,  83,
    37,  30, 126,   0,   0, 108,  51, 131, 128,   0,  34,   0,   0,
    132,   0,  98,  38,  39,   0,  20,  45, 117,  93,
};

const unsigned char sqlite3CtypeMap[256] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  /* 00..07    ........ */
    0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00,  /* 08..0f    ........ */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  /* 10..17    ........ */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  /* 18..1f    ........ */
    0x01, 0x00, 0x80, 0x00, 0x40, 0x00, 0x00, 0x80,  /* 20..27     !"#$%&' */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  /* 28..2f    ()*+,-./ */
    0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c,  /* 30..37    01234567 */
    0x0c, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  /* 38..3f    89:;<=>? */

    0x00, 0x0a, 0x0a, 0x0a, 0x0a, 0x0a, 0x0a, 0x02,  /* 40..47    @ABCDEFG */
    0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02,  /* 48..4f    HIJKLMNO */
    0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02,  /* 50..57    PQRSTUVW */
    0x02, 0x02, 0x02, 0x80, 0x00, 0x00, 0x00, 0x40,  /* 58..5f    XYZ[\]^_ */
    0x80, 0x2a, 0x2a, 0x2a, 0x2a, 0x2a, 0x2a, 0x22,  /* 60..67    `abcdefg */
    0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22,  /* 68..6f    hijklmno */
    0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22,  /* 70..77    pqrstuvw */
    0x22, 0x22, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00,  /* 78..7f    xyz{|}~. */

    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* 80..87    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* 88..8f    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* 90..97    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* 98..9f    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* a0..a7    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* a8..af    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* b0..b7    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* b8..bf    ........ */

    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* c0..c7    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* c8..cf    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* d0..d7    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* d8..df    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* e0..e7    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* e8..ef    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,  /* f0..f7    ........ */
    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40   /* f8..ff    ........ */
};


static const unsigned char aiClass[] = {
    /*         x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xa  xb  xc  xd  xe  xf */
    /* 0x */   29, 28, 28, 28, 28, 28, 28, 28, 28,  7,  7, 28,  7,  7, 28, 28,
    /* 1x */   28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    /* 2x */    7, 15,  8,  5,  4, 22, 24,  8, 17, 18, 21, 20, 23, 11, 26, 16,
    /* 3x */    3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  5, 19, 12, 14, 13,  6,
    /* 4x */    5,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
    /* 5x */    1,  1,  1,  1,  1,  1,  1,  1,  0,  2,  2,  9, 28, 28, 28,  2,
    /* 6x */    8,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
    /* 7x */    1,  1,  1,  1,  1,  1,  1,  1,  0,  2,  2, 28, 10, 28, 25, 28,
    /* 8x */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    /* 9x */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    /* Ax */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    /* Bx */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    /* Cx */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    /* Dx */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    /* Ex */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 30,
    /* Fx */   27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27
};

/* aKWNext[] forms the hash collision chain.  If aKWHash[i]==0
** then the i-th keyword has no more hash collisions.  Otherwise,
** the next keyword with the same hash is aKWHash[i]-1. */
static const unsigned char aKWNext[147] = {
    0,   0,   0,   0,   4,   0,  43,   0,   0, 106, 114,   0,   0,
    0,   2,   0,   0, 143,   0,   0,   0,  13,   0,   0,   0,   0,
    141,   0,   0, 119,  52,   0,   0, 137,  12,   0,   0,  62,   0,
    138,   0, 133,   0,   0,  36,   0,   0,  28,  77,   0,   0,   0,
    0,  59,   0,  47,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,  69,   0,   0,   0,   0,   0, 146,   3,   0,  58,   0,   1,
    75,   0,   0,   0,  31,   0,   0,   0,   0,   0, 127,   0, 104,
    0,  64,  66,  63,   0,   0,   0,   0,   0,  46,   0,  16,   8,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  81, 101,   0,
    112,  21,   7,  67,   0,  79,  96, 118,   0,   0,  68,   0,   0,
    99,  44,   0,  55,   0,  76,   0,  95,  32,  33,  57,  25,   0,
    102,   0,   0,  87,
};
/* aKWLen[i] is the length (in bytes) of the i-th keyword */
static const unsigned char aKWLen[147] = {
    7,   7,   5,   4,   6,   4,   5,   3,   6,   7,   3,   6,   6,
    7,   7,   3,   8,   2,   6,   5,   4,   4,   3,  10,   4,   7,
    6,   9,   4,   2,   6,   5,   9,   9,   4,   7,   3,   2,   4,
    4,   6,  11,   6,   2,   7,   5,   5,   9,   6,  10,   4,   6,
    2,   3,   7,   5,   9,   6,   6,   4,   5,   5,  10,   6,   5,
    7,   4,   5,   7,   6,   7,   7,   6,   5,   7,   3,   7,   4,
    7,   6,  12,   9,   4,   6,   5,   4,   7,   6,  12,   8,   8,
    2,   6,   6,   7,   6,   4,   5,   9,   5,   5,   6,   3,   4,
    9,  13,   2,   2,   4,   6,   6,   8,   5,  17,  12,   7,   9,
    4,   4,   6,   7,   5,   9,   4,   4,   5,   2,   5,   8,   6,
    4,   9,   5,   8,   4,   3,   9,   5,   5,   6,   4,   6,   2,
    2,   9,   3,   7,
};

static const char zKWText[666] = {
    'R','E','I','N','D','E','X','E','D','E','S','C','A','P','E','A','C','H',
    'E','C','K','E','Y','B','E','F','O','R','E','I','G','N','O','R','E','G',
    'E','X','P','L','A','I','N','S','T','E','A','D','D','A','T','A','B','A',
    'S','E','L','E','C','T','A','B','L','E','F','T','H','E','N','D','E','F',
    'E','R','R','A','B','L','E','L','S','E','X','C','L','U','D','E','L','E',
    'T','E','M','P','O','R','A','R','Y','I','S','N','U','L','L','S','A','V',
    'E','P','O','I','N','T','E','R','S','E','C','T','I','E','S','N','O','T',
    'N','U','L','L','I','K','E','X','C','E','P','T','R','A','N','S','A','C',
    'T','I','O','N','A','T','U','R','A','L','T','E','R','A','I','S','E','X',
    'C','L','U','S','I','V','E','X','I','S','T','S','C','O','N','S','T','R',
    'A','I','N','T','O','F','F','S','E','T','R','I','G','G','E','R','A','N',
    'G','E','N','E','R','A','T','E','D','E','T','A','C','H','A','V','I','N',
    'G','L','O','B','E','G','I','N','N','E','R','E','F','E','R','E','N','C',
    'E','S','U','N','I','Q','U','E','R','Y','W','I','T','H','O','U','T','E',
    'R','E','L','E','A','S','E','A','T','T','A','C','H','B','E','T','W','E',
    'E','N','O','T','H','I','N','G','R','O','U','P','S','C','A','S','C','A',
    'D','E','F','A','U','L','T','C','A','S','E','C','O','L','L','A','T','E',
    'C','R','E','A','T','E','C','U','R','R','E','N','T','_','D','A','T','E',
    'I','M','M','E','D','I','A','T','E','J','O','I','N','S','E','R','T','M',
    'A','T','C','H','P','L','A','N','A','L','Y','Z','E','P','R','A','G','M',
    'A','T','E','R','I','A','L','I','Z','E','D','E','F','E','R','R','E','D',
    'I','S','T','I','N','C','T','U','P','D','A','T','E','V','A','L','U','E',
    'S','V','I','R','T','U','A','L','W','A','Y','S','W','H','E','N','W','H',
    'E','R','E','C','U','R','S','I','V','E','A','B','O','R','T','A','F','T',
    'E','R','E','N','A','M','E','A','N','D','R','O','P','A','R','T','I','T',
    'I','O','N','A','U','T','O','I','N','C','R','E','M','E','N','T','C','A',
    'S','T','C','O','L','U','M','N','C','O','M','M','I','T','C','O','N','F',
    'L','I','C','T','C','R','O','S','S','C','U','R','R','E','N','T','_','T',
    'I','M','E','S','T','A','M','P','R','E','C','E','D','I','N','G','F','A',
    'I','L','A','S','T','F','I','L','T','E','R','E','P','L','A','C','E','F',
    'I','R','S','T','F','O','L','L','O','W','I','N','G','F','R','O','M','F',
    'U','L','L','I','M','I','T','I','F','O','R','D','E','R','E','S','T','R',
    'I','C','T','O','T','H','E','R','S','O','V','E','R','E','T','U','R','N',
    'I','N','G','R','I','G','H','T','R','O','L','L','B','A','C','K','R','O',
    'W','S','U','N','B','O','U','N','D','E','D','U','N','I','O','N','U','S',
    'I','N','G','V','A','C','U','U','M','V','I','E','W','I','N','D','O','W',
    'B','Y','I','N','I','T','I','A','L','L','Y','P','R','I','M','A','R','Y',
};

/* aKWCode[i] is the parser symbol code for the i-th keyword */
static const unsigned char aKWCode[147] = {
    TKIR_REINDEX,    TKIR_INDEXED,    TKIR_INDEX,      TKIR_DESC,       TKIR_ESCAPE,
    TKIR_EACH,       TKIR_CHECK,      TKIR_KEY,        TKIR_BEFORE,     TKIR_FOREIGN,
    TKIR_FOR,        TKIR_IGNORE,     TKIR_LIKE_KW,    TKIR_EXPLAIN,    TKIR_INSTEAD,
    TKIR_ADD,        TKIR_DATABASE,   TKIR_AS,         TKIR_SELECT,     TKIR_TABLE,
    TKIR_JOIN_KW,    TKIR_THEN,       TKIR_END,        TKIR_DEFERRABLE, TKIR_ELSE,
    TKIR_EXCLUDE,    TKIR_DELETE,     TKIR_TEMP,       TKIR_TEMP,       TKIR_OR,
    TKIR_ISNULL,     TKIR_NULLS,      TKIR_SAVEPOINT,  TKIR_INTERSECT,  TKIR_TIES,
    TKIR_NOTNULL,    TKIR_NOT,        TKIR_NO,         TKIR_NULL,       TKIR_LIKE_KW,
    TKIR_EXCEPT,     TKIR_TRANSACTION,TKIR_ACTION,     TKIR_ON,         TKIR_JOIN_KW,
    TKIR_ALTER,      TKIR_RAISE,      TKIR_EXCLUSIVE,  TKIR_EXISTS,     TKIR_CONSTRAINT,
    TKIR_INTO,       TKIR_OFFSET,     TKIR_OF,         TKIR_SET,        TKIR_TRIGGER,
    TKIR_RANGE,      TKIR_GENERATED,  TKIR_DETACH,     TKIR_HAVING,     TKIR_LIKE_KW,
    TKIR_BEGIN,      TKIR_JOIN_KW,    TKIR_REFERENCES, TKIR_UNIQUE,     TKIR_QUERY,
    TKIR_WITHOUT,    TKIR_WITH,       TKIR_JOIN_KW,    TKIR_RELEASE,    TKIR_ATTACH,
    TKIR_BETWEEN,    TKIR_NOTHING,    TKIR_GROUPS,     TKIR_GROUP,      TKIR_CASCADE,
    TKIR_ASC,        TKIR_DEFAULT,    TKIR_CASE,       TKIR_COLLATE,    TKIR_CREATE,
    TKIR_CTIME_KW,   TKIR_IMMEDIATE,  TKIR_JOIN,       TKIR_INSERT,     TKIR_MATCH,
    TKIR_PLAN,       TKIR_ANALYZE,    TKIR_PRAGMA,     TKIR_MATERIALIZED, TKIR_DEFERRED,
    TKIR_DISTINCT,   TKIR_IS,         TKIR_UPDATE,     TKIR_VALUES,     TKIR_VIRTUAL,
    TKIR_ALWAYS,     TKIR_WHEN,       TKIR_WHERE,      TKIR_RECURSIVE,  TKIR_ABORT,
    TKIR_AFTER,      TKIR_RENAME,     TKIR_AND,        TKIR_DROP,       TKIR_PARTITION,
    TKIR_AUTOINCR,   TKIR_TO,         TKIR_IN,         TKIR_CAST,       TKIR_COLUMNKW,
    TKIR_COMMIT,     TKIR_CONFLICT,   TKIR_JOIN_KW,    TKIR_CTIME_KW,   TKIR_CTIME_KW,
    TKIR_CURRENT,    TKIR_PRECEDING,  TKIR_FAIL,       TKIR_LAST,       TKIR_FILTER,
    TKIR_REPLACE,    TKIR_FIRST,      TKIR_FOLLOWING,  TKIR_FROM,       TKIR_JOIN_KW,
    TKIR_LIMIT,      TKIR_IF,         TKIR_ORDER,      TKIR_RESTRICT,   TKIR_OTHERS,
    TKIR_OVER,       TKIR_RETURNING,  TKIR_JOIN_KW,    TKIR_ROLLBACK,   TKIR_ROWS,
    TKIR_ROW,        TKIR_UNBOUNDED,  TKIR_UNION,      TKIR_USING,      TKIR_VACUUM,
    TKIR_VIEW,       TKIR_WINDOW,     TKIR_DO,         TKIR_BY,         TKIR_INITIALLY,
    TKIR_ALL,        TKIR_PRIMARY,
};

/* aKWOffset[i] is the index into zKWText[] of the start of
** the text for the i-th keyword. */
static const unsigned short int aKWOffset[147] = {
    0,   2,   2,   8,   9,  14,  16,  20,  23,  25,  25,  29,  33,
    36,  41,  46,  48,  53,  54,  59,  62,  65,  67,  69,  78,  81,
    86,  90,  90,  94,  99, 101, 105, 111, 119, 123, 123, 123, 126,
    129, 132, 137, 142, 146, 147, 152, 156, 160, 168, 174, 181, 184,
    184, 187, 189, 195, 198, 206, 211, 216, 219, 222, 226, 236, 239,
    244, 244, 248, 252, 259, 265, 271, 277, 277, 283, 284, 288, 295,
    299, 306, 312, 324, 333, 335, 341, 346, 348, 355, 359, 370, 377,
    378, 385, 391, 397, 402, 408, 412, 415, 424, 429, 433, 439, 441,
    444, 453, 455, 457, 466, 470, 476, 482, 490, 495, 495, 495, 511,
    520, 523, 527, 532, 539, 544, 553, 557, 560, 565, 567, 571, 579,
    585, 588, 597, 602, 610, 610, 614, 623, 628, 633, 639, 642, 645,
    648, 650, 655, 659,
};

static int keywordCode(const char *z, int n, int *pType){
  int i, j;
  const char *zKW;
  if( n>=2 ){
    i = ((charMap(z[0])*4) ^ (charMap(z[n-1])*3) ^ n*1) % 127;
    for(i=((int)aKWHash[i])-1; i>=0; i=((int)aKWNext[i])-1){
      if( aKWLen[i]!=n ) continue;
      zKW = &zKWText[aKWOffset[i]];
      if( (z[0]&~0x20)!=zKW[0] ) continue;
      if( (z[1]&~0x20)!=zKW[1] ) continue;
      j = 2;
      while( j<n && (z[j]&~0x20)==zKW[j] ){ j++; }
      if( j<n ) continue;
      *pType = aKWCode[i];
      break;
    }
  }
  return n;
}
int sqlite3KeywordCode(const unsigned char *z, int n){
  int id = TKIR_ID;
  keywordCode((char*)z, n, &id);
  return id;
}

int sqlite3GetToken(const unsigned char *z, int *tokenType);

static int sqlite3ParserFallback(int iToken){
#ifdef YYFALLBACK
  assert( iToken<(int)(sizeof(yyFallback)/sizeof(yyFallback[0])) );
  return yyFallback[iToken];
#else
  (void)iToken;
  return 0;
#endif
}

static int getToken(const unsigned char **pz){
  const unsigned char *z = *pz;
  int t;                          /* Token type to return */
  do {
    z += sqlite3GetToken(z, &t);
  }while( t==TKIR_SPACE );
  if( t==TKIR_ID
      || t==TKIR_STRING
      || t==TKIR_JOIN_KW
      || t==TKIR_WINDOW
      || t==TKIR_OVER
      || sqlite3ParserFallback(t)==TKIR_ID
  ){
    t = TKIR_ID;
  }
  *pz = z;
  return t;
}


inline int analyzeWindowKeyword(const unsigned char *z){
  int t;
  t = getToken(&z);
  if( t!=TKIR_ID ) return TKIR_ID;
  t = getToken(&z);
  if( t!=TKIR_AS ) return TKIR_ID;
  return TKIR_WINDOW;
}

inline int analyzeOverKeyword(const unsigned char *z, int lastToken){
  if( lastToken==TKIR_RP ){
    int t = getToken(&z);
    if( t==TKIR_LP || t==TKIR_ID ) return TKIR_OVER;
  }
  return TKIR_ID;
}

inline int analyzeFilterKeyword(const unsigned char *z, int lastToken){
  if( lastToken==TKIR_RP && getToken(&z)==TKIR_LP ){
    return TKIR_FILTER;
  }
  return TKIR_ID;
}

int sqlite3GetToken(const unsigned char *z, int *tokenType){
  int i, c;
  switch( aiClass[*z] ){  /* Switch on the character-class of the first byte
                          ** of the token. See the comment on the CC_ defines
                          ** above. */
  case CC_SPACE: {
    for(i=1; sqlite3Isspace(z[i]); i++){}
    *tokenType = TKIR_SPACE;
    return i;
  }
  case CC_MINUS: {
    if( z[1]=='-' ){
      for(i=2; (c=z[i])!=0 && c!='\n'; i++){}
      *tokenType = TKIR_SPACE;   /* IMP: R-22934-25134 */
      return i;
    }else if( z[1]=='>' ){
      *tokenType = TKIR_PTR;
      return 2 + (z[2]=='>');
    }
    *tokenType = TKIR_MINUS;
    return 1;
  }
  case CC_LP: {
    *tokenType = TKIR_LP;
    return 1;
  }
  case CC_RP: {
    *tokenType = TKIR_RP;
    return 1;
  }
  case CC_SEMI: {
    *tokenType = TKIR_SEMI;
    return 1;
  }
  case CC_PLUS: {
    *tokenType = TKIR_PLUS;
    return 1;
  }
  case CC_STAR: {
    *tokenType = TKIR_STAR;
    return 1;
  }
  case CC_SLASH: {
    if( z[1]!='*' || z[2]==0 ){
      *tokenType = TKIR_SLASH;
      return 1;
    }
    for(i=3, c=z[2]; (c!='*' || z[i]!='/') && (c=z[i])!=0; i++){}
    if( c ) i++;
    *tokenType = TKIR_SPACE;   /* IMP: R-22934-25134 */
    return i;
  }
  case CC_PERCENT: {
    *tokenType = TKIR_REM;
    return 1;
  }
  case CC_EQ: {
    *tokenType = TKIR_EQ;
    return 1 + (z[1]=='=');
  }
  case CC_LT: {
    if( (c=z[1])=='=' ){
      *tokenType = TKIR_LE;
      return 2;
    }else if( c=='>' ){
      *tokenType = TKIR_NE;
      return 2;
    }else if( c=='<' ){
      *tokenType = TKIR_LSHIFT;
      return 2;
    }else{
      *tokenType = TKIR_LT;
      return 1;
    }
  }
  case CC_GT: {
    if( (c=z[1])=='=' ){
      *tokenType = TKIR_GE;
      return 2;
    }else if( c=='>' ){
      *tokenType = TKIR_RSHIFT;
      return 2;
    }else{
      *tokenType = TKIR_GT;
      return 1;
    }
  }
  case CC_BANG: {
    if( z[1]!='=' ){
      *tokenType = TKIR_ILLEGAL;
      return 1;
    }else{
      *tokenType = TKIR_NE;
      return 2;
    }
  }
  case CC_PIPE: {
    if( z[1]!='|' ){
      *tokenType = TKIR_BITOR;
      return 1;
    }else{
      *tokenType = TKIR_CONCAT;
      return 2;
    }
  }
  case CC_COMMA: {
    *tokenType = TKIR_COMMA;
    return 1;
  }
  case CC_AND: {
    *tokenType = TKIR_BITAND;
    return 1;
  }
  case CC_TILDA: {
    *tokenType = TKIR_BITNOT;
    return 1;
  }
  case CC_QUOTE: {
    int delim = z[0];
    for(i=1; (c=z[i])!=0; i++){
      if( c==delim ){
        if( z[i+1]==delim ){
          i++;
        }else{
          break;
        }
      }
    }
    if( c=='\'' ){
      *tokenType = TKIR_STRING;
      return i+1;
    }else if( c!=0 ){
      *tokenType = TKIR_ID;
      return i+1;
    }else{
      *tokenType = TKIR_ILLEGAL;
      return i;
    }
  }
  case CC_DOT: {
#ifndef SQLITE_OMIT_FLOATING_POINT
    if( !sqlite3Isdigit(z[1]) )
#endif
    {
      *tokenType = TKIR_DOT;
      return 1;
    }
    /* If the next character is a digit, this is a floating point
      ** number that begins with ".".  Fall thru into the next case */
  }
  case CC_DIGIT: {
    *tokenType = TKIR_INTEGER;
#ifndef SQLITE_OMIT_HEX_INTEGER
    if( z[0]=='0' && (z[1]=='x' || z[1]=='X') && sqlite3Isxdigit(z[2]) ){
      for(i=3; sqlite3Isxdigit(z[i]); i++){}
      return i;
    }
#endif
    for(i=0; sqlite3Isdigit(z[i]); i++){}
#ifndef SQLITE_OMIT_FLOATING_POINT
    if( z[i]=='.' ){
      i++;
      while( sqlite3Isdigit(z[i]) ){ i++; }
      *tokenType = TKIR_FLOAT;
    }
    if( (z[i]=='e' || z[i]=='E') &&
        ( sqlite3Isdigit(z[i+1]) 
         || ((z[i+1]=='+' || z[i+1]=='-') && sqlite3Isdigit(z[i+2]))
             )
    ){
      i += 2;
      while( sqlite3Isdigit(z[i]) ){ i++; }
      *tokenType = TKIR_FLOAT;
    }
#endif
    while( IdChar(z[i]) ){
      *tokenType = TKIR_ILLEGAL;
      i++;
    }
    return i;
  }
  case CC_QUOTE2: {
    for(i=1, c=z[0]; c!=']' && (c=z[i])!=0; i++){}
    *tokenType = c==']' ? TKIR_ID : TKIR_ILLEGAL;
    return i;
  }
  case CC_VARNUM: {
    *tokenType = TKIR_VARIABLE;
    for(i=1; sqlite3Isdigit(z[i]); i++){}
    return i;
  }
  case CC_DOLLAR:
  case CC_VARALPHA: {
    int n = 0;
    *tokenType = TKIR_VARIABLE;
    for(i=1; (c=z[i])!=0; i++){
      if( IdChar(c) ){
        n++;
#ifndef SQLITE_OMIT_TCL_VARIABLE
      }else if( c=='(' && n>0 ){
        do{
          i++;
        }while( (c=z[i])!=0 && !sqlite3Isspace(c) && c!=')' );
        if( c==')' ){
          i++;
        }else{
          *tokenType = TKIR_ILLEGAL;
        }
        break;
      }else if( c==':' && z[i+1]==':' ){
        i++;
#endif
      }else{
        break;
      }
    }
    if( n==0 ) *tokenType = TKIR_ILLEGAL;
    return i;
  }
  case CC_KYWD0: {
    for(i=1; aiClass[z[i]]<=CC_KYWD; i++){}
    if( IdChar(z[i]) ){
      /* This token started out using characters that can appear in keywords,
        ** but z[i] is a character not allowed within keywords, so this must
        ** be an identifier instead */
      i++;
      break;
    }
    *tokenType = TKIR_ID;
    return keywordCode((char*)z, i, tokenType);
  }
  case CC_X: {
#ifndef SQLITE_OMIT_BLOB_LITERAL
    if( z[1]=='\'' ){
      *tokenType = TKIR_BLOB;
      for(i=2; sqlite3Isxdigit(z[i]); i++){}
      if( z[i]!='\'' || i%2 ){
        *tokenType = TKIR_ILLEGAL;
        while( z[i] && z[i]!='\'' ){ i++; }
      }
      if( z[i] ) i++;
      return i;
    }
#endif
    /* If it is not a BLOB literal, then it must be an ID, since no
      ** SQL keywords start with the letter 'x'.  Fall through */
  }
  case CC_KYWD:
  case CC_ID: {
    i = 1;
    break;
  }
  case CC_BOM: {
    if( z[1]==0xbb && z[2]==0xbf ){
      *tokenType = TKIR_SPACE;
      return 3;
    }
    i = 1;
    break;
  }
  case CC_NUL: {
    *tokenType = TKIR_ILLEGAL;
    return 0;
  }
  default: {
    *tokenType = TKIR_ILLEGAL;
    return 1;
  }
  }
  while( IdChar(z[i]) ){ i++; }
  *tokenType = TKIR_ID;
  return i;
}

IR* parser_helper(const string in_str) {

  IR* root_ir = nullptr;
  IR** tmp_p_root_ir = &root_ir;

  void* pEngine = IRParserAlloc(malloc);
  if (pEngine == 0) {
    cerr << "\n\n\nERROR: Lemon parser initialization failed. \n\n\n";
    exit(1);
  }

  int tokenType = 0;
  const char* zSql = in_str.c_str();
  int n = 0;
  int lastTokenParsed = -1;

  while( 1 ) {
    if ((zSql - in_str.c_str()) == in_str.size()) {
      break;
    }
    n = sqlite3GetToken((const unsigned char *)zSql, &tokenType);

    if (tokenType >= TKIR_WINDOW) {
      assert(tokenType == TKIR_SPACE || tokenType == TKIR_OVER ||
             tokenType == TKIR_FILTER || tokenType == TKIR_ILLEGAL ||
             tokenType == TKIR_WINDOW);
      if (tokenType == TKIR_SPACE) {
        zSql += n;
        continue;
      }
      if (zSql[0] == 0) {
        /* Upon reaching the end of input, call the parser two more times
        ** with tokens TKIR_SEMI and 0, in that order. */
        if (lastTokenParsed == TKIR_SEMI) {
          tokenType = 0;
        } else if (lastTokenParsed == 0) {
          break;
        } else {
          tokenType = TKIR_SEMI;
        }
        n = 0;
#ifndef SQLITE_OMIT_WINDOWFUNC
      } else if (tokenType == TKIR_WINDOW) {
        assert(n == 6);
        tokenType = analyzeWindowKeyword((const unsigned char *)&zSql[6]);
      } else if (tokenType == TKIR_OVER) {
        assert(n == 4);
        tokenType = analyzeOverKeyword((const unsigned char *)&zSql[4], lastTokenParsed);
      } else if (tokenType == TKIR_FILTER) {
        assert(n == 6);
        tokenType = analyzeFilterKeyword((const unsigned char *)&zSql[6], lastTokenParsed);
#endif /* SQLITE_OMIT_WINDOWFUNC */
      } else {
        cerr << "unrecognized token. \n\n\n";
        break;
      }
    }
    IRParser(pEngine, tokenType, zSql, tmp_p_root_ir);
    lastTokenParsed = tokenType;
    zSql += n;
  }
  IRParser(pEngine, 0, "", tmp_p_root_ir);
  IRParserFree(pEngine, free);

  return root_ir;

}
