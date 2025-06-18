#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== Mathematical Operations Examples ===\n";

# Basic arithmetic
say "1. Basic arithmetic operations:";
say "5 + 3 = " ~ $py.run('5 + 3', :eval);
say "10 - 4 = " ~ $py.run('10 - 4', :eval);
say "6 * 7 = " ~ $py.run('6 * 7', :eval);
say "15 / 3 = " ~ $py.run('15 / 3', :eval);
say "17 // 5 = " ~ $py.run('17 // 5', :eval) ~ " (floor division)";
say "17 % 5 = " ~ $py.run('17 % 5', :eval) ~ " (modulo)";
say "2 ** 8 = " ~ $py.run('2 ** 8', :eval) ~ " (exponentiation)";

# Import math module
$py.run('import math');

# Math constants
say "\n2. Mathematical constants:";
say "π (pi) = " ~ $py.run('math.pi', :eval);
say "e = " ~ $py.run('math.e', :eval);
say "τ (tau) = " ~ $py.run('math.tau', :eval);
say "∞ (infinity) = " ~ $py.run('math.inf', :eval);

# Trigonometric functions
say "\n3. Trigonometric functions:";
say "sin(π/2) = " ~ $py.run('math.sin(math.pi/2)', :eval);
say "cos(π) = " ~ $py.run('math.cos(math.pi)', :eval);
say "tan(π/4) = " ~ $py.run('math.tan(math.pi/4)', :eval);
say "degrees(π) = " ~ $py.run('math.degrees(math.pi)', :eval);
say "radians(180) = " ~ $py.run('math.radians(180)', :eval);

# Logarithmic functions
say "\n4. Logarithmic and exponential functions:";
say "log(10) = " ~ $py.run('math.log(10)', :eval);
say "log10(1000) = " ~ $py.run('math.log10(1000)', :eval);
say "log2(8) = " ~ $py.run('math.log2(8)', :eval);
say "exp(1) = " ~ $py.run('math.exp(1)', :eval);
say "sqrt(16) = " ~ $py.run('math.sqrt(16)', :eval);
say "pow(2, 10) = " ~ $py.run('math.pow(2, 10)', :eval);

# Rounding and absolute value
say "\n5. Rounding functions:";
say "ceil(4.3) = " ~ $py.run('math.ceil(4.3)', :eval);
say "floor(4.7) = " ~ $py.run('math.floor(4.7)', :eval);
say "trunc(4.7) = " ~ $py.run('math.trunc(4.7)', :eval);
say "round(4.5) = " ~ $py.run('round(4.5)', :eval);
say "round(4.567, 2) = " ~ $py.run('round(4.567, 2)', :eval);

# Special functions
say "\n6. Special mathematical functions:";
say "factorial(5) = " ~ $py.run('math.factorial(5)', :eval);
say "gcd(48, 18) = " ~ $py.run('math.gcd(48, 18)', :eval);
say "lcm(12, 18) = " ~ $py.run('math.lcm(12, 18)', :eval);
say "comb(10, 3) = " ~ $py.run('math.comb(10, 3)', :eval) ~ " (combinations)";
say "perm(5, 3) = " ~ $py.run('math.perm(5, 3)', :eval) ~ " (permutations)";

# Distance and hypot
say "\n7. Distance calculations:";
say "hypot(3, 4) = " ~ $py.run('math.hypot(3, 4)', :eval);
say "dist([1, 2], [4, 6]) = " ~ $py.run('math.dist([1, 2], [4, 6])', :eval);

# Statistics-like operations
say "\n8. Basic statistics with built-ins:";
$py.run('numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]');
say "numbers = " ~ $py.run('numbers', :eval);
say "sum(numbers) = " ~ $py.run('sum(numbers)', :eval);
say "min(numbers) = " ~ $py.run('min(numbers)', :eval);
say "max(numbers) = " ~ $py.run('max(numbers)', :eval);
say "mean = " ~ $py.run('sum(numbers) / len(numbers)', :eval);

# Complex calculations
say "\n9. Complex calculations:";
$py.run(q:to/PYTHON/);
# Quadratic formula
def quadratic(a, b, c):
    discriminant = b**2 - 4*a*c
    if discriminant >= 0:
        root1 = (-b + math.sqrt(discriminant)) / (2*a)
        root2 = (-b - math.sqrt(discriminant)) / (2*a)
        return (root1, root2)
    else:
        return "No real roots"
PYTHON

say "Solving x² - 5x + 6 = 0:";
my $roots = $py.run('quadratic(1, -5, 6)', :eval);
say "Roots: $roots";

# Checking for special values
say "\n10. Checking special values:";
say "isfinite(100) = " ~ $py.run('math.isfinite(100)', :eval);
say "isinf(math.inf) = " ~ $py.run('math.isinf(math.inf)', :eval);
say "isnan(float('nan')) = " ~ $py.run('math.isnan(float("nan"))', :eval);
say "isclose(0.1 + 0.2, 0.3) = " ~ $py.run('math.isclose(0.1 + 0.2, 0.3)', :eval);

say "\n=== End of Mathematical Operations Examples ===";