call mtr.add_suppression("Plugin .* is not to be used as an .early. plugin");
call mtr.add_suppression("Couldn't load plugin named .* with soname ");
SELECT @@global.example_enum_var = 'e2';
