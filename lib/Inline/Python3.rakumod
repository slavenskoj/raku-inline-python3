unit class Inline::Python3;

use NativeCall;
use Inline::Python3::Config;

# Native function declarations
sub get-helper-lib() {
    # First try to load from resources (installed version)
    return %?RESOURCES<libraries/python3_helper> if %?RESOURCES<libraries/python3_helper>;
    
    # Fallback to local development path
    my $lib-name = $*DISTRO.is-win ?? 'python3_helper.dll' !!
                   $*DISTRO.name eq 'macos' ?? 'libpython3_helper.dylib' !!
                   'libpython3_helper.so';
    my $local-lib = $*CWD.add("resources/libraries/$lib-name");
    return $local-lib.Str if $local-lib.e;
    
    die "Python3 helper library not found";
}

my constant $helper = &get-helper-lib();

class PythonObject { ... }
class PythonProxy { ... }
class PythonError { ... }
role PythonParent { ... }

# Type cache for method lookups
my class TypeCache {
    has %.method-cache;
    has %.attr-cache;
    has Str $.type-name;
    
    method get-method(Str $name, $obj) {
        %!method-cache{$name} //= do {
            my $method = python3_get_attr($obj.ptr, $name);
            $method ?? PythonObject.new(:ptr($method), :python($obj.python)) !! Nil;
        }
    }
    
    method clear() {
        %!method-cache = ();
        %!attr-cache = ();
    }
}

# Buffer pool for string conversions
my class BufferPool {
    has @.buffers;
    has $.max-size = 4096;
    has $.max-buffers = 16;
    
    method get-buffer(Int $size) {
        if $size <= $!max-size && @!buffers {
            return @!buffers.shift;
        }
        return buf8.allocate($size);
    }
    
    method return-buffer($buffer) {
        if $buffer.elems <= $!max-size && @!buffers.elems < $!max-buffers {
            @!buffers.push($buffer);
        }
    }
}

# Global type cache for method lookups
my %type-cache;

# Object registry for Raku objects passed to Python
my class ObjectRegistry {
    has @.objects;
    has @.free-slots;
    
    method register($object) {
        if @!free-slots {
            my $idx = @!free-slots.shift;
            @!objects[$idx] = $object;
            return $idx;
        } else {
            @!objects.push($object);
            return @!objects.end;
        }
    }
    
    method get(Int $idx) {
        @!objects[$idx]
    }
    
    method unregister(Int $idx) {
        @!objects[$idx] = Nil;
        @!free-slots.push($idx);
    }
}

# Native callbacks
sub python3_init_python(&call_object (int32, Pointer, Pointer --> Pointer), 
                        &call_method (int32, Str, Pointer, Pointer --> Pointer) --> int32)
    is native($helper) { * }

sub python3_destroy_python(--> int32)
    is native($helper) { * }

# Error handling
sub python3_fetch_error(CArray[Pointer])
    is native($helper) { * }

# Type checking
sub python3_is_none(Pointer --> int32) is native($helper) { * }
sub python3_is_bool(Pointer --> int32) is native($helper) { * }
sub python3_is_int(Pointer --> int32) is native($helper) { * }
sub python3_is_float(Pointer --> int32) is native($helper) { * }
sub python3_is_str(Pointer --> int32) is native($helper) { * }
sub python3_is_bytes(Pointer --> int32) is native($helper) { * }
sub python3_is_list(Pointer --> int32) is native($helper) { * }
sub python3_is_tuple(Pointer --> int32) is native($helper) { * }
sub python3_is_dict(Pointer --> int32) is native($helper) { * }
sub python3_is_set(Pointer --> int32) is native($helper) { * }
sub python3_is_callable(Pointer --> int32) is native($helper) { * }
sub python3_is_module(Pointer --> int32) is native($helper) { * }
sub python3_is_type(Pointer --> int32) is native($helper) { * }

# Conversions
sub python3_int_to_long(Pointer --> int64) is native($helper) { * }
sub python3_float_to_double(Pointer --> num64) is native($helper) { * }
sub python3_bool_to_int(Pointer --> int32) is native($helper) { * }
sub python3_str_to_utf8(Pointer, CArray[int64] --> Str) is native($helper) { * }

