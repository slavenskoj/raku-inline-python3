use v6.d;
use Test;
use Inline::Python3;

plan 20;

# Test 1: Can create instance
my $py;
lives-ok { $py = Inline::Python3.new }, 'Can create Inline::Python3 instance';

# Test 2: Simple eval
is $py.run('2 + 2', :eval), 4, 'Simple arithmetic evaluation';

# Test 3: String return
is $py.run('"Hello, Raku!"', :eval), 'Hello, Raku!', 'String return value';

# Test 4: None/Any conversion
ok $py.run('None', :eval) ~~ Any, 'Python None converts to Raku Any';

# Test 5: Boolean conversion
is $py.run('True', :eval), True, 'Python True converts to Raku True';
is $py.run('False', :eval), False, 'Python False converts to Raku False';

# Test 6: Float conversion
is-approx $py.run('3.14159', :eval), 3.14159, 'Float conversion';

# Test 7: List conversion
my $list = $py.run('[1, 2, 3]', :eval);
ok $list ~~ Array, 'List returns as Array';
is $list[0], 1, 'Can access list elements';
is $list[2], 3, 'List element access works';

# Test 8: Dict conversion
my $dict = $py.run('{"a": 1, "b": 2}', :eval);
ok $dict ~~ Hash, 'Dict returns as Hash';
is $dict<a>, 1, 'Can access dict values';

# Test 9: Function definition and call
$py.run(q:to/PYTHON/);
def greet(name):
    return f"Hello, {name}!"
PYTHON

my $greet = $py.run('greet', :eval);
is $greet('World'), 'Hello, World!', 'Function call with argument';

# Test 10: Exception handling
dies-ok {
    $py.run('1/0', :eval)
}, 'Python exceptions are caught';

# Test 11: Import system module
my $sys = $py.import('sys');
ok $sys ~~ Inline::Python3::PythonObject, 'Can import system module';
ok $sys.version.Str ~~ /^3/, 'Can access module attributes';

# Test 12: Import with function call
my $os = $py.import('os');
ok $os.getcwd().Str.IO.e, 'Can call imported module functions';

# Test 13: Keyword arguments
$py.run(q:to/PYTHON/);
def kwarg_test(a, b=10, c=20):
    return a + b + c
PYTHON

my $kwarg_test = $py.run('kwarg_test', :eval);
is $kwarg_test(5), 35, 'Function with default kwargs';
is $kwarg_test(5, :b(15)), 40, 'Function with named kwargs';
is $kwarg_test(5, :b(15), :c(25)), 45, 'Multiple kwargs';

done-testing;