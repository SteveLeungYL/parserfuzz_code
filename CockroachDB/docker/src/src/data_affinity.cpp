#include "../include/data_affinity.h"
#include "../include/utils.h"

#include <regex>
#include <float.h>
#include <math.h>

string get_string_by_affinity_type(DATAAFFINITYTYPE type) {
#define DECLARE_CASE(classname)                                                \
  if (type == classname)                                                       \
    return #classname;
    ALLDATAAFFINITY(DECLARE_CASE);
#undef DECLARE_CASE
    return "";
}

DATAAFFINITYTYPE get_data_affinity_by_string(string s) {
#define DECLARE_CASE(dataAffiname)                                             \
  if (s == #dataAffiname)                                                      \
    return dataAffiname;
    ALLDATAAFFINITY(DECLARE_CASE);
#undef DECLARE_CASE
    return AFFIUNKNOWN;
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
#define DECLARE_CASE(collationname) "collation_name",
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

    // Interval. (Not accurate.)
    regex interval_sim("^'(?:\\d+h)?(?:\\d+m)?\\d+s'$"); // INTERVAL '2h30m30s'
    // INTERVAL 'Y-M D H:M:S
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

    if (get_rand_int(3) < 1) { // 1/3 chance, choose special value.
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

    if (get_rand_int(3) < 1) { // 1/3 chance, choose special value.
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
        auto rand_int = get_rand_int(4294967295);
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

    return to_string(get_rand_double(DBL_MIN, DBL_MAX));
}

string DataAffinity::mutate_affi_array() {
    // TODO:: Need more editing.
    return "";
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

string DataAffinity::mutate_affi_bit() {
    // TODO:: Need more editing.
    return "";

};
string DataAffinity::mutate_affi_byte(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_jsonb(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_interval(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_date(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_timestamp(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_timestamptz(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_uuid(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_enum(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_inet(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_time(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_timetz(){
    // TODO:: Need more editing.
    return "";
};
string DataAffinity::mutate_affi_string(){
    // TODO:: Need more editing.
    return "";
};

string DataAffinity::get_mutated_literal() {
    switch (this->data_affinity) {
        case AFFIUNKNOWN:
            cerr << "In DataAffinity::get_mutated_literal, getting AFIUNKNOWN. \n";
            abort();

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
        case AFFIARRAY:
            return this->mutate_affi_array();
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
        default:
            return this->mutate_affi_string();
    }
}