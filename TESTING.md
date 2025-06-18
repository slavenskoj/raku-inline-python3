# Testing Inline::Python3

## Prerequisites

- Ensure pyenv is installed and properly configured
- Python 3.8+ should be installed via pyenv
- The helper library must be built (see Development Setup in README.md)

## Running Tests

### Using the test wrapper (recommended)

The `test` script ensures pyenv is properly initialized:

```bash
# Run all tests
./test t/

# Run specific test
./test t/01-basic.t
```

### Running tests directly

If running tests directly with `prove`, ensure pyenv is initialized in your shell:

```bash
# Initialize pyenv
eval "$(pyenv init -)"

# Then run tests
prove --exec=raku t/
```

## Test Structure

The test suite consists of 8 test files with 97 tests total:

- `01-basic.t` - Basic functionality and type conversions (20 tests)
- `02-types.t` - Type conversion tests (15 tests)
- `03-objects.t` - Python object manipulation (12 tests)
- `04-errors.t` - Exception handling (8 tests)
- `05-performance.t` - Performance-related tests (5 tests)
- `10-persistence.t` - Persistent environment tests (12 tests)
- `11-fallback.t` - FALLBACK mechanism tests (15 tests)
- `12-optimization.t` - Optimization features (10 tests)

## Known Issues

Some tests may fail with "bash: No such file or directory" if pyenv is not properly initialized. This is because pyenv's initialization script expects bash. Always use the `test` wrapper script or ensure pyenv is initialized in your shell before running tests.