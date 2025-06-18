use v6.d;
use Test;
use Inline::Python3;

plan 12;

my $py = Inline::Python3.new;

# Create a Python class
$py.run(q:to/PYTHON/);
class TestClass:
    def __init__(self, value):
        self.value = value
        self.calls = []
    
    def get_value(self):
        return self.value
    
    def set_value(self, new_value):
        self.value = new_value
    
    def add(self, a, b):
        result = a + b
        self.calls.append(f"add({a}, {b}) = {result}")
        return result
    
    def greet(self, name="World"):
        return f"Hello, {name}!"
    
    @property
    def computed(self):
        return self.value * 2
PYTHON

# Test object creation
my $TestClass = $py.run('TestClass', :eval);
my $obj = $TestClass(42);
ok $obj ~~ Inline::Python3::PythonObject, 'Created Python object';

# Test method calls
is $obj.get_value(), 42, 'Method call without args';
lives-ok { $obj.set_value(100) }, 'Method call with args (void return)';
is $obj.get_value(), 100, 'State change persisted';

# Test method with multiple arguments
is $obj.add(10, 20), 30, 'Method with multiple args';

# Test method with default arguments
is $obj.greet(), 'Hello, World!', 'Method with default arg';
is $obj.greet('Raku'), 'Hello, Raku!', 'Method with provided arg';

# Test property access
is $obj.value, 100, 'Direct attribute access';
is $obj.computed, 200, 'Property access';

# Test attribute modification via method
lives-ok { $obj.set_value(50) }, 'Attribute modification via setter';
is $obj.value, 50, 'Attribute modification persisted';

# Test list attribute
ok $obj.calls.elems > 0, 'Can access list attributes';

done-testing;