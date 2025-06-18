#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== Exception Handling Examples ===\n";

# Basic exception handling in Python
say "1. Basic Python3 exception handling:";
$py.run(q:to/PYTHON/);
def divide(a, b):
    try:
        result = a / b
        return f"Result: {result}"
    except ZeroDivisionError:
        return "Error: Cannot divide by zero"
    except TypeError:
        return "Error: Invalid types for division"
    finally:
        print("Division operation completed")

print(divide(10, 2))
print(divide(10, 0))
print(divide("10", 2))
PYTHON

# Python exceptions in Raku
say "\n2. Catching Python3 exceptions in Raku:";
try {
    $py.run('x = 1 / 0', :eval);
    CATCH {
        default {
            say "Caught Python3 exception!";
            say "  Exception: $_";
        }
    }
}

# Multiple exception types
say "\n3. Handling multiple exception types:";
$py.run(q:to/PYTHON/);
def process_data(data):
    try:
        # Try to process as a list
        return sum(data) / len(data)
    except TypeError:
        # Maybe it's a string or number?
        try:
            return float(data)
        except (ValueError, TypeError):
            return "Cannot process data: not a number or list"
    except ZeroDivisionError:
        return "Cannot calculate average of empty list"

# Test with different inputs
test_data = [
    [1, 2, 3, 4, 5],
    "42.5",
    "not a number",
    [],
    None
]

for data in test_data:
    result = process_data(data)
    print(f"process_data({data!r}) = {result}")
PYTHON

# Custom exceptions
say "\n4. Creating and using custom exceptions:";
$py.run(q:to/PYTHON/);
class ValidationError(Exception):
    """Custom exception for validation errors"""
    pass

class AgeValidationError(ValidationError):
    """Specific validation error for age"""
    def __init__(self, age):
        self.age = age
        super().__init__(f"Invalid age: {age}")

def validate_age(age):
    if not isinstance(age, (int, float)):
        raise TypeError("Age must be a number")
    if age < 0:
        raise AgeValidationError(age)
    if age > 150:
        raise AgeValidationError(age)
    return f"Valid age: {age}"

# Test the validation
test_ages = [25, -5, 200, "thirty", 0, 100]
for age in test_ages:
    try:
        print(validate_age(age))
    except AgeValidationError as e:
        print(f"Age validation failed: {e}")
    except TypeError as e:
        print(f"Type error: {e}")
PYTHON

# Exception chaining
say "\n5. Exception chaining and context:";
$py.run(q:to/PYTHON/);
def read_config(filename):
    try:
        # Simulate reading a config file
        if filename == "missing.conf":
            raise FileNotFoundError(f"Config file not found: {filename}")
        elif filename == "invalid.conf":
            raise ValueError("Invalid configuration format")
        else:
            return {"status": "ok", "file": filename}
    except Exception as e:
        # Chain the exception with additional context
        raise RuntimeError(f"Failed to load configuration") from e

# Test with different scenarios
files = ["config.conf", "missing.conf", "invalid.conf"]
for file in files:
    try:
        config = read_config(file)
        print(f"Loaded {file}: {config}")
    except RuntimeError as e:
        print(f"Runtime error: {e}")
        if e.__cause__:
            print(f"  Caused by: {e.__cause__}")
PYTHON

# Context managers with exception handling
say "\n6. Exception handling in context managers:";
$py.run(q:to/PYTHON/);
class DatabaseConnection:
    def __init__(self, name):
        self.name = name
        self.connected = False
    
    def __enter__(self):
        print(f"Connecting to {self.name}...")
        if self.name == "invalid_db":
            raise ConnectionError(f"Cannot connect to {self.name}")
        self.connected = True
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.connected:
            print(f"Disconnecting from {self.name}")
            self.connected = False
        if exc_type:
            print(f"Exception in context: {exc_type.__name__}: {exc_val}")
        # Return False to propagate the exception
        return False
    
    def query(self, sql):
        if not self.connected:
            raise RuntimeError("Not connected to database")
        if "DROP" in sql:
            raise PermissionError("DROP operations not allowed")
        return f"Query result for: {sql}"

# Test different scenarios
databases = ["valid_db", "invalid_db"]
queries = ["SELECT * FROM users", "DROP TABLE users"]

for db in databases:
    for query in queries:
        try:
            with DatabaseConnection(db) as conn:
                result = conn.query(query)
                print(f"Success: {result}")
        except (ConnectionError, PermissionError, RuntimeError) as e:
            print(f"Database error: {e}")
        print()
PYTHON