# Object creation
sub python3_none(--> Pointer) is native($helper) { * }
sub python3_bool_from_int(int32 --> Pointer) is native($helper) { * }
sub python3_int_from_long(int64 --> Pointer) is native($helper) { * }
sub python3_float_from_double(num64 --> Pointer) is native($helper) { * }
sub python3_str_from_utf8(Str, int64 --> Pointer) is native($helper) { * }
sub python3_bytes_to_buf(Pointer, CArray[int64] --> Pointer) is native($helper) { * }
sub python3_bytes_from_buffer(Blob, int64 --> Pointer) is native($helper) { * }

# Collections
sub python3_list_new(int64 --> Pointer) is native($helper) { * }
sub python3_list_set_item(Pointer, int64, Pointer --> int32) is native($helper) { * }
sub python3_list_get_item(Pointer, int64 --> Pointer) is native($helper) { * }
sub python3_list_size(Pointer --> int64) is native($helper) { * }

sub python3_tuple_new(int64 --> Pointer) is native($helper) { * }
sub python3_tuple_set_item(Pointer, int64, Pointer --> int32) is native($helper) { * }
sub python3_tuple_get_item(Pointer, int64 --> Pointer) is native($helper) { * }
sub python3_tuple_size(Pointer --> int64) is native($helper) { * }

sub python3_dict_new(--> Pointer) is native($helper) { * }
sub python3_dict_set_item(Pointer, Pointer, Pointer --> int32) is native($helper) { * }
sub python3_dict_get_item(Pointer, Pointer --> Pointer) is native($helper) { * }
sub python3_dict_keys(Pointer --> Pointer) is native($helper) { * }
sub python3_dict_values(Pointer --> Pointer) is native($helper) { * }
sub python3_dict_items(Pointer --> Pointer) is native($helper) { * }
sub python3_dict_size(Pointer --> int64) is native($helper) { * }

# Object operations
sub python3_get_attr(Pointer, Str --> Pointer) is native($helper) { * }
sub python3_set_attr(Pointer, Str, Pointer --> int32) is native($helper) { * }
sub python3_has_attr(Pointer, Str --> int32) is native($helper) { * }
sub python3_dir(Pointer --> Pointer) is native($helper) { * }
sub python3_type(Pointer --> Pointer) is native($helper) { * }
sub python3_str(Pointer --> Pointer) is native($helper) { * }
sub python3_repr(Pointer --> Pointer) is native($helper) { * }

# Import and execution
sub python3_import(Str --> Pointer) is native($helper) { * }
sub python3_import_from(Str, Str --> Pointer) is native($helper) { * }
sub python3_eval(Str, Pointer, Pointer --> Pointer) is native($helper) { * }
sub python3_exec(Str, Pointer, Pointer --> Pointer) is native($helper) { * }

# Function calling
sub python3_call(Pointer, Pointer, Pointer --> Pointer) is native($helper) { * }
sub python3_call_method(Pointer, Str, Pointer, Pointer --> Pointer) is native($helper) { * }

# Reference counting
sub python3_inc_ref(Pointer) is native($helper) { * }
sub python3_dec_ref(Pointer) is native($helper) { * }
sub python3_ref_count(Pointer --> int64) is native($helper) { * }

# Instance variables
has PythonConfig $.config;
has &!call-object;
has &!call-method;
has ObjectRegistry $!registry .= new;
has BufferPool $!buffer-pool .= new;
has %!type-cache;
has Pointer $!globals;  # Persistent Python globals dictionary

# Python error class
class PythonError is Exception {
    has Str $.python-type;
    has Str $.python-message;
    has Str $.python-traceback;
    
    method message() {
        my $msg = "Python $.python-type: $.python-message";
        $msg ~= "\n$.python-traceback" if $.python-traceback;
        $msg
    }
}

# Lazy proxy for Python objects
class PythonProxy {
    has Pointer $.ptr;
    has Inline::Python3 $.python;
    has Bool $!converted = False;
    has $!raku-value;
    
    method raku-value() {
        unless $!converted {
            $!raku-value = $!python.py-to-raku($!ptr);
            $!converted = True;
        }
        $!raku-value
    }
    
    method Str() { self.raku-value.Str }
    method Num() { self.raku-value.Num }
    method Int() { self.raku-value.Int }
    method Bool() { self.raku-value.Bool }
    method gist() { self.raku-value.gist }
    
    method DESTROY() {
        python3_dec_ref($!ptr) if $!ptr;
    }
}

# Main Python object wrapper
class PythonObject {
    has Pointer $.ptr;
    has Inline::Python3 $.python;
    has TypeCache $!type-cache;
    
