## 3.1.3
- Added support for compiling on gcc 4.8.5
- Disabled helper bytes literal operators for gcc < 5 (didn't tested on other compilers)
- Using boost if compiler does not support regex
- Added strings methods for replacing string vector with just one string (old substr_replace_all supports it too, but second argument should be a vector with 1 element):
  - `void substr_replace_all(const std::vector<std::string>, const std::string&, std::string&)`
  - `std::string substr_replace_all_ret(const std::vector<std::string>, const std::string&, const std::string&)`

## 3.1.2
- Added support for compiling on gcc 4.9
- Added strings `trim` and `trim_ref` methods to remove characters "\t\n\r\x0B"
- Added generating pc.in file