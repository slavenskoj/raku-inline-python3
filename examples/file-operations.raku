#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== File Operations Examples ===\n";

# Import necessary modules
$py.run('import os');
$py.run('import tempfile');
$py.run('import pathlib');
$py.run('from pathlib import Path');

# Working with temporary files
say "1. Creating and using temporary files:";
$py.run(q:to/PYTHON/);
# Create a temporary file
with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as tmp:
    tmp.write("Hello from Python3!\n")
    tmp.write("This is a temporary file.\n")
    tmp.write("It will be deleted after use.\n")
    temp_filename = tmp.name

print(f"Created temporary file: {temp_filename}")
PYTHON

# Reading the file
say "\n2. Reading file contents:";
$py.run(q:to/PYTHON/);
# Read entire file
with open(temp_filename, 'r') as f:
    content = f.read()
print("Full content:")
print(content)

# Read line by line
print("Line by line:")
with open(temp_filename, 'r') as f:
    for i, line in enumerate(f, 1):
        print(f"Line {i}: {line.strip()}")
PYTHON

# File information
say "\n3. Getting file information:";
$py.run(q:to/PYTHON/);
# Using os.stat
stat_info = os.stat(temp_filename)
print(f"File size: {stat_info.st_size} bytes")
print(f"File exists: {os.path.exists(temp_filename)}")
print(f"Is file: {os.path.isfile(temp_filename)}")
print(f"File basename: {os.path.basename(temp_filename)}")
print(f"File directory: {os.path.dirname(temp_filename)}")
PYTHON

# Working with paths
say "\n4. Path operations:";
$py.run(q:to/PYTHON/);
# Using pathlib
path = Path(temp_filename)
print(f"Path name: {path.name}")
print(f"Path stem: {path.stem}")
print(f"Path suffix: {path.suffix}")
print(f"Path parent: {path.parent}")
print(f"Absolute path: {path.absolute()}")
PYTHON

# Writing different types of data
say "\n5. Writing different data types:";
$py.run(q:to/PYTHON/);
# Create another temp file for various writes
with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.dat') as tmp2:
    tmp2_name = tmp2.name
    # Write strings
    tmp2.write("String data\n")
    # Write formatted data
    tmp2.write(f"Number: {42}\n")
    tmp2.write(f"Float: {3.14159:.2f}\n")
    # Write list as string
    data_list = [1, 2, 3, 4, 5]
    tmp2.write(f"List: {data_list}\n")

# Read it back
with open(tmp2_name, 'r') as f:
    print("Written data:")
    print(f.read())

# Clean up
os.unlink(tmp2_name)
PYTHON

# Working with CSV-like data
say "\n6. Working with CSV-like data (using standard library):";
$py.run(q:to/PYTHON/);
# Create CSV data manually
csv_data = [
    ["Name", "Age", "City"],
    ["Alice", "30", "New York"],
    ["Bob", "25", "London"],
    ["Charlie", "35", "Paris"]
]

# Write CSV
with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.csv') as csv_file:
    csv_filename = csv_file.name
    for row in csv_data:
        csv_file.write(','.join(row) + '\n')

# Read CSV
print("CSV content:")
with open(csv_filename, 'r') as f:
    for line in f:
        fields = line.strip().split(',')
        print(f"  {fields}")

os.unlink(csv_filename)
PYTHON

# File operations with context managers
say "\n7. Safe file operations with context managers:";
$py.run(q:to/PYTHON/);
# Custom context manager for file operations
class FileManager:
    def __init__(self, filename, mode):
        self.filename = filename
        self.mode = mode
        self.file = None
    
    def __enter__(self):
        print(f"Opening {self.filename}")
        self.file = open(self.filename, self.mode)
        return self.file
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        print(f"Closing {self.filename}")
        if self.file:
            self.file.close()
        if exc_type:
            print(f"Exception occurred: {exc_val}")
        return False

# Use the custom context manager
temp_file = tempfile.mktemp(suffix='.txt')
with FileManager(temp_file, 'w') as f:
    f.write("Using custom context manager\n")

# Read it back
with FileManager(temp_file, 'r') as f:
    print(f"Content: {f.read().strip()}")

os.unlink(temp_file)
PYTHON

# Directory operations
say "\n8. Directory operations:";
$py.run(q:to/PYTHON/);
# Create a temporary directory
with tempfile.TemporaryDirectory() as temp_dir:
    print(f"Created temp directory: {temp_dir}")
    
    # Create some files in it
    for i in range(3):
        file_path = os.path.join(temp_dir, f"file_{i}.txt")
        with open(file_path, 'w') as f:
            f.write(f"This is file {i}\n")
    
    # List directory contents
    print("Directory contents:")
    for item in os.listdir(temp_dir):
        full_path = os.path.join(temp_dir, item)
        size = os.path.getsize(full_path)
        print(f"  {item} ({size} bytes)")
    
    # Walk directory tree
    print("\nDirectory tree:")
    for root, dirs, files in os.walk(temp_dir):
        level = root.replace(temp_dir, '').count(os.sep)
        indent = ' ' * 2 * level
        print(f"{indent}{os.path.basename(root)}/")
        subindent = ' ' * 2 * (level + 1)
        for file in files:
            print(f"{subindent}{file}")

print("Temp directory automatically cleaned up")
PYTHON

# Binary file operations
say "\n9. Binary file operations:";
$py.run(q:to/PYTHON/);
# Write binary data
binary_data = bytes([0x48, 0x65, 0x6C, 0x6C, 0x6F])  # "Hello" in ASCII
more_data = b' World!'  # Binary string literal

with tempfile.NamedTemporaryFile(mode='wb', delete=False, suffix='.bin') as bin_file:
    bin_filename = bin_file.name
    bin_file.write(binary_data)
    bin_file.write(more_data)

# Read binary data
with open(bin_filename, 'rb') as f:
    data = f.read()
    print(f"Binary data: {data}")
    print(f"As string: {data.decode('utf-8')}")
    print(f"As hex: {data.hex()}")

os.unlink(bin_filename)
PYTHON

# File manipulation
say "\n10. File manipulation and cleanup:";
$py.run(q:to/PYTHON/);
# Create a test file
test_file = tempfile.mktemp(suffix='.test')
with open(test_file, 'w') as f:
    f.write("Test file for manipulation\n")

print(f"Created: {test_file}")
print(f"Exists: {os.path.exists(test_file)}")

# Rename file
new_name = test_file.replace('.test', '_renamed.test')
os.rename(test_file, new_name)
print(f"Renamed to: {new_name}")

# Copy content to another file (manually)
copy_name = new_name.replace('_renamed', '_copy')
with open(new_name, 'r') as src:
    with open(copy_name, 'w') as dst:
        dst.write(src.read())
print(f"Copied to: {copy_name}")

# Clean up
os.unlink(new_name)
os.unlink(copy_name)
print("Files cleaned up")

# Final cleanup of the first temp file
os.unlink(temp_filename)
print(f"Cleaned up {temp_filename}")
PYTHON

say "\n=== End of File Operations Examples ===";