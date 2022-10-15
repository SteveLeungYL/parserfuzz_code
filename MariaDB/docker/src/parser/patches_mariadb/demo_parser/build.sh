# /bin/bash

CC=clang CXX=clang++ CFLAGS="-fPIC" CXXFLAGS="-fPIC" cmake ..  -DWITH_UNIT_TESTS=OFF -DUSE_LD_GOLD=1 -DCMAKE_INSTALL_PREFIX=$(pwd) -DCMAKE_POSITION_INDEPENDENT_CODE=ON
make -j$(nproc) && make install -j$(nproc)

cd sql
/usr/bin/clang++  -shared -fPIC -fstack-protector --param=ssp-buffer-size=4 -O0 -g -DNDEBUG -fno-omit-frame-pointer -D_FORTIFY_SOURCE=2 -DDBUG_OFF -Wall -Wdeclaration-after-statement -Wenum-compare -Wenum-conversion -Wextra -Wformat-security -Wno-init-self -Wno-null-conversion -Wno-unused-parameter -Wno-unused-private-field -Woverloaded-virtual -Wnon-virtual-dtor -Wvla -Wwrite-strings   -Wl,-z,relro,-z,now -Wl,--export-dynamic -o mariadb_parser.so  -pthread -Wl,-whole-archive libsql.a -Wl,-no-whole-archive  libsql_builtins.a ../vio/libvio.a ../extra/pcre2/src/pcre2-build/libpcre2-8.a -lcrypt ../storage/maria/libaria.a ../mysys_ssl/libmysys_ssl.a libpartition.a ../storage/perfschema/libperfschema.a libsql_sequence.a libwsrep.a ../storage/csv/libcsv.a ../storage/heap/libheap.a ../storage/innobase/libinnobase.a ../tpool/libtpool.a ../storage/myisam/libmyisam.a ../mysys/libmysys.a ../dbug/libdbug.a ../strings/libstrings.a ../mysys/libmysys.a ../dbug/libdbug.a ../strings/libstrings.a -lz -lm ../storage/myisammrg/libmyisammrg.a ../storage/sequence/libsequence.a ../plugin/auth_socket/libauth_socket.a ../plugin/feedback/libfeedback.a -lssl -lcrypto ../plugin/type_geom/libtype_geom.a ../plugin/type_inet/libtype_inet.a ../plugin/type_uuid/libtype_uuid.a ../plugin/user_variables/libuser_variables.a ../plugin/userstat/libuserstat.a ../wsrep-lib/src/libwsrep-lib.a -lpthread -ldl ../wsrep-lib/wsrep-API/libwsrep_api_v26.a libthread_pool_info.a -pthread

cp ./mariadb_parser.so /home/sly/Desktop/Mac/Home/Desktop/Projects/SQLRight_Project/sqlright-code/MariaDB/docker/src/parser/patches_mariadb/demo_parser/
cd ../