    submethod BUILD(:$!ptr, :$!python) {
        python3_inc_ref($!ptr);
        my $type-obj = python3_type($!ptr);
        my $type-name-obj = python3_str($type-obj);
        my $size = CArray[int64].new;
        $size[0] = 0;
        my $type-name = python3_str_to_utf8($type-name-obj, $size);
        python3_dec_ref($type-obj);
        python3_dec_ref($type-name-obj);
        
        $!type-cache = %type-cache{$type-name} //= TypeCache.new(:$type-name);
    }
    
    method CALL-ME(*@args, *%kwargs) {
        #note "CALL-ME: args={@args.gist}, kwargs={%kwargs.gist}" if %kwargs;
        $!python.call-object(self, |@args, |%kwargs)
    }
    
    method sink() { self }
    
    method DESTROY() {
        python3_dec_ref($!ptr) if $!ptr;
    }
}

# Role for Python inheritance
role PythonParent[$module, $class] {
    has PythonObject $.python-object;
    has Bool $!subclass-created = False;
    
    submethod BUILD(:$!python-object) {
        unless $!subclass-created {
            self!create-subclass;
            $!subclass-created = True;
        }
        
        # Create or upgrade Python object
        $!python-object //= self!create-python-object;
    }
    
    method !create-subclass() {
        my $python = $*PYTHON3 // Inline::Pythonic.new;
        # Implementation for creating Python subclass
    }
    
    method !create-python-object() {
        my $python = $*PYTHON3 // Inline::Pythonic.new;
        # Implementation for creating Python object
    }
}

# Initialization
method BUILD() {
    $!config = PythonConfig.new;
    $!config.detect-python;
    
    &!call-object = sub (int32 $idx, Pointer $args, Pointer $err --> Pointer) {
        my $obj = $!registry.get($idx);
        return Pointer unless $obj;
        
        CATCH {
            default {
                nativecast(CArray[Pointer], $err)[0] = self.raku-to-py($_.Str);
                return Pointer;
            }
        }
        
        my @args = self.py-to-raku($args);
        my $result = $obj(|@args);
        return self.raku-to-py($result);
    };
    
    &!call-method = sub (int32 $idx, Str $name, Pointer $args, Pointer $err --> Pointer) {
        my $obj = $!registry.get($idx);
        return Pointer unless $obj;
        
        CATCH {
            default {
                nativecast(CArray[Pointer], $err)[0] = self.raku-to-py($_.Str);
                return Pointer;
            }
        }
        
        my @args = self.py-to-raku($args);
        my $result = $obj."$name"(|@args);
        return self.raku-to-py($result);
    };
    
    my $status = python3_init_python(&!call-object, &!call-method);
    die "Failed to initialize Python" if $status != 0;
    
    # Create persistent globals dictionary with __builtins__
    $!globals = python3_dict_new();
    my $builtins = python3_import('builtins');
    python3_dict_set_item($!globals, self.raku-to-py('__builtins__'), $builtins);
    
    # Set __name__ to __main__
    python3_dict_set_item($!globals, self.raku-to-py('__name__'), self.raku-to-py('__main__'));
    
    # Initialize Python environment
    self.run(q:to/PYTHON/);
        import sys
        
        # Set up better error handling
        sys.excepthook = lambda type, value, traceback: None
        PYTHON
}

# Error handling
method !handle-python-error() {
    my @error := CArray[Pointer].new;
    @error[$_] = Pointer for ^4;
    
    python3_fetch_error(@error);
    return unless @error[0];
    
    my $type-obj = @error[0];
    my $value-obj = @error[1];
    my $tb-obj = @error[2];
    my $formatted = @error[3];
    
    my $type-name = "Unknown";
    if $type-obj {
        my $type-str = python3_str($type-obj);
        my $size = CArray[int64].new;
        $size[0] = 0;
        $type-name = python3_str_to_utf8($type-str, $size);
        python3_dec_ref($type-str);
    }
    
    my $message = "";
    if $value-obj {
        my $msg-str = python3_str($value-obj);
        my $size = CArray[int64].new;
        $size[0] = 0;
        $message = python3_str_to_utf8($msg-str, $size);
        python3_dec_ref($msg-str);
    }
    
    my $traceback = "";
    if $formatted {
        $traceback = nativecast(Str, $formatted);
    }
    
    # Clean up
    python3_dec_ref($_) for @error[^3];
    
    die PythonError.new(
        :python-type($type-name),
        :python-message($message),
        :python-traceback($traceback)
    );
}

