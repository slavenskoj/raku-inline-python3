use v6.d;

# Module to fix the PythonObject fallback issue

# We need to patch the PythonObject class after it's loaded
INIT {
    # Get the PythonObject class
    my $py-obj-class = ::('Inline::Python3::PythonObject');
    
    # Remove the existing fallback if it exists
    # Note: This is a workaround since we can't easily remove methods
    
    # Add our fixed fallback
    $py-obj-class.^add_fallback(
        -> $obj, $name { True },  # Always handle unknown methods
        -> $obj, $name, |c {      # The actual handler
            my $python = $obj.python;
            my $attr = python3_get_attr($obj.ptr, $name);
            
            # Handle error from python3_get_attr
            try {
                $python!handle-python-error();
                CATCH {
                    default {
                        die "No such method or attribute '$name'";
                    }
                }
            }
            
            if $attr {
                # Check if it's callable
                if python3_is_callable($attr) {
                    # For callables: if called without args, return the function object
                    # If called with args, call it
                    if c.elems == 0 && !c.hash {
                        # Just accessing the function, not calling it
                        return ::('Inline::Python3::PythonObject').new(:ptr($attr), :python($python));
                    } else {
                        # Actually calling the function
                        my $py-obj = ::('Inline::Python3::PythonObject').new(:ptr($attr), :python($python));
                        my $result = $python.call-object($py-obj, |c);
                        python3_dec_ref($attr);
                        return $result;
                    }
                } else {
                    # For non-callable attributes: always return the value
                    my $value = $python.py-to-raku($attr);
                    python3_dec_ref($attr);
                    
                    # If arguments were provided for a non-callable, that's an error
                    if c.elems > 0 || c.hash {
                        die "TypeError: '$name' object is not callable";
                    }
                    
                    return $value;
                }
            } else {
                die "No such method or attribute '$name'";
            }
        }
    );
    
    # Re-compose the class
    $py-obj-class.^compose;
}

# Alternatively, provide a role that can be mixed in
role PythonObjectAccessor {
    # Provide AT-KEY for hash-like access
    method AT-KEY(Str $key) {
        self."$key"();
    }
    
    # Provide a method to get attribute without calling
    method get-attr(Str $name) {
        my $attr = python3_get_attr(self.ptr, $name);
        self.python!handle-python-error() unless $attr;
        
        if $attr {
            my $value = self.python.py-to-raku($attr);
            python3_dec_ref($attr);
            return $value;
        }
        
        die "No such attribute '$name'";
    }
    
    # Provide a method to call methods
    method call-method(Str $name, |args) {
        my $method = python3_get_attr(self.ptr, $name);
        self.python!handle-python-error() unless $method;
        
        if $method && python3_is_callable($method) {
            my $py-obj = ::('Inline::Python3::PythonObject').new(
                :ptr($method), 
                :python(self.python)
            );
            my $result = self.python.call-object($py-obj, |args);
            python3_dec_ref($method);
            return $result;
        }
        
        die "No such method '$name' or not callable";
    }
}