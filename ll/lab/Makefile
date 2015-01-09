CFLAGS := 
CXXFLAGS := -std=c++11

main: main.o
	$(LINK.cc) -o $@ $<

main.o:main.cpp

%.o: %.cpp
	$(COMPILE.cc) $< -o $@

