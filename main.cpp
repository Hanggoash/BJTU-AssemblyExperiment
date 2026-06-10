#include "Matrix.h"

#include <chrono>
#include <cstdlib>
#include <ctime>
#include <exception>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

using KernelFn = void (*)(const Matrix*, const Matrix*, Matrix*);

struct BenchmarkConfig {
    int a_rows;
    int a_cols;
    int b_rows;
    int b_cols;
    int low;
    int high;
};

void matmul_cpp_into(const Matrix& A, const Matrix& B, Matrix& C) {
    if (A.cols != B.rows) {
        throw std::invalid_argument("matrix dimensions do not match for multiplication");
    }
    if (C.rows != A.rows || C.cols != B.cols) {
        throw std::invalid_argument("output matrix dimensions do not match");
    }

    for (int i = 0; i < A.rows; ++i) {
        for (int j = 0; j < B.cols; ++j) {
            int sum = 0;
            for (int k = 0; k < A.cols; ++k) {
                sum += A(i, k) * B(k, j);
            }
            C(i, j) = sum;
        }
    }
}

void write_matrix(std::ofstream& output, const std::string& name, const Matrix& matrix) {
    output << name << '\n';
    output << matrix.rows << ' ' << matrix.cols << '\n';
    for (int i = 0; i < matrix.rows; ++i) {
        for (int j = 0; j < matrix.cols; ++j) {
            output << matrix(i, j);
            if (j + 1 < matrix.cols) {
                output << ' ';
            }
        }
        output << '\n';
    }
    output << '\n';
}

void save_case_files(int case_index, const BenchmarkConfig& config, const Matrix& A, const Matrix& B, const Matrix& C) {
    const std::string prefix = "matmul_case_" + std::to_string(case_index);
    const std::string input_file = prefix + "_input.txt";
    const std::string answer_file = prefix + "_answer.txt";

    std::ofstream input_output(input_file);
    if (!input_output) {
        throw std::runtime_error("failed to create input file: " + input_file);
    }
    input_output << "random_range " << config.low << ' ' << config.high << "\n\n";
    write_matrix(input_output, "A", A);
    write_matrix(input_output, "B", B);

    std::ofstream answer_output(answer_file);
    if (!answer_output) {
        throw std::runtime_error("failed to create answer file: " + answer_file);
    }
    write_matrix(answer_output, "C_cpp", C);

    std::cout << "Saved input matrix file: " << input_file << '\n';
    std::cout << "Saved reference file: " << answer_file << '\n';
}

double time_cpp(const Matrix& A, const Matrix& B, Matrix& C, int repetitions) {
    volatile int sink = 0;
    const auto start = std::chrono::steady_clock::now();
    for (int i = 0; i < repetitions; ++i) {
        matmul_cpp_into(A, B, C);
        sink += C.data[i % (C.rows * C.cols)];
    }
    const auto end = std::chrono::steady_clock::now();
    (void)sink;
    return std::chrono::duration<double, std::milli>(end - start).count() / repetitions;
}

double time_kernel(const Matrix& A, const Matrix& B, Matrix& C, int repetitions, KernelFn kernel) {
    volatile int sink = 0;
    const auto start = std::chrono::steady_clock::now();
    for (int i = 0; i < repetitions; ++i) {
        kernel(&A, &B, &C);
        sink += C.data[i % (C.rows * C.cols)];
    }
    const auto end = std::chrono::steady_clock::now();
    (void)sink;
    return std::chrono::duration<double, std::milli>(end - start).count() / repetitions;
}

double time_asm_neon_total(const Matrix& A, const Matrix& B, Matrix& C, int repetitions) {
    volatile int sink = 0;
    const auto start = std::chrono::steady_clock::now();
    for (int i = 0; i < repetitions; ++i) {
        Matrix BT = B.transpose();
        matmul_asm_neon(&A, &BT, &C);
        sink += C.data[i % (C.rows * C.cols)];
    }
    const auto end = std::chrono::steady_clock::now();
    (void)sink;
    return std::chrono::duration<double, std::milli>(end - start).count() / repetitions;
}

int pick_repetitions(const BenchmarkConfig& config) {
    const long long operations = static_cast<long long>(config.a_rows) * config.a_cols * config.b_cols;

    if (operations <= 32LL * 32 * 32) {
        return 40;
    }
    if (operations <= 64LL * 64 * 64) {
        return 12;
    }
    if (operations <= 128LL * 128 * 128) {
        return 4;
    }
    return 1;
}

