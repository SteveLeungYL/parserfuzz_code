#include "../include/data_affinity.h"
#include "../include/utils.h"
#include "../include/rand_json_generator.h"

#include <regex>
#include <float.h>
#include <math.h>

map<string, string> sql_type_alias_2_type = {};

string get_string_by_affinity_type(DATAAFFINITYTYPE type) {
#define DECLARE_CASE(classname)                                                \
  if (type == classname)                                                       \
    return #classname;
    ALLDATAAFFINITY(DECLARE_CASE);
#undef DECLARE_CASE
    return "";
}

inline void rewrite_data_affinity_string_macro(string& in) {

    in = str_toupper(in);

    if (in.size() > 4 && in.substr(0, 4) == "AFFI") {
        return;
    } else {
        in = "AFFI" + in;
    }

    // Remove the various length
    in = string_splitter(in, '(')[0];

    if (sql_type_alias_2_type.count(in) != 0) {
        cerr << "\n\n\nDEBUG: rewriting in: " << in;
        in = sql_type_alias_2_type[in];
        cerr << " to: " << in << "\n\n\n";
    }
}

DATAAFFINITYTYPE get_data_affinity_by_string(string s) {
    rewrite_data_affinity_string_macro(s);

#define DECLARE_CASE(dataAffiname)                                             \
  if (s == #dataAffiname)                                                      \
    return dataAffiname;
    ALLDATAAFFINITY(DECLARE_CASE);
#undef DECLARE_CASE
    string err = "\n\n\nError: Cannot find the matching data affinity by"
            " string: " + s + " \n\n\n";
    cerr << err;
    abort();
//    return AFFIUNKNOWN;
}

DATAAFFINITYTYPE get_data_affinity_by_idx(int idx) { return static_cast<DATAAFFINITYTYPE>(idx); }

bool DataAffinity::is_str_collation(const string& str_in) {
#define CMP_STR(collationname)                                                \
  if (str_in == #collationname)                                               \
    return true;
    ALLCOLLATIONS(CMP_STR);
#undef DECLARE_CASE
    return false;
}

string DataAffinity::get_rand_collation_str() {
#define DECLARE_CASE(collation_name) #collation_name,
    vector<string> v_collate_str {
            ALLCOLLATIONS(DECLARE_CASE)
    };
#undef DECLARE_CASE

    auto rand_idx = get_rand_int(v_collate_str.size());
    if (rand_idx == 0) {
        return "default";
    } else {
        return v_collate_str[rand_idx];
    }
}

DATAAFFINITYTYPE DataAffinity::detect_numerical_type(const string& str_in){

    if (findStringIn(str_in, ".")) {
        // Candidates: AFFIDECIMAL, AFFIFLOAT
        return AFFIDECIMAL;
    } else {
        // Candidates: AFFIINT, AFFIOID (unsigned 32-bit), SERIAL (INTEGER with DEFAULT configs)
        return AFFIINT;
    }
}

DATAAFFINITYTYPE DataAffinity::detect_string_type(const string& str_in){

    // date: 1994-09-21.
    regex date ("^'\\d+-\\d+-\\d+'$");
    if (regex_match(str_in, date)) {
        return AFFIDATE;
    }

    // IP address.
    regex inet_ipv4("^'\\d+\\.\\d+\\.\\d+\\.\\d+(?:\\/\\d+)?'$");
    regex inet_ipv6("^'\\w+:\\w+:\\w+:\\w+:\\w+:\\w+:\\w+:\\w+(?:\\/\\d+)?'$");
    if (regex_match(str_in, inet_ipv4) || regex_match(str_in, inet_ipv6)) {
        return AFFIINT;
    }

    // Interval.
    // INTERVAL '2h30m30s'
    regex interval_sim("^'(?:\\d+h)?(?:\\d+m)?\\d+s'$");
    // INTERVAL 'Y-M D H:M:S'
    regex interval_SQL("^'(?:\\d+-\\d+)? (?:\\d+)? \\d+:\\d+:\\d+'$");
    // INTERVAL 'P1Y2M3DT4H5M6S'
    regex interval_ISO("^'P(?:\\d+Y)(?:\\d+M)(?:\\d+DT)\\d+H\\d+M\\d+S'$");
    // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'
    regex interval_tradi_posts("^'\\d+ year(s)? \\d+ month(s)? \\d+ day(s)? \\d+ hour(s)? \\d+ minute(s)? \\d+ second(s)?'$");
    // INTERVAL '1 yr 2 mons 3 d 4 hrs 5 mins 6 secs'
    regex interval_abbr_posts("^'\\d+ yr(s)? \\d+ mon(s)? \\d+ d(s)? \\d+ hr(s)? \\d+ min(s)? \\d+ sec(s)?'$");
    if (
            regex_match(str_in, interval_sim) ||
            regex_match(str_in, interval_SQL) ||
            regex_match(str_in, interval_ISO) ||
            regex_match(str_in, interval_tradi_posts) ||
            regex_match(str_in, interval_abbr_posts)
            ) {
        return AFFIINTERVAL;
    }

    // Time: "TIME '01:23:45.123456'"
    regex time_rex("^'\\d+:\\d+:\\d+\\.\\d+'$");
    if (regex_match(str_in, time_rex)) {
        return AFFITIME;
    }

    // TIMETZ: TIMETZ '01:23:45.123456-5:00', TIMETZ '01:23:45.123456+5:00'
    regex timetz_rex("^'\\d+:\\d+:\\d+\\.\\d+[-,+]\\d+:\\d+'$");
    if (regex_match(str_in, timetz_rex)) {
        return AFFITIMETZ;
    }

    regex timestamp_rex("^'\\d+-\\d+-\\d+ \\d+:\\d+:\\d+'$");
    if (regex_match(str_in, timestamp_rex)) {
        return AFFITIMESTAMP;
    }

    regex timestamptz_rex("^'\\d+-\\d+-\\d+[ ,T]\\d+:\\d+:\\d+((\\.\\d+)|(\\-\\d+:\\d+))'$");
    if (regex_match(str_in, timestamptz_rex)) {
        return AFFITIMESTAMPTZ;
    }

    regex uuid_rex("^'(urn:)?(uuid:)?\\w+-\\w+-\\w+-\\w+-\\w+'$");
    if (regex_match(str_in, uuid_rex)) {
        return AFFIUUID;
    }

    // Doesn't match any special types. Directly return the AFFISTRING type.
    return AFFISTRING;

}

DATAAFFINITYTYPE DataAffinity::recognize_data_type(const string& str_in){
    /* Given the string input (str_val_), detects its possible data type, and setup the DataAffinity struct. */
    // Cannot detect the ENUM type.

    // First, check whether the input string is empty.
    if(str_in.size() == 0) {
        return AFFIUNKNOWN;
    }

    // Second, filter out the easy to detect type first.
    if (str_in.size() > 2 && str_in[0] == 'B' && str_in[1] == '\'') {
        this->data_affinity = AFFIBIT;
        return AFFIBIT;
    } else if (str_in.size() > 2 && str_in[0] == 'b' && str_in[1] == '\'') {
        this->data_affinity = AFFIBYTES;
        return AFFIBYTES;
    } else if (str_in == "true" || str_in == "false") {
        this->data_affinity = AFFIBOOL;
        return AFFIBOOL;
    } else if (this->is_str_collation(str_in)) {
        this->data_affinity = AFFICOLLATE;
        return AFFICOLLATE;
    } else if (str_in[0] == '{' && str_in[str_in.size() - 1] == '}') {
        this->data_affinity = AFFIARRAY;
        return AFFIARRAY;
    } else if (str_in.size() > 4
        && str_in[0] == '\''
        && str_in[1] == '{'
        && str_in[str_in.size()-2] == '\''
        && str_in[str_in.size()-1]  == '}' // {'...'}
        ) {
        this->data_affinity = AFFIJSONB;
        return AFFIJSONB;
    } else if (
            str_in == "'inf'" ||
            str_in == "'infinity'" ||
            str_in == "'+inf'" ||
            str_in == "'+infinity'" ||
            str_in == "'-inf'" ||
            str_in == "'-infinity'"
            ) {
        this->data_affinity = AFFIFLOAT;
        return AFFIFLOAT;
    }

    // Third, compare the detailed numerical or string types.
    // Figure out whether it is numerical or string type.
    if (str_in.size() > 2 && str_in[0] == '\'' && str_in[str_in.size()-1] == '\'') {
        // String
        DATAAFFINITYTYPE detected_type = detect_string_type(str_in);
        this->data_affinity = detected_type;
        return this->data_affinity;
    } else {
        // Numerical
        DATAAFFINITYTYPE detected_type = detect_numerical_type(str_in);
        this->data_affinity = detected_type;
        return this->data_affinity;
    }

}

string DataAffinity::mutate_affi_int() {
    // and also for serial.
    // This is actually 64 bits integers.

    if (this->is_enum) {
        return vector_rand_ele(this->v_enum_str);
    }

    if (this->is_range) {
        auto rand_int = get_rand_long_long(9223372036854775807); // Max long long.
        auto range = int_max - int_min;
        rand_int = (rand_int % range) + int_min;
        string rand_int_str = to_string(rand_int);
        return rand_int_str;
    }

    if (get_rand_int(3) == 0) { // 1/3 chance, choose special value.
        auto rand_choice = get_rand_int(3);
        switch (rand_choice) {
            case 0:
                return "-9223372036854775807";
            case 1:
                return "9223372036854775807";
            case 2:
                return "0";
        }
        return "0";
    } else {
        // Randomly mutate the number.
        auto rand_int = get_rand_long_long(9223372036854775807);
        string rand_int_str = to_string(rand_int);
        if (get_rand_int(2)) {
            return rand_int_str;
        } else {
            return "-" + rand_int_str;
        }
    }
}

string DataAffinity::mutate_affi_oid() {
    // unsigned oid.
    if (this->is_enum) {
        return vector_rand_ele(this->v_enum_str);
    }

    if (this->is_range) {
        auto rand_int = get_rand_long_long(9223372036854775807); // Max long long.
        auto range = int_max - int_min;
        rand_int = (rand_int % range) + int_min;
        string rand_int_str = to_string(rand_int);
        return rand_int_str;
    }

    if (get_rand_int(3) == 0) { // 1/3 chance, choose special value.
        auto rand_choice = get_rand_int(2);
        switch (rand_choice) {
            case 0:
                return "4294967295";
            case 1:
                return "0";
        }
        return "0";
    } else {
        // Randomly mutate the number.
        auto rand_int = get_rand_int(INT16_MAX);
        return to_string(rand_int);
    }
}
string DataAffinity::mutate_affi_float() {
    // decimal and float.
    // unsigned oid.
    if (this->is_enum) {
        return vector_rand_ele(this->v_enum_str);
    }

    if (this->is_range) {
        auto rand_float = get_rand_double(DBL_MAX); // Max double precision.
        auto range = float_max - float_min;
        rand_float = fmod(rand_float, range) + float_min;
        string rand_float_str = to_string(rand_float);
        return rand_float_str;
    }

    if (get_rand_int(10) != 0) {
        // 80% of chance.
        return to_string(get_rand_double(-100.0, 100.0));
    } else {
        return to_string(get_rand_double(DBL_MIN, DBL_MAX));
    }

}

string DataAffinity::mutate_affi_array() {

    DATAAFFINITYTYPE cur_transformed_affi = this->transfer_array_to_normal_type(this->data_affinity);

//    int format = get_rand_int(2);
    int format = 1; // Do not use the direct string method.
    int len = get_rand_int(6) + 1; // At most 6 elements.
    string ret_str = "";

    if (format) {
        ret_str = "ARRAY[";
    } else {
        ret_str += "'{";
    }

    for (int i = 0; i < len; i++) {
        if (i > 0) {
            ret_str += ", ";
        }
        ret_str += this->get_mutated_literal(cur_transformed_affi);
    }

    if (format) {
        ret_str += "]";
    } else {
        ret_str += "}'";
    }
    return ret_str;
}

string DataAffinity::mutate_affi_collate() {
    return this->get_rand_collation_str();
}

string DataAffinity::mutate_affi_bool() {
    if(get_rand_int(2)) {
        return "true";
    } else {
        return "false";
    }
}

string DataAffinity::mutate_affi_onoff(){
    if(get_rand_int(2)) {
        return "on";
    } else {
        return "off";
    }
};

string DataAffinity::mutate_affi_onoffauto(){
    int choice = get_rand_int(3);
    if(choice == 0) {
        return "on";
    } else if (choice == 1){
        return "off";
    } else {
        return "auto";
    }
};

string DataAffinity::mutate_affi_bit() {
    string ret_str = "B'";

    int length = get_rand_int(17) + 1; // do not use 0;
    for (int i = 0; i < length; i++) {
        if(get_rand_int(2)) {
            ret_str += "1";
        } else {
            ret_str += "0";
        }
    }
    ret_str += "'";

    return ret_str;
};

string DataAffinity::mutate_affi_byte(){

    string ret_str = "b'";

    int len = get_rand_int(16) + 1; // Do not use len == 0;

    int format_choice = get_rand_int(4);
    switch (format_choice) {
        case 0:
            // b'abc'
            for (int i = 0; i < len; i++) {
                ret_str += char(get_rand_int(256));
            }
            break;
        case 1:
            // b'\141\142\143'
            for (int i = 0; i < len; i++) {
                ret_str += "\\" + to_string(get_rand_int(256));
            }
            break;
        case 2:
            // b'\x61\x62\x63'
            for (int i = 0; i < len; i++) {
                ret_str += "\\x" + get_rand_hex_num() + get_rand_hex_num();
            }
            break;
        case 3:
            // b'00001111'
            len = get_rand_int(3) + 1; // use a shorter length
            for (int i = 0; i < len; i++) {
                if(get_rand_int(2)) {
                    ret_str += "1";
                } else {
                    ret_str += "0";
                }
            }
            break;
    }

    ret_str += "'";
    return ret_str;
};

string DataAffinity::mutate_affi_jsonb(){
    // May not be able to control the content inside the JSON.
    int jsonDepth = 1;
    string ret_str = "'" + generateRandomJson(1).dump() + "'";
    return ret_str;
};

string DataAffinity::mutate_affi_interval(){

    string ret_str = "";

    int second = get_rand_int(60);
    int min = get_rand_int(60);
    int hour = get_rand_int(24);
    int day = get_rand_int(31);
    int month = get_rand_int(12);
    int year = get_rand_int(10); // 10 years range?

    int format = get_rand_int(5);

    // Second.
    switch(format) {
        case 0:
            // INTERVAL '2h30m30s'
            ret_str += to_string(second) + "s";
            break;
        case 1:
            // INTERVAL 'Y-M D H:M:S'
            ret_str += to_string(second);
            break;
        case 2:
            // INTERVAL 'P1Y2M3DT4H5M6S'
            ret_str += to_string(second) + "S";
            break;
        case 3:
            // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'
            ret_str += to_string(second) + " seconds";
            break;
        case 4:
            // INTERVAL '1 yr 2 mons 3 d 4 hrs 5 mins 6 secs'
            ret_str += to_string(second) + " secs";
            break;
    }

    if (get_rand_int(5) == 0) {
        // 80% chance, ignore the rest.
        goto interval_early_break;
    }

    // Mins.
    switch(format) {
        case 0:
            // INTERVAL '2h30m30s'
            ret_str = to_string(min) + "m" + ret_str;
            break;
        case 1:
            // INTERVAL 'Y-M D H:M:S'
            ret_str = to_string(min) + ":" + ret_str;
            break;
        case 2:
            // INTERVAL 'P1Y2M3DT4H5M6S'
            ret_str = to_string(min) + "M" + ret_str;
            break;
        case 3:
            // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'
            ret_str = to_string(min) + " minutes " + ret_str;
            break;
        case 4:
            // INTERVAL '1 yr 2 mons 3 d 4 hrs 5 mins 6 secs'
            ret_str = to_string(min) + " mins " + ret_str;
            break;
    }

    if (get_rand_int(5) == 0) {
        // 80% chance, ignore the rest.
        goto interval_early_break;
    }


    // Hour.
    switch(format) {
        case 0:
            // INTERVAL '2h30m30s'
            ret_str = to_string(hour) + "h" + ret_str;
            break;
        case 1:
            // INTERVAL 'Y-M D H:M:S'
            ret_str = to_string(hour) + ":" + ret_str;
            break;
        case 2:
            // INTERVAL 'P1Y2M3DT4H5M6S'
            ret_str = to_string(hour) + "H" + ret_str;
            break;
        case 3:
            // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'
            ret_str = to_string(hour) + " hours " + ret_str;
            break;
        case 4:
            // INTERVAL '1 yr 2 mons 3 d 4 hrs 5 mins 6 secs'
            ret_str = to_string(min) + " hrs " + ret_str;
            break;
    }

    if (get_rand_int(5) == 0) {
        // 80% chance, ignore the rest.
        goto interval_early_break;
    }


    // Day.
    switch(format) {
        case 0:
            // INTERVAL '2h30m30s'
            break;
        case 1:
            // INTERVAL 'Y-M D H:M:S'
            ret_str = to_string(day) + " " + ret_str;
            break;
        case 2:
            // INTERVAL 'P1Y2M3DT4H5M6S'
            ret_str = to_string(day) + "DT" + ret_str;
            break;
        case 3:
            // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'
            ret_str = to_string(day) + " days " + ret_str;
            break;
        case 4:
            // INTERVAL '1 yr 2 mons 3 d 4 hrs 5 mins 6 secs'
            ret_str = to_string(day) + " d " + ret_str;
            break;
    }

    if (get_rand_int(5) == 0) {
        // 80% chance, ignore the rest.
        goto interval_early_break;
    }

    // Month.
    switch(format) {
        case 0:
            // INTERVAL '2h30m30s'
            break;
        case 1:
            // INTERVAL 'Y-M D H:M:S'
            ret_str = to_string(month) + " " + ret_str;
            break;
        case 2:
            // INTERVAL 'P1Y2M3DT4H5M6S'
            ret_str = to_string(month) + "M" + ret_str;
            break;
        case 3:
            // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'
            ret_str = to_string(month) + " months " + ret_str;
            break;
        case 4:
            // INTERVAL '1 yr 2 mons 3 d 4 hrs 5 mins 6 secs'
            ret_str = to_string(month) + " mons " + ret_str;
            break;
    }

    if (get_rand_int(5) == 0) {
        // 80% chance, ignore the rest.
        goto interval_early_break;
    }


    // year.
    switch(format) {
        case 0:
            // INTERVAL '2h30m30s'
            break;
        case 1:
            // INTERVAL 'Y-M D H:M:S'
            ret_str = to_string(year) + "-" + ret_str;
            break;
        case 2:
            // INTERVAL 'P1Y2M3DT4H5M6S'
            ret_str = to_string(year) + "Y" + ret_str;
            break;
        case 3:
            // INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6 seconds'
            ret_str = to_string(year) + " years " + ret_str;
            break;
        case 4:
            // INTERVAL '1 yr 2 mons 3 d 4 hrs 5 mins 6 secs'
            ret_str = to_string(year) + " yr " + ret_str;
            break;
    }

    if (get_rand_int(5) == 0) {
        // 80% chance, ignore the rest.
        goto interval_early_break;
    }

interval_early_break:
    if (format == 2) {
        ret_str = "'P" + ret_str + "'";
    } else {
        ret_str = "'" + ret_str + "'";
    }

    return ret_str;
};

string DataAffinity::mutate_affi_intervaltz() {
    string ret_str = "";

    // get timestamp prefix.
    ret_str = mutate_affi_interval();
    ret_str = ret_str.substr(1,ret_str.size()-2); // Remove the `'` symbol.

    ret_str += add_random_time_zone();

    ret_str = "'" + ret_str + "'";
    return ret_str;
}

string DataAffinity::mutate_affi_date(){

    int format = get_rand_int(10);
    int abbr_year = get_rand_int(2);
    string ret_str = "";

    int month = get_rand_int(12)+1;
    string month_str = "";
    if (month < 10) {
        month_str = "0" + to_string(month);
    } else {
        month_str = to_string(month);
    }

    int day = get_rand_int(32)+1;
    string day_str = "";
    if (day < 10) {
        day_str = "0" + to_string(day);
    } else {
        day_str = to_string(day);
    }

    // For year, do not use the 1980 begin line.
    // range 5000 years BC and AD.
    int year = get_rand_int(5001);
    string year_str = "";
    // Add padding 0.
    if (year < 10) {
        year_str = "000" + to_string(year);
    } else if (year < 100) {
        year_str = "00" + to_string(year);
    } else if (year < 1000) {
        year_str = "0" + to_string(year);
    } else {
        year_str = to_string(year);
    }

    if (get_rand_int(2)) {
        year_str = year_str.substr(2, 2);
    }

    // Always use the default format of the date.
    switch(format) {
        case 0 ... 9:
            // MM-DD-YYYY/YY (default)
            ret_str = month_str + "-" + day_str;
            ret_str += "-" + year_str;
            break;
//        case 9:
//            // YYYY-MM-DD
//            ret_str = year_str; // FIXME:: Could miss prefix `0`s.
//            ret_str += "-" + month_str + "-" + day_str;
//            break;
    }

    if (get_rand_int(2)) {
        ret_str = "'" + ret_str + "'";
    } else {
        // Add BC
        ret_str = "'" + ret_str + " BC'";
    }

    return ret_str;
};

string DataAffinity::mutate_affi_timestamp(){

    string ret_str = "";

    // The date prefix is always necessary.
    ret_str = mutate_affi_date();
    ret_str = ret_str.substr(1,ret_str.size()-2); // Remove the `'` symbol.
    ret_str += " "; // Added whitespace.

    // Format 05:40:00
    string tmp_affi_time = this->mutate_affi_time();
    tmp_affi_time = tmp_affi_time.substr(1, tmp_affi_time.size()-2);
    ret_str += tmp_affi_time;

    ret_str = "'" + ret_str + "'";
    return ret_str;
};

string DataAffinity::add_random_time_zone() {
    string ret_str = "";
    if(get_rand_int(2) == 0) {
        ret_str += "+" + to_string(get_rand_int(13));
    } else {
        ret_str += "-" + to_string(get_rand_int(13));
    }
    // Do not add the `'` symbol.
    return ret_str;
}

string DataAffinity::mutate_affi_timestamptz(){
    string ret_str = "";

    // get timestamp prefix.
    ret_str = mutate_affi_timestamp();
    ret_str = ret_str.substr(1,ret_str.size()-2); // Remove the `'` symbol.

    ret_str += add_random_time_zone();

    ret_str = "'" + ret_str + "'";
    return ret_str;
};

string DataAffinity::mutate_affi_uuid(){

    int format = get_rand_int(2);
    string ret_str = "";

    if (format == 0) {
        // Hyphen-separated groups of 8, 4, 4, 4, and 12 hexadecimal digits.
        // Example: acde070d-8c4c-4f0d-9d8a-162843c10333
        for (int i = 0; i < 32; i++) {
//            cerr << "\n" << ret_str << "\n";
            if (i == 8 || i == 12 || i == 16 || i == 20) {
                ret_str += "-";
            }
            ret_str += get_rand_hex_num();
        }
        ret_str = "'" + ret_str + "'";
    } else {
        // UUID value specified as a BYTES value.
        // b'kafef00ddeadbeed'
        for (int i = 0; i < 16; i++) {
            ret_str += get_rand_hex_num();
        }
        ret_str = "b'" + ret_str + "'";
    }

//    cerr << "\n\n\nmutate uuid: " << ret_str << "\n\n\n";
    return ret_str;
};

string DataAffinity::mutate_affi_enum(){

    string ret_str = "";
    if (this->v_enum_str.size() > 0) {
        ret_str = vector_rand_ele(this->v_enum_str);
    }

    ret_str = "'" + ret_str + "'";
    return ret_str;
};

string DataAffinity::mutate_affi_inet(){

    string ret_str = "";
    int format = get_rand_int(3);

    if (format == 0) {
        // ipv 4.
        // Typical ipv4 address.
        switch (get_rand_int(6)) {
            case 0:
                ret_str = "192.168.0.0/24";
                break;
            case 1:
                ret_str = "192.168.0.1";
                break;
            case 2:
                ret_str = "172.0.0.0/8"; // loopback
                break;
            case 3:
                ret_str = "169.254.0.0/16"; // link local
                break;
            case 4:
                ret_str = "127.0.0.1"; // localhost
                break;
            case 5:
                ret_str = "127.0.0.1/26257"; // localhost to CockroachDB/PostgreSQL port.
                break;
        }
    } else if (format == 1) {
        // Random IPV4 address.
        for (int i = 0; i < 4; i++ ) {
            if (i > 0) {
                ret_str += ".";
            }
            ret_str += to_string(get_rand_int(256));
        }
    } else {
        // Random ipv 6 address.
        // Example: 2001:db88:3333:4444:5555:6666:7777:8888
        for (int i = 0; i < 32; i++) {
            if ((i % 4) == 0 && i != 0) {
                ret_str += ":";
            }
            ret_str += get_rand_hex_num();
        }
    }
    ret_str = "'" + ret_str + "'";
    return ret_str;
};

string DataAffinity::mutate_affi_time(){

    string ret_str = "";

    // Format 05:40:00
    int hours = get_rand_int(24);
    string hours_str = "";
    if (hours < 10) {
        hours_str = "0" + to_string(hours);
    } else {
        hours_str = to_string(hours);
    }

    int mins = get_rand_int(60);
    string mins_str = "";
    if (mins < 10) {
        mins_str = "0" + to_string(mins);
    } else {
        mins_str = to_string(mins);
    }

    int secs = get_rand_int(60);
    string secs_str = "";
    if (secs < 10) {
        secs_str = "0" + to_string(secs);
    } else {
        secs_str = to_string(secs);
    }

    ret_str += hours_str;
    ret_str += ":";
    ret_str += mins_str;
    ret_str += ":";
    ret_str += secs_str;

    // Optional microsecond precision. HH:MM:SS.SSSSSS
    if (get_rand_int(2) < 1) {
        // Append 4 digits microsecond precision.
        ret_str += ".";
        ret_str += to_string(get_rand_int(10));
        ret_str += to_string(get_rand_int(10));
        ret_str += to_string(get_rand_int(10));
        ret_str += to_string(get_rand_int(10));
    }

    ret_str = "'" + ret_str + "'";
    return ret_str;
};

string DataAffinity::mutate_affi_timetz(){

    string ret_str = this->mutate_affi_time();
    ret_str = ret_str.substr(1,ret_str.size()-2); // Remove the `'` symbol.

    ret_str += this->add_random_time_zone();

    ret_str = "'" + ret_str + "'";
    return ret_str;
};

string DataAffinity::mutate_affi_string(){
    /* This function is not a complete mutation function.
    // This function will generate a complete new string literals,
    //    regardless of its types (i.e., the mutation function can
    //    generate any string types data. )
    // Or, it can generate a complete random ASCII string.
    */

    int format = get_rand_int(12);
    string ret_str = "";

    // Handle the `'` symbol in the switch.
    switch(format) {
        case 0 ... 2: {
            // Complete random string.
            int len = get_rand_int(10) + 1; // Doesn't need to be long. Avoid 0 len.
            for (int i = 0; i < len; i++) {
                char cch = char(get_rand_int(256));
                string tmp_cch_str = string(1, cch);
                ret_str += tmp_cch_str;
            }
            ret_str = "'" + ret_str + "'";
            break;
        }
//        case 1:
//            // affinity bit type
//            ret_str = this->mutate_affi_bit();
//            break;
//        case 2:
//            // affinity byte type
//            ret_str = this->mutate_affi_byte();
//            break;
        case 3:
            // affinity json type
            ret_str = this->mutate_affi_jsonb();
            break;
        case 4:
            // affinity interval type
            ret_str = this->mutate_affi_interval();
            break;
        case 5:
            // affinity date type
            ret_str = this->mutate_affi_date();
            break;
        case 6:
            // affinity timestamp type
            ret_str = this->mutate_affi_timestamp();
            break;
        case 7:
            // affinity timestamptz type
            ret_str = this->mutate_affi_timestamptz();
            break;
        case 8:
            // affinity uuid type
            ret_str = this->mutate_affi_uuid();
            break;
        case 9:
            // affinity inet type
            ret_str = this->mutate_affi_inet();
            break;
        case 10:
            // affinity time type
            ret_str = this->mutate_affi_time();
            break;
        case 11:
            // affinity timetz type
            ret_str = this->mutate_affi_timetz();
            break;
//        case 13:
//            // Use Affinity Array type;
//            ret_str = this->mutate_affi_array();
//            break;
    }

    return ret_str;
};

/* Spatial types mutation */

//string DataAffinity::mutate_affi_box2d() {
//
//}

//string DataAffinity::mutate_affi_void();
//string DataAffinity::mutate_affi_point();
//string DataAffinity::mutate_affi_linestring();
//string DataAffinity::mutate_affi_polygon();
//string DataAffinity::mutate_affi_multipoint();
//string DataAffinity::mutate_affi_multilinestring();
//string DataAffinity::mutate_affi_multipolygon();
//string DataAffinity::mutate_affi_geometrycollection();

string DataAffinity::get_mutated_literal(DATAAFFINITYTYPE type_in) {

    DATAAFFINITYTYPE cur_affi = type_in;
    if (cur_affi == AFFIUNKNOWN) {
        cur_affi = this->data_affinity;
    }

    switch (cur_affi) {
        case AFFIUNKNOWN:
            cerr << "In DataAffinity::get_mutated_literal, getting AFIUNKNOWN. \n";
//            abort();
            return this->mutate_affi_string();

        case AFFISERIAL:
            // [[fallthrough]]
        case AFFIINT:
            return this->mutate_affi_int();

        case AFFIFLOAT:
            //[[fallthrough]];
        case AFFIDECIMAL:
            return this->mutate_affi_float();

        case AFFIINET:
            return this->mutate_affi_inet();
        case AFFICOLLATE:
            return this->mutate_affi_collate();
        case AFFIBOOL:
            return this->mutate_affi_bool();
        case AFFIBIT:
            return this->mutate_affi_bit();
        case AFFIBYTES:
            return this->mutate_affi_byte();
        case AFFIJSONB:
            return this->mutate_affi_jsonb();
        case AFFIINTERVAL:
            return this->mutate_affi_interval();
        case AFFIINTERVALTZ:
            return this->mutate_affi_intervaltz();
        case AFFIDATE:
            return this->mutate_affi_date();
        case AFFITIMESTAMP:
            return this->mutate_affi_timestamp();
        case AFFITIMESTAMPTZ:
            return this->mutate_affi_timestamptz();
        case AFFIUUID:
            return this->mutate_affi_uuid();
        case AFFIENUM:
            return this->mutate_affi_enum();
        case AFFITIME:
            return this->mutate_affi_time();
        case AFFITIMETZ:
            return this->mutate_affi_timetz();
        case AFFISTRING:
            return this->mutate_affi_string();
        case AFFIONOFF:
            return this->mutate_affi_onoff();
        case AFFIONOFFAUTO:
            return this->mutate_affi_onoffauto();
        case AFFIOID:
            return this->mutate_affi_oid();
        default:
            // For other types, should be collate.
            return this->mutate_affi_array();
    }
}

string DataAffinity::get_rand_alphabet_num() {
    // no capital letters;
    // Pure helper function for random mutations.
    int rand_int = get_rand_int(36);
    if (rand_int >= 26) {
//        cerr << "\nDebug: Getting rand_alphabet (number): " << rand_int << ":" << to_string(rand_int-26) << "\n";
        return to_string(rand_int-26);
    } else {
        char cch = 'a' + rand_int;
        string ret_str(1, cch);
//        cerr << "\nDebug: Getting rand_alphabet (letter): " << rand_int << ":" << ret_str << "\n";
        return ret_str;
    }
}

string DataAffinity::get_rand_hex_num() {
    // no capital letters;
    // Pure helper function for random mutations.
    int rand_int = get_rand_int(16);
    if (rand_int < 10) {
//        cerr << "\nDebug: Getting rand_alphabet (number): " << rand_int << ":" << to_string(rand_int-26) << "\n";
        return to_string(rand_int);
    } else {
        char cch = 'a' + (rand_int - 10);
        string ret_str(1, cch);
//        cerr << "\nDebug: Getting rand_alphabet (letter): " << rand_int << ":" << ret_str << "\n";
        return ret_str;
    }
}

DATAAFFINITYTYPE DataAffinity::transfer_array_to_normal_type(DATAAFFINITYTYPE in_type) {
    switch(in_type) {
        case AFFIARRAYUNKNOWN:
            return AFFIUNKNOWN;
        case AFFIARRAYBIT:
            return AFFIBIT;
        case AFFIARRAYBOOL:
            return AFFIBOOL;
        case AFFIARRAYBYTES:
            return AFFIBYTES;
        case AFFIARRAYCOLLATE:
            return AFFICOLLATE;
        case AFFIARRAYDATE:
            return AFFIDATE;
        case AFFIARRAYENUM:
            return AFFIENUM;
        case AFFIARRAYDECIMAL:
            return AFFIDECIMAL;
        case AFFIARRAYFLOAT:
            return AFFIFLOAT;
        case AFFIARRAYINET:
            return AFFIINET;
        case AFFIARRAYINT:
            return AFFIINT;
        case AFFIARRAYINTERVAL:
            return AFFIINTERVAL;
        case AFFIARRAYJSONB:
            return AFFIJSONB;
        case AFFIARRAYOID:
            return AFFIOID;
        case AFFIARRAYSERIAL:
            return AFFISERIAL;
        case AFFIARRAYSTRING:
            return AFFISTRING;
        case AFFIARRAYTIME:
            return AFFITIME;
        case AFFIARRAYTIMETZ:
            return AFFITIMETZ;
        case AFFIARRAYTIMESTAMP:
            return AFFITIMESTAMP;
        case AFFIARRAYTIMESTAMPTZ:
            return AFFITIMESTAMPTZ;
        case AFFIARRAYUUID:
            return AFFIUUID;
        case AFFIARRAYGEOGRAPHY:
            return AFFIGEOGRAPHY;
        case AFFIARRAYGEOMETRY:
            return AFFIGEOMETRY;
        case AFFIARRAYBOX2D:
            return AFFIBOX2D;
        case AFFIARRAYVOID:
            return AFFIVOID;
        case AFFIARRAYPOINT:
            return AFFIPOINT;
        case AFFIARRAYLINESTRING:
            return AFFILINESTRING;
        case AFFIARRAYPOLYGON:
            return AFFIPOLYGON;
        case AFFIARRAYMULTIPOINT:
            return AFFIMULTIPOINT;
        case AFFIARRAYMULTILINESTRING:
            return AFFIMULTILINESTRING;
        case AFFIARRAYMULTIPOLYGON:
            return AFFIMULTIPOLYGON;
        case AFFIARRAYGEOMETRYCOLLECTION:
            return AFFIGEOMETRYCOLLECTION;
        case AFFIARRAYOIDWRAPPER:
            return AFFIOIDWRAPPER;
        case AFFIARRAYWHOLESTMT:
            return AFFIWHOLESTMT;
        case AFFIARRAYONOFF:
            return AFFIONOFF;
        case AFFIARRAYONOFFAUTO:
            return AFFIONOFFAUTO;
        default:
            return AFFISTRING;
    }
    return AFFIUNKNOWN;
}

DATAAFFINITYTYPE get_random_affinity_type(bool is_basic_type_only, bool is_no_array) {

    if (is_basic_type_only) {

        if (is_no_array || get_rand_int(10) < 9) {
            // Basic type except for Array.
            auto random_affi_idx = get_rand_int(AFFIUUID - AFFIBIT) + AFFIBIT; // Avoid AFFIUNKNOWN;
            auto random_affi = static_cast<DATAAFFINITYTYPE>(random_affi_idx);

            if (random_affi == AFFIINTERVALTZ) {
                return AFFIINTERVAL;
            }

            if (random_affi != AFFICOLLATE && random_affi != AFFIENUM) {
                return random_affi;
            } else {
                return AFFISTRING;
            }
        } else {
            // Basic ARRAY type. 1/10 chances to get ARRAY type.
            auto random_affi_idx = get_rand_int(AFFIARRAYUUID - AFFIARRAYBIT) + AFFIARRAYBIT + 1; // Avoid AFFIARRAYUNKNOWN;
            auto random_affi = static_cast<DATAAFFINITYTYPE>(random_affi_idx);

            if (random_affi != AFFIARRAYENUM && random_affi != AFFIARRAYCOLLATE) {
                return random_affi;
            } else {
                return AFFISTRING;
            }
        }

    } else {

        auto random_affi_idx = get_rand_int(DATAAFFINITYTYPE::AFFIELEMENTCOUNT - 1) + 1; // Avoid AFFIUNKNOWN;
        auto random_affi = static_cast<DATAAFFINITYTYPE>(random_affi_idx);
        return random_affi;
    }
}

string get_random_affinity_type_str(bool is_basic_type_only) {
    auto random_affi = get_random_affinity_type();
    return get_string_by_affinity_type(random_affi);
}

string get_random_affinity_type_str_formal(bool is_basic_type_only) {
    auto rand_type = get_random_affinity_type();
    return get_affinity_type_str_formal(rand_type);
}

string get_affinity_type_str_formal(DATAAFFINITYTYPE type_in) {

    string type_str = get_string_by_affinity_type(type_in);

    type_str = type_str.substr(4, type_str.size()-4);

    /* Dirty fix for the INTERVALTZ type. */
    if (type_str == "INTERVALTZ") {
        type_str = "INTERVAL";
    } else if (type_str == "ARRAYINTERVALTZ") {
        type_str = "ARRAYINTERVAL";
    } else if (type_str == "ANY") {
        type_str = "STRING";
    } else if (type_str == "ARRAYANY") {
        type_str = "STRING[]";
    }

    string ori_str = type_str;

    if (type_str.size() > 5 && type_str.substr(0, 5) == "ARRAY") {
        // This is an ARRAY type, need more handling of the formal representation.

        // Debug
//        cerr << "For type_str: " << type_str << ", assuming ARRAY type. \n\n\n";

        switch(get_rand_int(2)) {
            case 0: {
                // First format: example: c0 string[]
                type_str = type_str.substr(5, (type_str.size() - 5));
                type_str += "[]";
                break;
            }
            case 1: {
                // Second format: example: c0 INT ARRAY
                type_str = type_str.substr(5, (type_str.size() - 5));
                type_str += " ARRAY";
                break;
            }
        }
    }

    return type_str;
}