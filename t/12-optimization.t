use v6.d;
use Test;
use lib 'lib';
use Inline::Python3;

plan 10;

# Test built-in optimization features
my $py = Inline::Python3.new;

# Set up test environment
$py.run(q:to/PYTHON/);
test_int = 42
test_str = "hello"

def multiply(x, y):
    return x * y

class MyClass:
    def __init__(self, value):
        self.value = value
    
    def double(self):
        return self.value * 2

obj = MyClass(10)

# For string interning test
string_list = ["test", "test", "test", "hello", "hello"]
PYTHON

# Test 1-2: Basic value access
is $py.run('test_int', :eval), 42, 'Integer access';
is $py.run('test_str', :eval), 'hello', 'String access';

# Test 3-4: Function calls
my $multiply = $py.run('multiply', :eval);
is $multiply(3, 4), 12, 'Function call';
is $multiply(5, 6), 30, 'Second function call';

# Test 5-6: Object method calls
my $obj = $py.run('obj', :eval);
is $obj.double(), 20, 'Method call';
is $obj.double(), 20, 'Second method call';

# Test 7: Multiple instances work independently
my $py2 = Inline::Python3.new;
$py2.run('test_int = 99');
is $py.run('test_int', :eval), 42, 'First instance unchanged';
is $py2.run('test_int', :eval), 99, 'Second instance has different value';

# Test 8: Large list handling
$py.run('large_list = list(range(1000))');
my @list = $py.run('large_list', :eval);
is @list.elems, 1000, 'Large list converted correctly';

# Test 9: Repeated string access (tests internal optimizations)
my @strings;
for ^5 -> $i {
    @strings.push($py.run("string_list[$i]", :eval));
}
ok @strings[0] eq @strings[1] eq @strings[2], 'Repeated strings handled correctly';

done-testing;