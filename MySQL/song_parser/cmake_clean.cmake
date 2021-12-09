file(REMOVE_RECURSE
  "join_syntax-t"
  "join_syntax-t.pdb"
  "join_syntax-t.cc.o"
  "join_syntax-t.cc.i"
  "join_syntax-t.cc.s"
)

# Per-language clean rules from dependency scanning.
foreach(lang CXX)
  include(cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
