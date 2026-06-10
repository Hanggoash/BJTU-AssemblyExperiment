CXX := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -O0

TARGET := matmul_test
SOURCES := main.cpp Matrix.cpp matmul_basic.s matmul_unroll.s matmul_addr.s matmul_neon.s

.PHONY: all clean run

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CXX) $(CXXFLAGS) $(SOURCES) -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) matmul_case_*_input.txt matmul_case_*_answer.txt
