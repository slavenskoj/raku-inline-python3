# Inline::Python3 Performance Guide

## Overview

Inline::Python3 includes several automatic performance optimizations that work without configuration. This guide explains how these optimizations work and how to maximize performance when using the module.

## Automatic Optimizations

### 1. Type Cache

The module automatically caches method and attribute lookups for each Python type, significantly improving performance for repeated operations on objects of the same type.

```raku
my $py = Inline::Python3.new;
$py.run(q:to/PYTHON/);
class Calculator:
    def add(self, x, y):
        return x + y
PYTHON

my $calc = $py.run('Calculator()', :eval);

# First call: method lookup is cached
$calc.add(1, 2);

# Subsequent calls: use cached method (much faster)
for ^1000 {
    $calc.add($_, $_ + 1);
}
```

### 2. Buffer Pool

String conversions between Raku and Python reuse buffers from a pool, reducing memory allocation overhead:

```raku
# Efficient string transfers
for ^10000 {
    $py.run("text = 'Processing string number $_'");
}
```

### 3. Direct Type Conversions

Basic types (integers, floats, strings, booleans) are converted directly without creating intermediate objects:

```raku
# These conversions are optimized
my $int = $py.run('42', :eval);           # Direct Int conversion
my $float = $py.run('3.14', :eval);       # Direct Num conversion
my $str = $py.run('"hello"', :eval);      # Direct Str conversion
my @list = $py.run('[1, 2, 3]', :eval);   # Direct Array conversion
```

## Performance Best Practices

### 1. Reuse Python Objects

Don't recreate objects unnecessarily:

```raku
# Good: Create once, use many times
my $regex = $py.run('import re; re.compile(r"\d+")', :eval);
for @strings -> $str {
    my $matches = $regex.findall($str);
}

# Bad: Recreating object each time
for @strings -> $str {
    my $matches = $py.run('re.findall(r"\d+", "' ~ $str ~ '")', :eval);
}
```

### 2. Use Batch Conversions for Large Data

When transferring large amounts of data, use the BatchConverter:

```raku
use Inline::Python3::BatchConvert;

my $batch = BatchConverter.new(:python($py));

# Convert large arrays efficiently
my @large-data = 1..100000;
my $py-list = $batch.to-python(@large-data);

# Process in Python
$py.run('import statistics');
my $mean = $py.call('statistics', 'mean', $py-list);
```

### 3. Keep Data in Python Format

When performing multiple operations, keep data in Python format:

```raku
# Good: Keep data in Python
$py.run(q:to/PYTHON/);
data = list(range(10000))
result = sum(data) / len(data)
squared = [x**2 for x in data]
PYTHON

# Bad: Converting back and forth
my @data = $py.run('list(range(10000))', :eval);
my $sum = @data.sum;
my $mean = $sum / @data.elems;
my @squared = @data.map(* ** 2);
```

### 4. Use NumPy for Numerical Work

For numerical computations, NumPy provides significant performance benefits:

```raku
use Inline::Python3::NumPy;

$py.run('import numpy as np');

# Create large array in NumPy
my $arr = $py.run('np.arange(1000000)', :eval);
my $numpy = $py.numpy-array($arr);

# Operations are performed in C
my $sum = $py.run('np.sum', :eval)($arr);
my $mean = $py.run('np.mean', :eval)($arr);
```

### 5. Minimize Python/Raku Boundary Crossings

Each call between Raku and Python has overhead. Batch operations when possible:

```raku
# Good: Single Python call processes everything
$py.run(q:to/PYTHON/);
def process_all(items):
    return [item.upper() for item in items if len(item) > 3]
    
result = process_all(['hello', 'hi', 'world', 'python'])
PYTHON

# Bad: Multiple boundary crossings
my @items = <hello hi world python>;
my @result;
for @items -> $item {
    if $item.chars > 3 {
        @result.push($py.run('"' ~ $item ~ '".upper()', :eval));
    }
}
```

## Performance Monitoring

Use the PerformanceMonitor to identify bottlenecks:

```raku
use Inline::Python3::Performance::Monitor;

my $monitor = PerformanceMonitor.new;

$monitor.start-timing("data-processing");
# ... your code here ...
$monitor.end-timing("data-processing");

$monitor.start-timing("python-calls");
for ^100 {
    $py.run('x = 1 + 1');
}
$monitor.end-timing("python-calls");

say $monitor.report;
```

## Expected Performance

With optimizations enabled, you can expect:

- **Simple function calls**: Tens of thousands per second
- **Method calls**: Similar to function calls (with caching)
- **Attribute access**: Hundreds of thousands per second
- **Type conversions**: Minimal overhead for basic types
- **NumPy operations**: Near-native C performance

Actual performance depends on:
- Complexity of Python operations
- Size of data being transferred
- Frequency of Python/Raku boundary crossings
- Python interpreter overhead

## Memory Management

The module handles memory management automatically:

- Python objects are reference counted
- Raku wrappers are garbage collected
- Circular references between Raku and Python are handled
- Buffer pool prevents excessive allocations

## Troubleshooting Performance Issues

If you experience performance problems:

1. **Profile your code**: Use PerformanceMonitor to identify slow operations
2. **Check boundary crossings**: Minimize calls between Raku and Python
3. **Verify data sizes**: Large data transfers may need BatchConverter
4. **Consider Python-side processing**: Complex operations may be faster entirely in Python
5. **Use NumPy**: For numerical work, NumPy is significantly faster

## Summary

Inline::Python3 provides automatic optimizations that handle most common use cases efficiently. For maximum performance:

- Let the automatic caching work for you
- Keep data in the appropriate format (Python or Raku)
- Use batch operations for large data sets
- Minimize language boundary crossings
- Use specialized tools (NumPy) for specific domains