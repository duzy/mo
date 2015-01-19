#include "parser.h"

int main() {
    auto stmts = lab::parse_file("00.lab");
    std::clog<<"stmts: "<<stmts.size()<<std::endl;
    for (auto stmt : stmts) {
        
    }
    return 0;
}
