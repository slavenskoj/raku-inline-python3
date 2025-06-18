#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== Python3 Data Structures Examples ===\n";

# Lists
say "1. Working with Lists:";
$py.run('numbers = [1, 2, 3, 4, 5]');
say "Original list: " ~ $py.run('numbers', :eval);

$py.run('numbers.append(6)');
say "After append(6): " ~ $py.run('numbers', :eval);

$py.run('numbers.insert(0, 0)');
say "After insert(0, 0): " ~ $py.run('numbers', :eval);

$py.run('numbers.pop()');
say "After pop(): " ~ $py.run('numbers', :eval);

$py.run('numbers.reverse()');
say "After reverse(): " ~ $py.run('numbers', :eval);

# List slicing
say "\n2. List slicing:";
$py.run('letters = ["a", "b", "c", "d", "e", "f"]');
say "letters = " ~ $py.run('letters', :eval);
say "letters[2:5] = " ~ $py.run('letters[2:5]', :eval);
say "letters[:3] = " ~ $py.run('letters[:3]', :eval);
say "letters[3:] = " ~ $py.run('letters[3:]', :eval);
say "letters[::2] = " ~ $py.run('letters[::2]', :eval);

# Dictionaries
say "\n3. Working with Dictionaries:";
$py.run('person = {"name": "Alice", "age": 30, "city": "New York"}');
say "person = " ~ $py.run('person', :eval);

say "Keys: " ~ $py.run('list(person.keys())', :eval);
say "Values: " ~ $py.run('list(person.values())', :eval);
say "Items: " ~ $py.run('list(person.items())', :eval);

$py.run('person["email"] = "alice@example.com"');
say "After adding email: " ~ $py.run('person', :eval);

my $has_age = $py.run('"age" in person', :eval);
say "Has 'age' key: $has_age";

# Sets
say "\n4. Working with Sets:";
$py.run('set1 = {1, 2, 3, 4, 5}');
$py.run('set2 = {4, 5, 6, 7, 8}');
say "set1 = " ~ $py.run('set1', :eval);
say "set2 = " ~ $py.run('set2', :eval);

say "Union: " ~ $py.run('set1 | set2', :eval);
say "Intersection: " ~ $py.run('set1 & set2', :eval);
say "Difference (set1 - set2): " ~ $py.run('set1 - set2', :eval);
say "Symmetric difference: " ~ $py.run('set1 ^ set2', :eval);

# Tuples
say "\n5. Working with Tuples:";
$py.run('point = (3, 5)');
say "point = " ~ $py.run('point', :eval);
say "point[0] = " ~ $py.run('point[0]', :eval);
say "point[1] = " ~ $py.run('point[1]', :eval);

$py.run('x, y = point');
say "Unpacked: x = " ~ $py.run('x', :eval) ~ ", y = " ~ $py.run('y', :eval);

# Nested structures
say "\n6. Nested data structures:";
$py.run(q:to/PYTHON/);
matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]
PYTHON
say "Matrix: " ~ $py.run('matrix', :eval);
say "matrix[1][2] = " ~ $py.run('matrix[1][2]', :eval);

$py.run(q:to/PYTHON/);
users = {
    "user1": {"name": "Alice", "age": 30},
    "user2": {"name": "Bob", "age": 25},
    "user3": {"name": "Charlie", "age": 35}
}
PYTHON
say "\nNested dictionary: " ~ $py.run('users', :eval);
say "users['user2']['name'] = " ~ $py.run('users["user2"]["name"]', :eval);

# List comprehensions with data structures
say "\n7. Comprehensions:";
my $squares = $py.run('[x**2 for x in range(10) if x % 2 == 0]', :eval);
say "Even squares: $squares";

my $dict_comp = $py.run('{x: x**2 for x in range(5)}', :eval);
say "Dictionary comprehension: $dict_comp";

my $set_comp = $py.run('{x % 5 for x in range(20)}', :eval);
say "Set comprehension: $set_comp";

# Converting between Raku and Python
say "\n8. Raku ↔ Python3 conversions:";
my @raku-array = <apple banana cherry>;
$py.run('fruits = ["apple", "banana", "cherry"]');
say "Raku array → Python3 list: " ~ $py.run('fruits', :eval);

my %raku-hash = (red => '#FF0000', green => '#00FF00', blue => '#0000FF');
$py.run('colors = {"red": "#FF0000", "green": "#00FF00", "blue": "#0000FF"}');
say "Raku hash → Python3 dict: " ~ $py.run('colors', :eval);

# Getting Python3 data back to Raku
my @py-list = $py.run('[10, 20, 30, 40, 50]', :eval);
say "Python3 list → Raku array: @py-list[]";

my %py-dict = $py.run('{"a": 1, "b": 2, "c": 3}', :eval);
say "Python3 dict → Raku hash: " ~ %py-dict.raku;

say "\n=== End of Data Structures Examples ===";