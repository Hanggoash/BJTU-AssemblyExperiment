#include "Matrix.h"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <stdexcept>

Matrix::Matrix(int r, int c) : rows(r), cols(c), data(nullptr) {
    if (r <= 0 || c <= 0) {
        throw std::invalid_argument("matrix dimensions must be positive");
    }

    data = new int[rows * cols]();
}

Matrix::Matrix(const Matrix& other) : rows(other.rows), cols(other.cols), data(nullptr) {
    data = new int[rows * cols];
    for (int i = 0; i < rows * cols; ++i) {
        data[i] = other.data[i];
    }
}

Matrix& Matrix::operator=(const Matrix& other) {
    if (this == &other) {
        return *this;
    }

    int* new_data = new int[other.rows * other.cols];
    for (int i = 0; i < other.rows * other.cols; ++i) {
        new_data[i] = other.data[i];
    }

    delete[] data;
    rows = other.rows;
    cols = other.cols;
    data = new_data;
    return *this;
}

Matrix::~Matrix() {
    delete[] data;
}

int& Matrix::operator()(int i, int j) {
    return data[i * cols + j];
}

const int& Matrix::operator()(int i, int j) const {
    return data[i * cols + j];
}

void Matrix::randomFill(int low, int high) {
    if (low > high) {
        throw std::invalid_argument("randomFill low must be <= high");
    }

    const int range = high - low + 1;
    for (int i = 0; i < rows * cols; ++i) {
        data[i] = low + std::rand() % range;
    }
}

void Matrix::print() const {
    for (int i = 0; i < rows; ++i) {
        for (int j = 0; j < cols; ++j) {
            std::cout << data[i * cols + j];
            if (j + 1 < cols) {
                std::cout << ' ';
            }
        }
        std::cout << '\n';
    }
}

bool Matrix::equals(const Matrix& other) const {
    if (rows != other.rows || cols != other.cols) {
        return false;
    }

    for (int i = 0; i < rows * cols; ++i) {
        if (data[i] != other.data[i]) {
            return false;
        }
    }
    return true;
}

Matrix Matrix::transpose() const {
    Matrix transposed(cols, rows);
    for (int i = 0; i < rows; ++i) {
        for (int j = 0; j < cols; ++j) {
            transposed(j, i) = (*this)(i, j);
        }
    }
    return transposed;
}

Matrix Matrix::fromFile(const std::string& filename) {
    std::ifstream input(filename);
    if (!input) {
        throw std::runtime_error("failed to open matrix file: " + filename);
    }

    int r = 0;
    int c = 0;
    if (!(input >> r >> c)) {
        throw std::runtime_error("failed to read matrix size from: " + filename);
    }

    Matrix matrix(r, c);
    for (int i = 0; i < r; ++i) {
        for (int j = 0; j < c; ++j) {
            if (!(input >> matrix(i, j))) {
                throw std::runtime_error("not enough matrix data in: " + filename);
            }
        }
    }

    return matrix;
}

Matrix Matrix::operator*(const Matrix& other) const {
    if (cols != other.rows) {
        throw std::invalid_argument("matrix dimensions do not match for multiplication");
    }

    Matrix result(rows, other.cols);
    matmul_asm_basic(this, &other, &result);
    return result;
}
