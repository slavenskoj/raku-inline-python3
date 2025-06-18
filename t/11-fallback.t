use v6.d;
use Test;
use lib 'lib';
use Inline::Python3;

plan 15;

my $py = Inline::Python3.new;

# Create a Python object with various attributes and methods
$py.run(q:to/PYTHON/);
class TestObject:
    def __init__(self):
        self.int_attr = 42
        self.str_attr = "hello"
        self.list_attr = [1, 2, 3]
        self.dict_attr = {"key": "value"}
        self._private = "private"
    
    def no_args(self):
        return "no args"
    
    def one_arg(self, x):
        return x * 2
    
    def two_args(self, x, y):
        return x + y
    
    def kwargs_method(self, x, y=10):
        return x + y
    
    @property
    def computed_property(self):
        return self.int_attr * 2
    
    @staticmethod
    def static_method(x):
        return x * 3
    
    @classmethod
    def class_method(cls, x):
        return f"{cls.__name__}:{x}"

obj = TestObject()
PYTHON

my $obj = $py.run('obj', :eval);

# Test attribute access
is $obj.int_attr, 42, 'Integer attribute access';
is $obj.str_attr, 'hello', 'String attribute access';
my $list = $obj.list_attr;
ok $list ~~ Array, 'List attribute returns Array';
# Access list elements directly
is $list[1], 2, 'List attribute data correct';
# Access dict values through Python
my $val = $py.run('obj.dict_attr["key"]', :eval);
is $val, 'value', 'Dict attribute access';
is $obj._private, 'private', 'Private attribute access';

# Test method calls
is $obj.no_args(), 'no args', 'Method with no arguments';
is $obj.one_arg(5), 10, 'Method with one argument';
is $obj.two_args(3, 4), 7, 'Method with two arguments';
is $obj.kwargs_method(5), 15, 'Method with default argument';
is $obj.kwargs_method(5, 20), 25, 'Method with explicit argument';

# Test property access
is $obj.computed_property, 84, 'Property access';

# Test that attribute access doesn't accept arguments
dies-ok { $obj.int_attr(42) }, 'Cannot call attribute as method';

# Test module attribute/method access
my $os = $py.import('os');
ok $os.name ~~ Str, 'Module attribute access';
ok $os.getcwd() ~~ Str, 'Module method call';

done-testing;