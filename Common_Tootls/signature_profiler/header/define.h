#ifndef SIGNATURE_PROFILER_DEFINE_H
#define SIGNATURE_PROFILER_DEFINE_H

#include <map>
#include <string>

using std::map;
using std::string;

#define ALLDATATYPE(V)                                                         \
  V(TYPEUNKNOWN)                                                               \
  V(TYPEUNDEFINE)                                                              \
  V(TYPEANY)                                                                   \
  V(TYPENONE)                                                                  \
  V(TYPEIDENT)                                                                 \
  V(TYPEVOID)                                                                  \
  V(TYPEBIGINT)                                                                \
  V(TYPEBIGSERIAL)                                                             \
  V(TYPEBIT)                                                                   \
  V(TYPEVARBIT)                                                                \
  V(TYPEBOOL)                                                                  \
  V(TYPEBYTEA)                                                                 \
  V(TYPECHAR)                                                                  \
  V(TYPEVARCHAR)                                                               \
  V(TYPECIDR)                                                                  \
  V(TYPEDATE)                                                                  \
  V(TYPEFLOAT)                                                                 \
  V(TYPEINET)                                                                  \
  V(TYPEINT)                                                                   \
  V(TYPEINTERVAL)                                                              \
  V(TYPEJSON)                                                                  \
  V(TYPEJSONB)                                                                 \
  V(TYPEMACADDR)                                                               \
  V(TYPEMACADDR8)                                                              \
  V(TYPEMONEY)                                                                 \
  V(TYPENUMERIC)                                                               \
  V(TYPEREAL)                                                                  \
  V(TYPESMALLINT)                                                              \
  V(TYPESMALLSERIAL)                                                           \
  V(TYPESERIAL)                                                                \
  V(TYPETEXT)                                                                  \
  V(TYPETIME)                                                                  \
  V(TYPETIMETZ)                                                                \
  V(TYPETIMESTAMP)                                                             \
  V(TYPETIMESTAMPTZ)                                                           \
  V(TYPEUUID)                                                                  \
  V(TYPEOID)                                                                   \
  /* Separator line. Do not auto generate the types below this line. */        \
  V(TYPECSTRING)                                                               \
  /* Separator line. Do not support the types below this line. */              \
  V(TYPENOTSUPPORT)                                                            \
  V(TYPETSQUERY)                                                               \
  V(TYPETSVECTOR)                                                              \
  V(TYPETXIDSNAPSHOT)                                                          \
  V(TYPEXML)                                                                   \
  V(TYPEENUM)                                                                  \
  V(TYPETUPLE)                                                                 \
  V(TYPEBOX)                                                                   \
  V(TYPECIRCLE)                                                                \
  V(TYPELINE)                                                                  \
  V(TYPELSEG)                                                                  \
  V(TYPEPATH)                                                                  \
  V(TYPEPGLSN)                                                                 \
  V(TYPEPGSNAPSHOT)                                                            \
  V(TYPEPOINT)                                                                 \
  V(TYPEPOLYGON)

#define ALLFUNCTIONTYPESMYSQL(V)                                               \
  V(FUNCUNKNOWN)                                                               \
  V(FUNCAGGR)                                                                  \
  V(FUNCORDERAGGR)                                                             \
  V(FUNCHYPOTHETICALAGGR)                                                      \
  V(FUNCWINDOW)                                                                \
  V(FUNCCOMP)                                                                  \
  V(FUNCMATH)                                                                  \
  V(FUNCSTR)                                                                   \
  V(FUNCBINSTR)                                                                \
  V(FUNCREG)                                                                   \
  V(FUNCDATATYPE)                                                              \
  V(FUNCDATETIME)                                                              \
  V(FUNCENUM)                                                                  \
  V(FUNCGEO)                                                                   \
  V(FUNCINET)                                                                  \
  V(FUNCTEXTSEARCH)                                                            \
  V(FUNCUUID)                                                                  \
  V(FUNCXML)                                                                   \
  V(FUNCJSON)                                                                  \
  V(FUNCSEQ)                                                                   \
  V(FUNCARRAY)                                                                 \
  V(FUNCRANGE)                                                                 \
  V(FUNCSETRETURN)                                                             \
  V(FUNCSYSINFO)                                                               \
  V(FUNCSYSADMIN)                                                              \
  V(FUNCTRIGGER)                                                               \
  V(FUNCEVENTTRIGGER)                                                          \
  V(FUNCSTAT)

#endif // SIGNATURE_PROFILER_DEFINE_H
