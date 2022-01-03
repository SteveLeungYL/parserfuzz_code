create procedure proc_1() install plugin my_plug soname '/root/some_plugin.so';
call proc_1();
call proc_1();
call proc_1();
drop procedure proc_1;
prepare abc from "install plugin my_plug soname '/root/some_plugin.so'";
execute abc;
execute abc;
deallocate prepare abc;
