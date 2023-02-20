#include "../header/utils.h"

// From https://stackoverflow.com/questions/14265581/parse-split-a-string-in-c-using-string-delimiter-standard-c
vector<string> string_splitter(const string& in, string delimiter) {

  vector<string> ret;
  string s = in;

  size_t pos = 0;
  string token;
  while ((pos = s.find(delimiter)) != std::string::npos) {
    token = s.substr(0, pos);
    ret.push_back(token);
    s.erase(0, pos + delimiter.length());
  }
  ret.push_back(s);

  return ret;
}
