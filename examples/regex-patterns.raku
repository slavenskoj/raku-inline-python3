#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== Regular Expression Examples ===\n";

# Import re module
$py.run('import re');

# Basic pattern matching
say "1. Basic pattern matching:";
$py.run('text = "The phone number is 123-456-7890"');
$py.run('pattern = r"\d{3}-\d{3}-\d{4}"');
my $match = $py.run('re.search(pattern, text)', :eval);
say "Found phone number: " ~ $py.run('re.search(pattern, text).group() if re.search(pattern, text) else "Not found"', :eval);

# Finding all matches
say "\n2. Finding all matches:";
$py.run('text = "Email me at john@example.com or jane@test.org"');
$py.run('email_pattern = r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"');
my $emails = $py.run('re.findall(email_pattern, text)', :eval);
say "Found emails: $emails";

# Pattern with groups
say "\n3. Using capture groups:";
$py.run('date_text = "Today is 2024-06-18"');
$py.run('date_pattern = r"(\d{4})-(\d{2})-(\d{2})"');
$py.run('match = re.search(date_pattern, date_text)');
say "Full match: " ~ $py.run('match.group(0)', :eval);
say "Year: " ~ $py.run('match.group(1)', :eval);
say "Month: " ~ $py.run('match.group(2)', :eval);
say "Day: " ~ $py.run('match.group(3)', :eval);

# Named groups
say "\n4. Named capture groups:";
$py.run('log_entry = "2024-06-18 14:30:45 ERROR Failed to connect"');
$py.run('log_pattern = r"(?P<date>\d{4}-\d{2}-\d{2}) (?P<time>\d{2}:\d{2}:\d{2}) (?P<level>\w+) (?P<message>.*)"');
$py.run('log_match = re.match(log_pattern, log_entry)');
say "Log level: " ~ $py.run('log_match.group("level")', :eval);
say "Message: " ~ $py.run('log_match.group("message")', :eval);
say "Groups as dict: " ~ $py.run('log_match.groupdict()', :eval);

# String substitution
say "\n5. Pattern substitution:";
$py.run('text = "The price is $123.45 and the tax is $12.34"');
say "Original: " ~ $py.run('text', :eval);
my $masked = $py.run('re.sub(r"\$(\d+\.\d{2})", r"$***.**", text)', :eval);
say "Masked prices: $masked";

$py.run('phone = "Call me at 123-456-7890"');
my $formatted = $py.run('re.sub(r"(\d{3})-(\d{3})-(\d{4})", r"(\1) \2-\3", phone)', :eval);
say "Formatted phone: $formatted";

# Case-insensitive matching
say "\n6. Case-insensitive matching:";
$py.run('text = "Python PYTHON PyThOn"');
$py.run('pattern = r"python"');
say "Case-sensitive matches: " ~ $py.run('re.findall(pattern, text)', :eval);
say "Case-insensitive matches: " ~ $py.run('re.findall(pattern, text, re.IGNORECASE)', :eval);

# Splitting with regex
say "\n7. Splitting strings with regex:";
$py.run('text = "apple,banana;orange|grape:mango"');
my $fruits = $py.run('re.split(r"[,;|:]", text)', :eval);
say "Split by multiple delimiters: $fruits";

$py.run('sentence = "This  has   multiple     spaces"');
my $words = $py.run('re.split(r"\s+", sentence)', :eval);
say "Split by whitespace: $words";

# Validation patterns
say "\n8. Common validation patterns:";
$py.run(q:to/PYTHON/);
def validate(pattern, text):
    return bool(re.match(pattern + "$", text))

# Email validation
email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

# URL validation
url_pattern = r"^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

# IP address validation
ip_pattern = r"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

# Credit card (simplified)
cc_pattern = r"^\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}$"
PYTHON

my @test_emails = <valid@email.com invalid@email user@>;
for @test_emails -> $email {
    my $valid = $py.run("validate(email_pattern, '$email')", :eval);
    say "Is '$email' valid? $valid";
}

say "\nURL validation:";
my @test_urls = <https://example.com http://test.org not-a-url>;
for @test_urls -> $url {
    my $valid = $py.run("validate(url_pattern, '$url')", :eval);
    say "Is '$url' valid? $valid";
}

# Lookahead and lookbehind
say "\n9. Lookahead and lookbehind:";
$py.run('text = "price: $100, cost: $50, total: $150"');
# Positive lookahead - find numbers preceded by $
my $prices = $py.run('re.findall(r"(?<=\$)\d+", text)', :eval);
say "Prices (numbers after \$): $prices";

# Negative lookahead - find numbers NOT followed by %
$py.run('text2 = "Save 50% on items, regular price 100 dollars"');
my $non_percent = $py.run('re.findall(r"\d+(?!%)", text2)', :eval);
say "Numbers not followed by %: $non_percent";

# Practical example: Log parser
say "\n10. Practical example - Log file parser:";
$py.run(q:to/PYTHON/);
log_entries = """
2024-06-18 10:15:23 INFO User logged in: user123
2024-06-18 10:16:45 WARNING Failed login attempt: admin
2024-06-18 10:17:32 ERROR Database connection failed
2024-06-18 10:18:10 INFO User logged out: user123
2024-06-18 10:19:55 DEBUG Cache cleared
"""

# Parse log entries
pattern = r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (\w+) (.+)$'
entries = []

for line in log_entries.strip().split('\n'):
    match = re.match(pattern, line)
    if match:
        entries.append({
            'timestamp': match.group(1),
            'level': match.group(2),
            'message': match.group(3)
        })

# Count by level
from collections import Counter
levels = [entry['level'] for entry in entries]
level_counts = dict(Counter(levels))

# Find all ERROR entries
errors = [entry for entry in entries if entry['level'] == 'ERROR']
PYTHON

say "Log level counts: " ~ $py.run('level_counts', :eval);
say "ERROR entries: " ~ $py.run('len(errors)', :eval);
say "First error message: " ~ $py.run('errors[0]["message"] if errors else "No errors"', :eval);

say "\n=== End of Regular Expression Examples ===";