# Exception groups (Python3 3.11+ concept, simulated)
say "\n7. Handling multiple exceptions together:";
$py.run(q:to/PYTHON/);
def validate_user_data(data):
    errors = []
    
    if "name" not in data:
        errors.append(KeyError("Missing required field: name"))
    elif not data["name"]:
        errors.append(ValueError("Name cannot be empty"))
    
    if "age" in data:
        try:
            age = int(data["age"])
            if age < 0 or age > 150:
                errors.append(ValueError(f"Invalid age: {age}"))
        except ValueError:
            errors.append(TypeError(f"Age must be a number, got: {data['age']}"))
    
    if "email" in data and "@" not in data.get("email", ""):
        errors.append(ValueError("Invalid email format"))
    
    if errors:
        error_messages = [str(e) for e in errors]
        raise ValueError(f"Validation failed with {len(errors)} errors: " + "; ".join(error_messages))
    
    return "Validation passed"

# Test with various data
test_users = [
    {"name": "Alice", "age": "30", "email": "alice@example.com"},
    {"name": "", "age": "200", "email": "invalid-email"},
    {"age": "not-a-number"},
    {"name": "Bob", "age": "25"}
]

for user_data in test_users:
    try:
        result = validate_user_data(user_data)
        print(f"✓ {user_data}: {result}")
    except ValueError as e:
        print(f"✗ {user_data}: {e}")
PYTHON

# Raku-Python3 exception interop
say "\n8. Advanced Raku-Python3 exception handling:";
for <divide_by_zero type_error name_error syntax_error> -> $error_type {
    try {
        given $error_type {
            when 'divide_by_zero' { $py.run('1 / 0', :eval) }
            when 'type_error' { $py.run('"string" + 123', :eval) }
            when 'name_error' { $py.run('undefined_variable', :eval) }
            when 'syntax_error' { $py.run('if True print("bad syntax")', :eval) }
        }
        CATCH {
            default {
                say "Error type '$error_type' caught:";
                say "  Exception: $_";
            }
        }
    }
}

# Cleanup and exception safety
say "\n9. Exception safety and cleanup:";
$py.run(q:to/PYTHON/);
class Resource:
    def __init__(self, name):
        self.name = name
        self.acquired = False
        print(f"Creating resource: {name}")
    
    def acquire(self):
        print(f"Acquiring resource: {self.name}")
        self.acquired = True
    
    def release(self):
        if self.acquired:
            print(f"Releasing resource: {self.name}")
            self.acquired = False
    
    def use(self):
        if not self.acquired:
            raise RuntimeError(f"Resource {self.name} not acquired")
        print(f"Using resource: {self.name}")

def safe_resource_usage(should_fail=False):
    resource = None
    try:
        resource = Resource("important_data")
        resource.acquire()
        resource.use()
        if should_fail:
            raise Exception("Simulated failure")
        return "Operation completed successfully"
    except Exception as e:
        return f"Operation failed: {e}"
    finally:
        if resource:
            resource.release()

# Test both success and failure scenarios
print("Successful operation:")
print(safe_resource_usage(False))
print("\nFailed operation:")
print(safe_resource_usage(True))
PYTHON

# Practical example: Robust file processor
say "\n10. Practical example - Robust file processor:";
$py.run(q:to/PYTHON/);
import tempfile
import os

def process_file(filename, operation):
    """Process a file with comprehensive error handling"""
    file_handle = None
    temp_file = None
    
    try:
        # Open the file
        try:
            file_handle = open(filename, 'r')
        except FileNotFoundError:
            return f"Error: File '{filename}' not found"
        except PermissionError:
            return f"Error: Permission denied for '{filename}'"
        
        # Read content
        content = file_handle.read()
        
        # Process content based on operation
        if operation == "uppercase":
            result = content.upper()
        elif operation == "wordcount":
            result = f"Word count: {len(content.split())}"
        elif operation == "reverse":
            result = content[::-1]
        else:
            raise ValueError(f"Unknown operation: {operation}")
        
        return f"Success: {result[:50]}..." if len(str(result)) > 50 else f"Success: {result}"
        
    except Exception as e:
        return f"Processing error: {type(e).__name__}: {e}"
    
    finally:
        # Ensure cleanup happens
        if file_handle:
            file_handle.close()
            print(f"Closed file: {filename}")

# Create test file
test_content = "Hello World! This is a test file for exception handling."
with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
    tmp.write(test_content)
    temp_filename = tmp.name

# Test various scenarios
operations = ["uppercase", "wordcount", "reverse", "invalid_op"]
for op in operations:
    result = process_file(temp_filename, op)
    print(f"Operation '{op}': {result}")

# Test with non-existent file
result = process_file("non_existent.txt", "uppercase")
print(f"Non-existent file: {result}")

# Cleanup
os.unlink(temp_filename)
PYTHON

say "\n=== End of Exception Handling Examples ===";