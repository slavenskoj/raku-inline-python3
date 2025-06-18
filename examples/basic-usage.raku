#!/usr/bin/env raku

use Inline::Python3;

# Create a Python3 environment
my $py = Inline::Python3.new;

say "=== Basic Usage Examples ===\n";

# Execute Python3 code
say "1. Executing Python3 print statement:";
$py.run('print("Hello from Python3!")');

# Evaluate expressions
say "\n2. Evaluating Python3 expressions:";
my $result = $py.run('2 + 2', :eval);
say "2 + 2 = $result";

$result = $py.run('10 * 5', :eval);
say "10 * 5 = $result";

# Working with variables
say "\n3. Setting and using Python3 variables:";
$py.run('x = 42');
$py.run('y = 8');
$result = $py.run('x + y', :eval);
say "x = 42, y = 8";
say "x + y = $result";

# Multi-line Python3 code
say "\n4. Running multi-line Python3 code:";
$py.run(q:to/PYTHON/);
def greet(name):
    return f"Hello, {name}!"

message = greet("Raku User")
print(message)
PYTHON

# Accessing the function we just defined
say "\n5. Calling Python3 function from Raku:";
my $greet_func = $py.run('greet', :eval);
my $greeting = $greet_func("World");
say $greeting;

# Python lambdas
say "\n6. Using Python3 lambdas:";
my $square = $py.run('lambda x: x ** 2', :eval);
say "square(5) = " ~ $square(5);
say "square(10) = " ~ $square(10);

# Boolean operations
say "\n7. Boolean operations:";
my $is_true = $py.run('5 > 3', :eval);
say "5 > 3 is " ~ ($is_true ?? "True" !! "False");

my $is_false = $py.run('10 < 2', :eval);
say "10 < 2 is " ~ ($is_false ?? "True" !! "False");

say "\n=== End of Basic Usage Examples ===";