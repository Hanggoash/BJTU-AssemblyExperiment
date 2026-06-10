#ifndef MATRIX_H
#define MATRIX_H

#include <cstddef>
#include <string>

class Matrix {
public:
    int rows;
    int cols;
    int* data;

    Matrix(int r, int c);
    Matrix(const Matrix& other);
    Matrix& operator=(const Matrix& other);
    ~Matrix();

    int& operator()(int i, int j);
    const int& operator()(int i, int j) const;

    void randomFill(int low, int high);
    void print() const;
    bool equals(const Matrix& other) const;
    Matrix transpose() const;

    static Matrix fromFile(const std::string& filename);

    Matrix operator*(const Matrix& other) const;
};

static_assert(offsetof(Matrix, rows) == 0, "Matrix.rows offset must be 0");
static_assert(offsetof(Matrix, cols) == 4, "Matrix.cols offset must be 4");
static_assert(offsetof(Matrix, data) == 8, "Matrix.data offset must be 8");

extern "C" void matmul_asm_basic(const Matrix* A, const Matrix* B, Matrix* C);
extern "C" void matmul_asm_unroll(const Matrix* A, const Matrix* B, Matrix* C);
extern "C" void matmul_asm_addr(const Matrix* A, const Matrix* B, Matrix* C);
extern "C" void matmul_asm_neon(const Matrix* A, const Matrix* BT, Matrix* C);

#endif
