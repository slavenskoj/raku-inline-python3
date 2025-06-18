use v6.d;
use Test;
use lib 'lib';
use Inline::Python3;

plan 12;

my $py = Inline::Python3.new;

# Test 1: Variables persist between run() calls
$py.run('x = 42');
is $py.run('x', :eval), 42, 'Variable persists between run() calls';

# Test 2: Functions persist
$py.run(q:to/PYTHON/);
def add(a, b):
    return a + b
PYTHON

is $py.run('add(2, 3)', :eval), 5, 'Function persists and can be called';

# Test 3: Classes persist
$py.run(q:to/PYTHON/);
class TestClass:
    def __init__(self, value):
        self.value = value
    
    def get_value(self):
        return self.value
PYTHON

$py.run('obj = TestClass(100)');
is $py.run('obj.get_value()', :eval), 100, 'Class instances persist';

# Test 4: Imports persist
$py.run('import json');
ok $py.run('json.dumps({"test": 123})', :eval) ~~ Str, 'Imported modules persist';

# Test 5: Global namespace modification
$py.run('globals()["dynamic_var"] = "test"');
is $py.run('dynamic_var', :eval), 'test', 'Can modify global namespace';

# Test 6: List modifications persist
$py.run('my_list = [1, 2, 3]');
$py.run('my_list.append(4)');
is $py.run('len(my_list)', :eval), 4, 'List modifications persist';
is $py.run('my_list[3]', :eval), 4, 'List contains appended element';

# Test 7: Dictionary modifications persist
$py.run('my_dict = {"a": 1}');
$py.run('my_dict["b"] = 2');
is $py.run('my_dict["b"]', :eval), 2, 'Dictionary modifications persist';

# Test 8: Multiple Python interpreters have separate namespaces
my $py2 = Inline::Python3.new;
$py2.run('x = 99');
is $py.run('x', :eval), 42, 'First interpreter maintains its value';
is $py2.run('x', :eval), 99, 'Second interpreter has separate namespace';

# Test 9: Complex object state persists
$py.run(q:to/PYTHON/);
class Counter:
    def __init__(self):
        self.count = 0
    
    def increment(self):
        self.count += 1
        return self.count

counter = Counter()
PYTHON

is $py.run('counter.increment()', :eval), 1, 'First increment';
is $py.run('counter.increment()', :eval), 2, 'Second increment - state persists';

done-testing;