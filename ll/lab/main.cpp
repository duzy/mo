#include "parser.h"

int main() {
    lab::parser parser;
    auto ast = parser.parse("00.lab");
    return 0;
}
