#ifndef SRC_RAND_JSON_GENERATOR_H
#define SRC_RAND_JSON_GENERATOR_H

#include "json.hpp"
#include<iostream>
#include<random>
#define MAX_STRING_LENGTH 10
#define MAXIMUM_KEYS 7
#define MINIMUM_KEYS 4
#define MAX_JSON_DEPTH 4
#define MAX_VALUE_RANDOM_INTEGER 50
#define MIN_VALUE_RANDOM_INTEGER 5
#define MAX_VECTOR_LENGTH 9
/**Different value types for keys of JSON*/
#define BOOLEAN 0
#define INTEGER 1
#define STRING 2
#define VECTOR 3
#define JSON 4
#define INCLUDE_JSON 0,4
#define EXCLUDE_JSON 0,3
#define INTEGER_TYPE 1

using json = nlohmann::json;
using namespace std;
/**String of characters to generate random string*/
const string CHARACTERS =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
/** Used to generate uniformly distributed random number*/
random_device rd;
/**Random number engine*/
mt19937 generator(rd());
/**Important Function Declaration*/
json generateRandomJson(int);
int generateRandomIntegerWithRange(int,int);
int assignValueTypeToJsonKey(int);
void assignKeyValuePairToJson(int,json &,int);
uniform_int_distribution<int> generateUniformDistributionWithRange
        (int lowerBound,int upperBound) {
    /**Uniformly distributed random integer generator between
       two bounds*/
    uniform_int_distribution<int> distribution(lowerBound,upperBound);
    return distribution;
}
/**This function generates a random integer between two numbers */
int generateRandomIntegerWithRange(int lowerBound, int upperBound) {
    return generateUniformDistributionWithRange(lowerBound,
                                                upperBound)(generator);
}
string generateRandomString() {
    string randomString;
    /**This variable stores the random value of length of string*/
    int randomLength =
            generateRandomIntegerWithRange(1,MAX_STRING_LENGTH);
    /**This variable stores the generator used to generate
       random number between two values*/
    uniform_int_distribution<int> characterDistribution =
            generateUniformDistributionWithRange(0,CHARACTERS.size()-1);
    for(int index = 0; index < randomLength; index++) {
        /**Each iteration adds a random character to string
           using global string CHARACTERS*/
        randomString+= CHARACTERS[characterDistribution(generator)];
    }
    return randomString;
}
bool generateRandomBoolean() {
    if(generateRandomIntegerWithRange(0,1)){
        return true;
    }
    return false;
}
int generateRandomInteger(){
    return
            generateRandomIntegerWithRange(MIN_VALUE_RANDOM_INTEGER,
                                           MAX_VALUE_RANDOM_INTEGER);
}
int getRandomVectorLength() {
    return generateRandomIntegerWithRange(1,MAX_VECTOR_LENGTH);
}
vector<int> generateRandomIntegerVector() {
    vector<int> v;
    int vectorLength = getRandomVectorLength();
    for(int index=0; index < vectorLength ; index++){
        v.push_back(generateRandomInteger());
    }
    return v;
}
vector<string> generateRandomStringVector(){
    vector<string> v;
    int vectorLength = getRandomVectorLength();
    for(int index=0; index < vectorLength ; index++){
        v.push_back(generateRandomString());
    }
    return v;
}
/**This function returns a random integer that determines the value type
  ( example : boolean, integer etc )for a key */
int assignValueTypeToJsonKey(int jsonDepth)
{
    int valueType;
    /**If this condition is true, then JSON object cannot be
       value type*/
    if(jsonDepth > MAX_JSON_DEPTH){
        valueType = generateRandomIntegerWithRange(EXCLUDE_JSON);
    }
    else{
        valueType = generateRandomIntegerWithRange(INCLUDE_JSON);
    }
    return valueType;
}
/**This function generates either 0 or 1.
   If 0 is generated, then vector value type is integer.
   Otherwise vector value type is string*/
bool getVectorType(){
    return generateRandomBoolean();
}
/**This function generates key value pair for JSON*/
void assignKeyValuePairToJson(int valueType,json &t, int jsonDepth){
    if(valueType==BOOLEAN){
        t[generateRandomString()]=generateRandomBoolean();
    }
    else if(valueType==INTEGER){
        t[generateRandomString()]=generateRandomInteger();
    }
    else if(valueType==STRING){
        t[generateRandomString()]=generateRandomString();
    }
    else if(valueType==VECTOR){
        bool vectorType = getVectorType();
        if(vectorType == INTEGER_TYPE){
            t[generateRandomString()]=generateRandomIntegerVector();
        }
        else{
            t[generateRandomString()]=generateRandomStringVector();
        }
    }
    else{
        /**When a value type is another JSON object, then we
           increase the jsonDepth variable by one.
           This is because we are creating another JSON object as a
           value for a key inside the present JSON object */
        t[generateRandomString()]=generateRandomJson(jsonDepth+1);
    }
}
/** This function generates the JSON object */
json generateRandomJson(int jsonDepth) {
    json t;
    int numberOfKeys =
            generateRandomIntegerWithRange(MINIMUM_KEYS,
                                           MAXIMUM_KEYS);
    for(int index =0;index < numberOfKeys; index++){
        /**This variable stores what value type
           ( example : boolean, integer etc ) will the key store */
        int valueType = assignValueTypeToJsonKey(jsonDepth);
        /**This function call generates the key value pair
           inside JSON object */
        assignKeyValuePairToJson(valueType,t,jsonDepth);
    }
    return t;
}

#undef MAX_STRING_LENGTH
#undef MAXIMUM_KEYS
#undef MINIMUM_KEYS
#undef MAX_JSON_DEPTH
#undef MAX_VALUE_RANDOM_INTEGER
#undef MIN_VALUE_RANDOM_INTEGER
#undef MAX_VECTOR_LENGTH
/**Different value types for keys of JSON*/
#undef BOOLEAN
#undef INTEGER
#undef STRING
#undef VECTOR
#undef JSON
#undef INCLUDE_JSON
#undef EXCLUDE_JSON
#undef INTEGER_TYPE

#endif //SRC_DATA_AFFINITY_H
