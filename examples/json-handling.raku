#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== JSON Handling Examples ===\n";

# Import json module
$py.run('import json');

# Basic JSON encoding
say "1. Converting Python3 objects to JSON:";
$py.run('simple_dict = {"name": "Alice", "age": 30, "active": True}');
my $json_str = $py.run('json.dumps(simple_dict)', :eval);
say "Dictionary to JSON: $json_str";

$py.run('simple_list = [1, 2, 3, "four", 5.0]');
$json_str = $py.run('json.dumps(simple_list)', :eval);
say "List to JSON: $json_str";

# Pretty printing JSON
say "\n2. Pretty printing JSON:";
$py.run(q:to/PYTHON/);
complex_data = {
    "users": [
        {"id": 1, "name": "Alice", "email": "alice@example.com"},
        {"id": 2, "name": "Bob", "email": "bob@example.com"}
    ],
    "settings": {
        "theme": "dark",
        "notifications": True,
        "language": "en"
    },
    "version": "1.0.0"
}
PYTHON

my $pretty_json = $py.run('json.dumps(complex_data, indent=2)', :eval);
say "Pretty printed JSON:";
say $pretty_json;

# JSON decoding
say "\n3. Parsing JSON strings:";
$py.run('json_string = \'{"name": "Charlie", "scores": [85, 92, 78], "passed": true}\'');
$py.run('parsed_data = json.loads(json_string)');
say "Parsed name: " ~ $py.run('parsed_data["name"]', :eval);
say "Parsed scores: " ~ $py.run('parsed_data["scores"]', :eval);
say "Parsed passed: " ~ $py.run('parsed_data["passed"]', :eval);

# Working with nested JSON
say "\n4. Working with nested JSON:";
$py.run(q:to/PYTHON/);
nested_json = '''
{
    "company": "Tech Corp",
    "employees": [
        {
            "name": "John Doe",
            "department": "Engineering",
            "skills": ["Python", "JavaScript", "SQL"]
        },
        {
            "name": "Jane Smith",
            "department": "Marketing",
            "skills": ["SEO", "Content Writing", "Analytics"]
        }
    ],
    "founded": 2010
}
'''
company_data = json.loads(nested_json)
PYTHON

say "Company: " ~ $py.run('company_data["company"]', :eval);
say "Founded: " ~ $py.run('company_data["founded"]', :eval);
say "First employee: " ~ $py.run('company_data["employees"][0]["name"]', :eval);
say "First employee skills: " ~ $py.run('company_data["employees"][0]["skills"]', :eval);

# JSON with custom separators
say "\n5. JSON with custom formatting:";
$py.run('data = {"a": 1, "b": 2, "c": 3}');
say "Compact: " ~ $py.run('json.dumps(data, separators=(",", ":"))', :eval);
say "Spaced: " ~ $py.run('json.dumps(data, separators=(", ", ": "))', :eval);

# Sorting keys
say "\n6. Sorting JSON keys:";
$py.run('unsorted = {"z": 1, "a": 2, "m": 3, "b": 4}');
say "Original: " ~ $py.run('json.dumps(unsorted)', :eval);
say "Sorted: " ~ $py.run('json.dumps(unsorted, sort_keys=True)', :eval);

# Handling special values
say "\n7. Handling special values:";
$py.run('special_values = {"infinity": float("inf"), "nan": float("nan"), "none": None}');
say "With allow_nan=True: " ~ $py.run('json.dumps(special_values)', :eval);

# JSON error handling
say "\n8. JSON error handling:";
$py.run(q:to/PYTHON/);
def safe_json_parse(json_string):
    try:
        return json.loads(json_string)
    except json.JSONDecodeError as e:
        return f"JSON Error: {e}"

valid_json = '{"valid": true}'
invalid_json = '{"invalid": true,}'
PYTHON

say "Valid JSON: " ~ $py.run('safe_json_parse(valid_json)', :eval);
say "Invalid JSON: " ~ $py.run('safe_json_parse(invalid_json)', :eval);

# Converting between Raku and Python3 via JSON
say "\n9. Raku ↔ Python3 data exchange via JSON:";
my %raku-data = (
    title => "Raku to Python",
    count => 42,
    tags => ["raku", "python", "integration"],
    metadata => {
        author => "Developer",
        version => "1.0"
    }
);

# Convert Raku hash to JSON string
$py.run('raku_data = {"title": "Raku to Python", "count": 42, "tags": ["raku", "python", "integration"], "metadata": {"author": "Developer", "version": "1.0"}}');
say "Data from Raku: " ~ $py.run('json.dumps(raku_data, indent=2)', :eval);

# Practical JSON example: Configuration file
say "\n10. Practical example - Configuration handling:";
$py.run(q:to/PYTHON/);
config = {
    "database": {
        "host": "localhost",
        "port": 5432,
        "name": "myapp",
        "credentials": {
            "username": "dbuser",
            "password": "****"
        }
    },
    "api": {
        "endpoint": "https://api.example.com",
        "timeout": 30,
        "retry_count": 3
    },
    "features": {
        "dark_mode": True,
        "beta_features": False,
        "max_upload_size": 10485760
    }
}

# Save configuration
config_json = json.dumps(config, indent=2)

# Update a setting
config["features"]["dark_mode"] = False
config["api"]["timeout"] = 60

# Get updated JSON
updated_json = json.dumps(config, indent=2)
PYTHON

say "Configuration updated:";
say "Dark mode: " ~ $py.run('config["features"]["dark_mode"]', :eval);
say "API timeout: " ~ $py.run('config["api"]["timeout"]', :eval);

say "\n=== End of JSON Handling Examples ===";