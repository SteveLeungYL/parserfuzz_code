#include "json_ir_convertor.h"
#include "json.hpp"

using json = nlohmann::json;

IR* covert_json_to_IR(string json_str) {
    auto json_obj = json::parse(json_str);

    auto tmpIR = new IR(kConstInterval, "whatever");
    return tmpIR;
}