# Type conversion: Python to Raku
multi method py-to-raku(Pointer $ptr) {
    return Any unless $ptr;
    
    # Check type and convert accordingly
    if python3_is_none($ptr) {
        return Any;
    }
    elsif python3_is_bool($ptr) {
        return python3_bool_to_int($ptr) ?? True !! False;
    }
    elsif python3_is_int($ptr) {
        return python3_int_to_long($ptr);
    }
    elsif python3_is_float($ptr) {
        return python3_float_to_double($ptr);
    }
    elsif python3_is_str($ptr) {
        my $size = CArray[int64].new;
        $size[0] = 0;
        return python3_str_to_utf8($ptr, $size);
    }
    elsif python3_is_bytes($ptr) {
        # Handle bytes
        # Get bytes as string
        my $size = CArray[int64].new;
        $size[0] = 0;
        my $bytes = python3_bytes_to_buf($ptr, $size);
        return Blob.new(nativecast(CArray[uint8], $bytes)[^$size[0]]);
    }
    elsif python3_is_list($ptr) || python3_is_tuple($ptr) {
        # Convert lists/tuples directly
        my $size = python3_is_list($ptr) ?? python3_list_size($ptr) !! python3_tuple_size($ptr);
        my @result;
        for ^$size -> $i {
            my $item = python3_is_list($ptr) ?? python3_list_get_item($ptr, $i) !! python3_tuple_get_item($ptr, $i);
            @result.push(self.py-to-raku($item));
        }
        return @result;
    }
    elsif python3_is_dict($ptr) {
        # Convert dicts directly
        my %result;
        my $keys = python3_dict_keys($ptr);
        my $size = python3_list_size($keys);
        for ^$size -> $i {
            my $key = python3_list_get_item($keys, $i);
            my $value = python3_dict_get_item($ptr, $key);
            my $raku-key = self.py-to-raku($key);
            %result{$raku-key} = self.py-to-raku($value);
        }
        python3_dec_ref($keys);
        return %result;
    }
    else {
        # Return as PythonObject
        return PythonObject.new(:$ptr, :python(self));
    }
}

# Type conversion: Raku to Python
multi method raku-to-py(Any:U) { python3_none() }
multi method raku-to-py(Bool:D $val) { python3_bool_from_int($val ?? 1 !! 0) }
multi method raku-to-py(Int:D $val) { python3_int_from_long($val) }
multi method raku-to-py(Num:D $val) { python3_float_from_double($val) }
multi method raku-to-py(Rat:D $val) { python3_float_from_double($val.Num) }
multi method raku-to-py(Str:D $val) { 
    my $buf = $val.encode;
    python3_str_from_utf8($val, $buf.bytes)
}
multi method raku-to-py(Blob:D $val) {
    python3_bytes_from_buffer($val, $val.bytes)
}
multi method raku-to-py(Positional:D $val) {
    my $list = python3_list_new($val.elems);
    for $val.kv -> $i, $item {
        python3_list_set_item($list, $i, self.raku-to-py($item));
    }
    $list
}
multi method raku-to-py(Associative:D $val) {
    my $dict = python3_dict_new();
    for $val.kv -> $k, $v {
        python3_dict_set_item($dict, self.raku-to-py($k), self.raku-to-py($v));
    }
    $dict
}
multi method raku-to-py(PythonObject:D $val) { $val.ptr }
multi method raku-to-py(PythonProxy:D $val) { $val.ptr }

# Public API
method run(Str $code, :$eval = False) {
    my $result = $eval 
        ?? python3_eval($code, $!globals, $!globals)
        !! python3_exec($code, $!globals, $!globals);
    
    self!handle-python-error();
    
    return self.py-to-raku($result);
}

method import(Str $module) {
    my $py-module = python3_import($module);
    self!handle-python-error();
    
    return PythonObject.new(:ptr($py-module), :python(self));
}

method call(Str $module, Str $function, *@args, *%kwargs) {
    my $func = python3_import_from($module, $function);
    self!handle-python-error();
    
    my $result = self.call-object(PythonObject.new(:ptr($func), :python(self)), |@args, |%kwargs);
    python3_dec_ref($func);
    
    return $result;
}

