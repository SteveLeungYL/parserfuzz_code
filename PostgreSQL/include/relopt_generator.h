#ifndef RELOPT_GENERATOR_H_
#define RELOPT_GENERATOR_H_

#include <utility>
#include <string>

using namespace std;

#define INT_MAX 2147483647

enum RelOptionType {
StorageParameters,
SetConfigurationOptions,
};

class RelOptionGenerator {

public:
    static pair<string, string> get_rel_option_pair(RelOptionType);

private:
    static pair<string, string> get_rel_option_storage_parameters();
    static pair<string, string> get_rel_option_set_configuration_options();

};

#endif // RELOPT_GENERATOR_H_
