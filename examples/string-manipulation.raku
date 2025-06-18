#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== String Manipulation Examples ===\n";

# Basic string operations
say "1. Basic string operations:";
$py.run('text = "  Hello, Python3 World!  "');
say "Original: '" ~ $py.run('text', :eval) ~ "'";
say "strip(): '" ~ $py.run('text.strip()', :eval) ~ "'";
say "lower(): '" ~ $py.run('text.lower()', :eval) ~ "'";
say "upper(): '" ~ $py.run('text.upper()', :eval) ~ "'";
say "title(): '" ~ $py.run('text.title()', :eval) ~ "'";
say "swapcase(): '" ~ $py.run('text.swapcase()', :eval) ~ "'";

# String methods
say "\n2. String searching and testing:";
$py.run('sentence = "The quick brown fox jumps over the lazy dog"');
say "sentence = " ~ $py.run('sentence', :eval);
say "startswith('The'): " ~ $py.run('sentence.startswith("The")', :eval);
say "endswith('dog'): " ~ $py.run('sentence.endswith("dog")', :eval);
say "find('fox'): " ~ $py.run('sentence.find("fox")', :eval);
say "count('o'): " ~ $py.run('sentence.count("o")', :eval);
say "'fox' in sentence: " ~ $py.run('"fox" in sentence', :eval);

# String replacement
say "\n3. String replacement:";
say "replace('fox', 'cat'): " ~ $py.run('sentence.replace("fox", "cat")', :eval);
say "replace('o', '0'): " ~ $py.run('sentence.replace("o", "0")', :eval);
say "replace('the', 'THE', 1): " ~ $py.run('sentence.replace("the", "THE", 1)', :eval);

# Splitting and joining
say "\n4. Splitting and joining strings:";
my $words = $py.run('sentence.split()', :eval);
say "split(): $words";
say "split(' ', 3): " ~ $py.run('sentence.split(" ", 3)', :eval);

$py.run('words = ["Join", "these", "words", "together"]');
say "\nwords = " ~ $py.run('words', :eval);
say "' '.join(words): " ~ $py.run('" ".join(words)', :eval);
say "'-'.join(words): " ~ $py.run('"-".join(words)', :eval);
say "''.join(words): " ~ $py.run('"".join(words)', :eval);

# String formatting
say "\n5. String formatting:";
$py.run('name = "Alice"');
$py.run('age = 30');
$py.run('height = 5.6');

say "Old style: " ~ $py.run('"Name: %s, Age: %d, Height: %.1f" % (name, age, height)', :eval);
say "format(): " ~ $py.run('"Name: {}, Age: {}, Height: {:.1f}".format(name, age, height)', :eval);
say "f-string: " ~ $py.run('f"Name: {name}, Age: {age}, Height: {height:.1f}"', :eval);
say "f-string with expression: " ~ $py.run('f"{name} will be {age + 1} next year"', :eval);

# String alignment
say "\n6. String alignment and padding:";
$py.run('text = "Python"');
say "center(20, '*'): '" ~ $py.run('text.center(20, "*")', :eval) ~ "'";
say "ljust(15, '-'): '" ~ $py.run('text.ljust(15, "-")', :eval) ~ "'";
say "rjust(15, '-'): '" ~ $py.run('text.rjust(15, "-")', :eval) ~ "'";
say "zfill(10): '" ~ $py.run('"42".zfill(10)', :eval) ~ "'";

# Character operations
say "\n7. Character operations:";
say "ord('A'): " ~ $py.run('ord("A")', :eval);
say "chr(65): " ~ $py.run('chr(65)', :eval);
say "chr(0x03B1): " ~ $py.run('chr(0x03B1)', :eval) ~ " (Greek alpha)";

# String validation
say "\n8. String validation methods:";
$py.run('tests = ["hello", "Hello123", "123", "   ", ""]');
say "Testing strings: " ~ $py.run('tests', :eval);
for 0..4 -> $i {
    $py.run("s = tests[$i]");
    my $s = $py.run('s', :eval);
    my $repr = $py.run('repr(s)', :eval);
    say "\n  $repr:";
    say "    isalpha(): " ~ $py.run('s.isalpha()', :eval);
    say "    isdigit(): " ~ $py.run('s.isdigit()', :eval);
    say "    isalnum(): " ~ $py.run('s.isalnum()', :eval);
    say "    isspace(): " ~ $py.run('s.isspace()', :eval);
    say "    islower(): " ~ $py.run('s.islower()', :eval);
}

# Multi-line strings
say "\n9. Multi-line string handling:";
$py.run(q:to/PYTHON/);
multiline = """First line
    Second line with indent
        Third line with more indent
Last line"""
PYTHON
say "Original multiline string:";
say $py.run('multiline', :eval);
say "\nAfter splitlines():";
my $lines = $py.run('multiline.splitlines()', :eval);
say $lines;

# String slicing
say "\n10. String slicing:";
$py.run('alphabet = "abcdefghijklmnopqrstuvwxyz"');
say "alphabet = " ~ $py.run('alphabet', :eval);
say "alphabet[5:10] = " ~ $py.run('alphabet[5:10]', :eval);
say "alphabet[:5] = " ~ $py.run('alphabet[:5]', :eval);
say "alphabet[-5:] = " ~ $py.run('alphabet[-5:]', :eval);
say "alphabet[::2] = " ~ $py.run('alphabet[::2]', :eval);
say "alphabet[::-1] = " ~ $py.run('alphabet[::-1]', :eval);

say "\n=== End of String Manipulation Examples ===";