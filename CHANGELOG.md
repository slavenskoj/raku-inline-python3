# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-06-18

### Added
- Initial release of Inline::Python3
- Core Python3 integration functionality
- Automatic type conversion between Raku and Python3
- Support for executing Python3 code and evaluating expressions
- Access to Python3 objects, functions, and modules
- Exception handling across language boundaries
- Persistent Python3 environment across calls
- Full support for Python3's standard library
- Zero-copy NumPy array access (when NumPy is installed)
- Comprehensive test suite with 97 tests
- 11 example scripts demonstrating various features
- Complete documentation (README, API, PERFORMANCE)

### Features
- TypeCache for optimized method lookups
- BufferPool for efficient string conversions
- FALLBACK mechanism for seamless Python method access
- Support for Python3 callable objects
- Batch conversion utilities for performance
- Integration with pyenv for Python version management

### Requirements
- Raku 6.d or later
- Python3 3.8 or higher (managed by pyenv)
- C compiler (gcc/clang)
- pyenv for Python version management