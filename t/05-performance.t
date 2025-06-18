use v6.d;
use Test;
use Inline::Python3;

plan 5;

my $py = Inline::Python3.new;

# Test performance with large data structures
$py.run(q:to/PYTHON/);
def make_big_list():
    return list(range(10000))

def make_big_dict():
    return {str(i): i for i in range(1000)}

def sum_list(lst):
    return sum(lst)
PYTHON

# Test function creation and access
my $make-list = $py.run('make_big_list', :eval);
ok $make-list.defined, 'Function object created';

# Test list conversion performance
my $start = now;
my @big-list = $make-list();
my $list-time = now - $start;
ok @big-list.elems == 10000, 'Large list converted correctly';
ok $list-time < 1.0, 'Large list conversion is reasonably fast';

# Test dict conversion
my $make-dict = $py.run('make_big_dict', :eval);
$start = now;
my %big-dict = $make-dict();
my $dict-time = now - $start;
ok %big-dict.elems == 1000, 'Large dict converted correctly';

# Test passing large data back to Python
my $sum-func = $py.run('sum_list', :eval);
$start = now;
my $sum = $sum-func($[@big-list[^100]]);  # Just first 100 elements, itemized
my $pass-time = now - $start;
is $sum, 4950, 'Data passed back to Python correctly';

done-testing;