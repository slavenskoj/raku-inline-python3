use v6.d;
use Test;
use Inline::Python3;

plan 8;

my $py = Inline::Python3.new;

# Test basic exception
throws-like {
    $py.run('1/0', :eval)
}, Inline::Python3::PythonError, 'Division by zero throws PythonError';

# Test exception details
try {
    $py.run('undefined_variable', :eval)
}
my $error = $!;
ok $error ~~ Inline::Python3::PythonError, 'Name error is PythonError';
ok $error.python-type ~~ /NameError/, 'Exception type is NameError';
ok $error.python-message ~~ /undefined_variable/, 'Exception message contains variable name';

# Test syntax error
throws-like {
    $py.run('def bad syntax():', :eval)
}, Inline::Python3::PythonError, message => /SyntaxError/, 'Syntax errors are caught';

# Test exception in function
$py.run(q:to/PYTHON/);
def failing_function():
    raise ValueError("This is a test error")
PYTHON

my $failing_function = $py.run('failing_function', :eval);
throws-like {
    $failing_function()
}, Inline::Python3::PythonError, message => /ValueError.*'test' .* 'error'/, 'Function exceptions bubble up';

# Test exception with traceback
$py.run(q:to/PYTHON/);
def outer():
    return inner()

def inner():
    raise RuntimeError("Deep error")
PYTHON

my $outer = $py.run('outer', :eval);
try {
    $outer()
}
$error = $!;
ok $error.python-traceback.defined, 'Traceback is captured';
ok $error.python-traceback ~~ /inner/ && $error.python-traceback ~~ /outer/, 
   'Traceback contains call stack';

done-testing;