void print_time_line(const std::string& label, double ms, bool correct) {
    std::cout << std::left << std::setw(18) << label << std::right << std::setw(10)
              << std::fixed << std::setprecision(3) << ms << " ms"
              << "    " << (correct ? "Correct" : "Wrong") << '\n';
}

void run_benchmark_case(const BenchmarkConfig& config, int case_index) {
    if (config.a_cols != config.b_rows) {
        throw std::invalid_argument("A.cols must equal B.rows");
    }
    if (config.low > config.high) {
        throw std::invalid_argument("random range low must be <= high");
    }

    Matrix A(config.a_rows, config.a_cols);
    Matrix B(config.b_rows, config.b_cols);
    A.randomFill(config.low, config.high);
    B.randomFill(config.low, config.high);

    Matrix C_cpp(config.a_rows, config.b_cols);
    matmul_cpp_into(A, B, C_cpp);
    save_case_files(case_index, config, A, B, C_cpp);

    Matrix C_cpp_timed(config.a_rows, config.b_cols);
    Matrix C_basic(config.a_rows, config.b_cols);
    Matrix C_unroll(config.a_rows, config.b_cols);
    Matrix C_addr(config.a_rows, config.b_cols);
    Matrix C_neon(config.a_rows, config.b_cols);

    const int repetitions = pick_repetitions(config);
    const double cpp_ms = time_cpp(A, B, C_cpp_timed, repetitions);
    const double basic_ms = time_kernel(A, B, C_basic, repetitions, matmul_asm_basic);
    const double unroll_ms = time_kernel(A, B, C_unroll, repetitions, matmul_asm_unroll);
    const double addr_ms = time_kernel(A, B, C_addr, repetitions, matmul_asm_addr);
    const double neon_ms = time_asm_neon_total(A, B, C_neon, repetitions);

    const bool cpp_ok = C_cpp.equals(C_cpp_timed);
    const bool basic_ok = C_cpp.equals(C_basic);
    const bool unroll_ok = C_cpp.equals(C_unroll);
    const bool addr_ok = C_cpp.equals(C_addr);
    const bool neon_ok = C_cpp.equals(C_neon);

    std::cout << "==================================================\n";
    std::cout << "Case: " << case_index << '\n';
    std::cout << "A: " << config.a_rows << " x " << config.a_cols
              << ", B: " << config.b_rows << " x " << config.b_cols << '\n';
    std::cout << "Random range: [" << config.low << ", " << config.high << "]\n";
    std::cout << "Repetitions: " << repetitions << "\n\n";

    print_time_line("C++ reference:", cpp_ms, cpp_ok);
    print_time_line("ASM basic:", basic_ms, basic_ok);
    print_time_line("ASM unroll:", unroll_ms, unroll_ok);
    print_time_line("ASM addr:", addr_ms, addr_ok);
    print_time_line("ASM neon:", neon_ms, neon_ok);

    std::cout << '\n';
    std::cout << "Speedup vs basic:\n";
    std::cout << "unroll: " << std::fixed << std::setprecision(2) << basic_ms / unroll_ms << "x\n";
    std::cout << "addr:   " << std::fixed << std::setprecision(2) << basic_ms / addr_ms << "x\n";
    std::cout << "neon:   " << std::fixed << std::setprecision(2) << basic_ms / neon_ms << "x\n";
    std::cout << "==================================================\n\n";
}

bool read_config(BenchmarkConfig& config) {
    std::cout << "Input A_rows A_cols B_rows B_cols low high (-1 to exit): ";
    if (!(std::cin >> config.a_rows)) {
        return false;
    }
    if (config.a_rows == -1) {
        return false;
    }
    if (!(std::cin >> config.a_cols >> config.b_rows >> config.b_cols >> config.low >> config.high)) {
        throw std::runtime_error("failed to read benchmark config from stdin");
    }
    return true;
}

}  // namespace

int main() {
    try {
        std::srand(static_cast<unsigned int>(std::time(nullptr)));

        int case_index = 1;
        BenchmarkConfig config{};
        while (read_config(config)) {
            run_benchmark_case(config, case_index);
            ++case_index;
        }

        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << '\n';
        return 1;
    }
}
