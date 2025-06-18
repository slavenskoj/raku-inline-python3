#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== Python3 Built-in Functions Examples ===\n";

# Numeric functions
say "1. Numeric built-in functions:";
say "abs(-42) = " ~ $py.run('abs(-42)', :eval);
say "pow(2, 10) = " ~ $py.run('pow(2, 10)', :eval);
say "round(3.14159, 2) = " ~ $py.run('round(3.14159, 2)', :eval);
say "min(5, 3, 9, 1) = " ~ $py.run('min(5, 3, 9, 1)', :eval);
say "max(5, 3, 9, 1) = " ~ $py.run('max(5, 3, 9, 1)', :eval);

# Working with sequences
say "\n2. Sequence operations:";
my $sum = $py.run('sum([1, 2, 3, 4, 5])', :eval);
say "sum([1, 2, 3, 4, 5]) = $sum";

my $length = $py.run('len([10, 20, 30, 40])', :eval);
say "len([10, 20, 30, 40]) = $length";

my $sorted = $py.run('sorted([3, 1, 4, 1, 5, 9, 2, 6])', :eval);
say "sorted([3, 1, 4, 1, 5, 9, 2, 6]) = $sorted";

my $reversed = $py.run('list(reversed([1, 2, 3, 4, 5]))', :eval);
say "reversed([1, 2, 3, 4, 5]) = $reversed";

# Type conversions
say "\n3. Type conversion functions:";
say "int('42') = " ~ $py.run('int("42")', :eval);
say "float('3.14') = " ~ $py.run('float("3.14")', :eval);
say "str(123) = " ~ $py.run('str(123)', :eval);
say "bool(1) = " ~ $py.run('bool(1)', :eval);
say "bool(0) = " ~ $py.run('bool(0)', :eval);
say "list('abc') = " ~ $py.run('list("abc")', :eval);

# Range and enumerate
say "\n4. Range and enumerate:";
my $range = $py.run('list(range(5))', :eval);
say "range(5) = $range";

$range = $py.run('list(range(2, 8))', :eval);
say "range(2, 8) = $range";

$range = $py.run('list(range(0, 10, 2))', :eval);
say "range(0, 10, 2) = $range";

$py.run('items = ["a", "b", "c"]');
my $enumerated = $py.run('list(enumerate(items))', :eval);
say "enumerate(['a', 'b', 'c']) = $enumerated";

# Zip function
say "\n5. Zip function:";
$py.run('names = ["Alice", "Bob", "Charlie"]');
$py.run('ages = [25, 30, 35]');
my $zipped = $py.run('list(zip(names, ages))', :eval);
say "zip(names, ages) = $zipped";

# All and any
say "\n6. All and any functions:";
say "all([True, True, True]) = " ~ $py.run('all([True, True, True])', :eval);
say "all([True, False, True]) = " ~ $py.run('all([True, False, True])', :eval);
say "any([False, False, True]) = " ~ $py.run('any([False, False, True])', :eval);
say "any([False, False, False]) = " ~ $py.run('any([False, False, False])', :eval);

# Map and filter
say "\n7. Map and filter:";
$py.run('numbers = [1, 2, 3, 4, 5]');
my $mapped = $py.run('list(map(lambda x: x * 2, numbers))', :eval);
say "map(lambda x: x * 2, [1,2,3,4,5]) = $mapped";

my $filtered = $py.run('list(filter(lambda x: x % 2 == 0, numbers))', :eval);
say "filter(lambda x: x % 2 == 0, [1,2,3,4,5]) = $filtered";

# Format and repr
say "\n8. String representation:";
$py.run('value = 3.14159');
say "format(3.14159, '.2f') = " ~ $py.run('format(value, ".2f")', :eval);
say "repr('hello') = " ~ $py.run('repr("hello")', :eval);
say "hex(255) = " ~ $py.run('hex(255)', :eval);
say "oct(8) = " ~ $py.run('oct(8)', :eval);
say "bin(10) = " ~ $py.run('bin(10)', :eval);

say "\n=== End of Built-in Functions Examples ===";