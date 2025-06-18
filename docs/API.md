# Inline::Python3 API Documentation

## Core Module: Inline::Python3

### Constructor

```raku
my $py = Inline::Python3.new;
```

Creates a new Python environment instance with automatic optimization features enabled.

### Methods

#### run(Str $code, :$eval = False)

Execute Python code or evaluate an expression.

```raku
# Execute code (no return value)
$py.run('x = 42');

# Evaluate expression (returns value)
my $result = $py.run('x * 2', :eval);  # Returns 84
```

#### import(Str $module)

Import a Python module and return it as a PythonObject.

```raku
my $math = $py.import('math');
say $math.pi;  # 3.141592653589793
```

#### call(Str $module, Str $function, *@args, *%kwargs)

Call a function from a module with arguments.

```raku
my $result = $py.call('math', 'pow', 2, 3);  # Returns 8.0
```

#### call-object(PythonObject $obj, *@args, *%kwargs)

Call a Python callable object.

```raku
my $func = $py.run('lambda x: x**2', :eval);
my $result = $py.call-object($func, 5);  # Returns 25
```

#### global()

Access the global Python instance (singleton pattern).

```raku
my $global-py = Inline::Python3.global;
```

## PythonObject

Python objects that don't have direct Raku equivalents are wrapped in PythonObject instances.

### Features

- **Attribute access**: `$obj.attribute`
- **Method calls**: `$obj.method(@args, :$kwarg)`
- **Callable objects**: `$obj(@args)`
- **Indexing**: `$obj[$index]` or `$obj{$key}`
- **String representation**: Automatic conversion to string

### Example

```raku
my $py = Inline::Python3.new;
$py.run(q:to/PYTHON/);
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def greet(self):
        return f"Hello, I'm {self.name}"
PYTHON

my $person = $py.run('Person("Alice", 30)', :eval);
say $person.name;        # Alice
say $person.greet();     # Hello, I'm Alice
```

## Type Conversions

Automatic bidirectional type conversion between Raku and Python:

| Raku Type | Python Type | Notes |
|-----------|-------------|-------|
| Any (undefined) | None | |
| Bool | bool | |
| Int | int | |
| Num/Rat | float | |
| Str | str | |
| Blob | bytes | |
| Array | list | |
| Hash | dict | |
| Set | set | |
| PythonObject | (original) | Wrapped Python objects |

## NumPy Support (with NumPy installed)

### numpy-array(PythonObject $arr)

Create a zero-copy wrapper around a NumPy array.

```raku
use Inline::Python3;
use Inline::Python3::NumPy;

my $py = Inline::Python3.new;
$py.run('import numpy as np');
my $arr = $py.run('np.array([1, 2, 3, 4, 5])', :eval);
my $numpy = $py.numpy-array($arr);

say $numpy.shape;    # (5,)
say $numpy[2];       # 3
$numpy[2] = 10;      # Direct memory access
```

## Batch Conversions

For efficient bulk data transfers:

```raku
use Inline::Python3::BatchConvert;

my $py = Inline::Python3.new;
my $batch = BatchConverter.new(:python($py));

# Convert Raku data to Python
my @large-array = 1..10000;
my $py-list = $batch.to-python(@large-array);

# Convert Python data to Raku
my @raku-array = $batch.from-python($py-list);

# Dictionary conversions
my %data = (a => 1, b => 2, c => 3);
my $py-dict = $batch.dict-to-python(%data);
my %raku-hash = $batch.dict-from-python($py-dict);
```

## Performance Monitoring

### PerformanceMonitor

Monitor Python operation performance:

```raku
use Inline::Python3::Performance::Monitor;

my $monitor = PerformanceMonitor.new;
$monitor.start-timing("operation");
# ... perform operations ...
$monitor.end-timing("operation");

say $monitor.report;
```

### OptimizationHelper

Helper utilities for optimization:

```raku
use Inline::Python3::Performance;

my $py = Inline::Python3.new;
my $helper = OptimizationHelper.new(:py($py));

# The helper provides internal optimization utilities
# Most optimizations are automatic via TypeCache and BufferPool
```

## Exception Handling

Python exceptions are caught and rethrown as Raku exceptions:

```raku
try {
    $py.run('1/0', :eval);
    CATCH {
        default {
            say "Python error: $_";
        }
    }
}
```

## Internal Optimizations

The module includes several automatic optimizations:

1. **TypeCache**: Caches method and attribute lookups per Python type
2. **BufferPool**: Reuses string conversion buffers
3. **Direct Conversions**: Efficient type conversions without intermediate objects
4. **Persistent Globals**: Maintains Python state across calls

These optimizations are enabled by default and require no configuration.

## Thread Safety

The module is designed for single-threaded use. Each Inline::Python3 instance should be used from a single thread only.

## Limitations

- Python's GIL (Global Interpreter Lock) is respected
- Some Python objects may not be directly convertible to Raku types
- Large data transfers should use BatchConverter for efficiency
- NumPy integration requires NumPy to be installed in the Python environment