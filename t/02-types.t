use v6.d;
use Test;
use Inline::Python3;

plan 15;

my $py = Inline::Python3.new;

# Test Raku to Python conversions
$py.run(q:to/PYTHON/);
def check_type(obj, expected_type):
    return type(obj).__name__ == expected_type

def check_value(obj, expected):
    return obj == expected
PYTHON

# Get the functions from globals
my $check_type = $py.run('check_type', :eval);
my $check_value = $py.run('check_value', :eval);

# Int conversion
ok $check_type(42, 'int'), 'Raku Int -> Python int';
ok $check_value(42, 42), 'Int value preserved';

# Num conversion
ok $check_type(3.14, 'float'), 'Raku Num -> Python float';
ok $check_value(3.14, 3.14), 'Num value preserved';

# Str conversion
ok $check_type('hello', 'str'), 'Raku Str -> Python str';
ok $check_value('hello', 'hello'), 'Str value preserved';

# Bool conversion
ok $check_type(True, 'bool'), 'Raku Bool -> Python bool';
ok $check_value(True, True), 'Bool True preserved';
ok $check_value(False, False), 'Bool False preserved';

# List conversion
ok $check_type($[1, 2, 3], 'list'), 'Raku Array -> Python list';
ok $check_value($[1, 2, 3], $[1, 2, 3]), 'Array values preserved';

# Hash conversion
ok $check_type(${a => 1, b => 2}, 'dict'), 'Raku Hash -> Python dict';

# Nested structures
my %nested = 
    name => 'test',
    values => [1, 2, 3],
    config => {
        enabled => True,
        threshold => 0.5
    };

$py.run(q:to/PYTHON/);
def check_nested(data):
    return (
        data['name'] == 'test' and
        data['values'] == [1, 2, 3] and
        data['config']['enabled'] == True and
        data['config']['threshold'] == 0.5
    )
PYTHON

my $check_nested = $py.run('check_nested', :eval);
ok $check_nested($%nested), 'Nested structure conversion';

# Undefined/None conversion
ok $check_value(Any, $py.run('None', :eval)), 'Raku Any -> Python None';

# Blob conversion
my $blob = "Hello".encode;
$py.run(q:to/PYTHON/);
def check_bytes(data):
    return isinstance(data, bytes) and data == b'Hello'
PYTHON

my $check_bytes = $py.run('check_bytes', :eval);
ok $check_bytes($blob), 'Raku Blob -> Python bytes';

done-testing;