method call-object(PythonObject $obj, *@args, *%kwargs) {
    # Debug: print what we're calling with
    #note "call-object: obj={$obj.ptr}, args={@args.elems} items: {@args.gist}, kwargs={%kwargs.gist}" if %kwargs;
    
    my $args-tuple = self!build-args-tuple(@args);
    my $kwargs-dict = %kwargs ?? self!build-kwargs-dict(%kwargs) !! Pointer.new(0);
    
    # Debug: Check if kwargs dict was created
    if $kwargs-dict && $kwargs-dict != Pointer.new(0) {
        #note "Created kwargs dict with {python3_dict_size($kwargs-dict)} items";
    }
    
    #note "About to call python3_call with kwargs-dict = ", $kwargs-dict.defined ?? $kwargs-dict.gist !! "undefined";
    my $result = python3_call($obj.ptr, $args-tuple, $kwargs-dict);
    
    python3_dec_ref($args-tuple);
    python3_dec_ref($kwargs-dict) if %kwargs;
    
    self!handle-python-error();
    
    return self.py-to-raku($result);
}

method !build-args-tuple(@args) {
    my $tuple = python3_tuple_new(@args.elems);
    for @args.kv -> $i, $arg {
        python3_tuple_set_item($tuple, $i, self.raku-to-py($arg));
    }
    $tuple
}

method !build-kwargs-dict(%kwargs) {
    return Pointer.new(0) unless %kwargs;
    
    my $dict = python3_dict_new();
    for %kwargs.kv -> $k, $v {
        #note "Adding kwarg: $k => $v";
        python3_dict_set_item($dict, self.raku-to-py($k), self.raku-to-py($v));
    }
    #note "Built kwargs dict with {python3_dict_size($dict)} items";
    $dict
}

# Make PythonObject work with method calls
PythonObject.^add_fallback(-> $, $ { True },
    method (Str $name, |args) {
        my $python = self.python;
        #note "Fallback called: name=$name, args={args.gist}";
        
        # First check if the attribute exists
        if python3_has_attr(self.ptr, $name) {
            # Get the attribute to check if it's callable
            my $attr = python3_get_attr(self.ptr, $name);
            $python!handle-python-error();
            
            # If called with arguments, check if it's callable first
            if args.elems > 0 || args.hash {
                if python3_is_callable($attr) {
                    # It's callable, so we can call it with arguments
                    my $args-tuple = $python!build-args-tuple(args.list);
                    my $kwargs-dict = args.hash ?? $python!build-kwargs-dict(args.hash) !! Pointer.new(0);
                    
                    my $result = python3_call($attr, $args-tuple, $kwargs-dict);
                    
                    python3_dec_ref($args-tuple);
                    python3_dec_ref($kwargs-dict) if args.hash;
                    python3_dec_ref($attr);
                    
                    $python!handle-python-error();
                    
                    return $python.py-to-raku($result);
                } else {
                    # Not callable but called with arguments - error
                    python3_dec_ref($attr);
                    die "TypeError: '$name' object is not callable";
                }
            } else {
                # No arguments - could be attribute access or method reference
                # We already have $attr from above
                if python3_is_callable($attr) {
                    # It's a method - we need to be careful about reference counting
                    # Create a PythonObject to manage the reference
                    my $method-obj = PythonObject.new(:ptr($attr), :python($python));
                    
                    # Return a closure that calls the method properly
                    # Note: When this closure is called via $obj.method(), Raku passes
                    # $obj as the first argument (invocant). We need to skip it.
                    return sub ($invocant?, |c) {
                        # Skip the invocant if it's the same as our parent object
                        # Use call-object which handles everything correctly
                        return $python.call-object($method-obj, |c);
                    };
                } else {
                    # It's a regular attribute - convert and return
                    my $value = $python.py-to-raku($attr);
                    python3_dec_ref($attr);
                    
                    # Return a callable that returns the value
                    # This handles Raku's $obj.attr syntax
                    return sub ($invocant?, |c) { 
                        # If called with arguments, it's an error
                        die "TypeError: '$name' object is not callable" if c.elems > 0 || c.hash;
                        $value 
                    };
                }
            }
        } else {
            $python!handle-python-error();  # This will throw the proper Python AttributeError
            die "No such method or attribute '$name'";
        }
    }
);

# Global instance management
my Inline::Python3 $*PYTHON3;

method global() {
    $*PYTHON3 //= self.new;
}

END {
    python3_destroy_python() if $*PYTHON3;
}