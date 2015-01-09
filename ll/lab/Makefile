CFLAGS := 
CXXFLAGS := -std=c++11

main: main.o
	$(LINK.cc) -o $@ $<

main.o: main.cpp parser.h

%.o: %.cpp
	$(COMPILE.cc) $< -o $@

