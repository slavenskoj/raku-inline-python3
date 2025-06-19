# Inline::Python3


A Raku module that enables seamless integration with Python3, allowing you to execute Python3 code, access Python3 objects, and leverage Python3's extensive standard library directly from Raku. 

**This is an initial implementation focusing on core functionality and is in development and testing.**

## Features

- Execute Python3 code from Raku
- Access Python3 objects, functions, and modules  
- Automatic bidirectional type conversion
- Persistent Python3 environment across calls
- Full support for Python3's standard library
- Exception handling across language boundaries
- Zero-copy NumPy array access (with NumPy installed)

## Installation

```bash
zef install Inline::Python3
```

### Requirements

- Raku 6.d or later

- Python3 3.6 or higher (managed by pyenv)

- Python3 development headers (python3-dev on Debian/Ubuntu)

- C compiler (gcc/clang)

- pyenv (required for the build system)

  

1. When you runs **zef install Inline::Python3**, zef will execute the Build.rakumod
2. The build process:

- Detects Python3 configuration using **pyenv** (required)

- Creates the resources/libraries directory

- Compiles src/python3_helper.c into a shared library

- Places the compiled library in resources/libraries/libpython3_helper.{so,dylib,dll}

  

 The build process specifically requires **pyenv** and will fail if:

1.   pyenv is not installed
2.  No Python version is selected in pyenv
3.  The selected Python version is not properly installed

 This ensures that the module is built with the correct Python version and configuration for each user's system.

### Development Setup

When developing or testing Inline::Python3, ensure pyenv is properly initialized:

```bash
# Build the helper library
cc -c -fPIC -O2 -Wall $(python3-config --includes) -o /tmp/python3_helper.o src/python3_helper.c
cc -shared -fPIC $(python3-config --ldflags --embed) -o resources/libraries/libpython3_helper.dylib /tmp/python3_helper.o

# Run tests with pyenv properly initialized
./test t/              # Run all tests
./test t/01-basic.t    # Run specific test
```

The `test` script ensures pyenv is initialized before running tests.

## Quick Start

```raku
use Inline::Python3;

# Create a Python3 environment
my $py = Inline::Python3.new;

# Execute Python3 code
$py.run('print("Hello from Python3!")');

# Evaluate expressions
my $result = $py.run('2 + 2', :eval);
say $result;  # 4

# Use Python3 modules
$py.run('import math');
my $pi = $py.run('math.pi', :eval);
say $pi;  # 3.141592653589793

# Call Python3 functions with Raku values
my $func = $py.run('lambda x, y: x * y', :eval);
say $func(6, 7);  # 42
```

## Examples

The `examples/` directory contains comprehensive examples demonstrating various features:

### Core Features
- [`basic-usage.raku`](examples/basic-usage.raku) - Getting started with Inline::Python3
- [`builtin-functions.raku`](examples/builtin-functions.raku) - Using Python3's built-in functions
- [`data-structures.raku`](examples/data-structures.raku) - Working with lists, dicts, sets, and tuples
- [`string-manipulation.raku`](examples/string-manipulation.raku) - Python3 string operations

### Standard Library Usage
- [`math-operations.raku`](examples/math-operations.raku) - Mathematical operations with the math module
- [`datetime-operations.raku`](examples/datetime-operations.raku) - Date and time handling
- [`json-handling.raku`](examples/json-handling.raku) - JSON encoding and decoding
- [`regex-patterns.raku`](examples/regex-patterns.raku) - Regular expressions with re module
- [`file-operations.raku`](examples/file-operations.raku) - File I/O and path operations

### Advanced Topics
- [`exception-handling.raku`](examples/exception-handling.raku) - Cross-language exception handling
- [`classes-and-objects.raku`](examples/classes-and-objects.raku) - Creating and using Python3 classes

## Type Conversions

Inline::Python3 automatically converts between Raku and Python3 types:

| Raku Type | Python3 Type |
|-----------|-------------|
| Any (undefined) | None |
| Bool | bool |
| Int | int |
| Num/Rat | float |
| Str | str |
| Blob | bytes |
| Array | list |
| Hash | dict |
| Set | set |

## API Reference

### Methods

#### `new()`
Create a new Python3 environment instance.

#### `run(Str $code, :$eval = False)`
Execute Python3 code. With `:eval`, return the result of evaluating the code as an expression.

#### `import(Str $module)`
Import a Python3 module and return it as a PythonObject.

#### `call(Str $module, Str $function, *@args, *%kwargs)`
Call a function from a module with arguments.

#### `numpy-array(PythonObject $arr)`
Create a zero-copy wrapper around a NumPy array (requires NumPy).

## Performance Features

- Method caching for frequently called methods
- Automatic type caching for repeated operations
- Batch conversion utilities for large datasets
- Zero-copy NumPy array access

## Contributing

Contributions are welcome! Please submit pull requests or issues on GitHub.

## Author

Danslav Slavenskoj

## License

Artistic License 2.0

## See Also

- [Performance Guide](docs/PERFORMANCE.md)
- [API Documentation](docs/API.md)
