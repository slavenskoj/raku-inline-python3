use v6.d;

# String interning pool for common strings
class Inline::Python3::Cache::String {
    has %.pool;
    has Int $.max-size = 10000;
    has Int $.max-string-length = 100;
    has Int $.hits = 0;
    has Int $.misses = 0;
    has @.access-order;
    
    method intern(Str $string) {
        # Don't intern long strings
        return $string if $string.chars > $!max-string-length;
        
        if %!pool{$string}:exists {
            $!hits++;
            # Move to end (most recently used)
            @!access-order .= grep(* ne $string);
            @!access-order.push($string);
            return %!pool{$string};
        }
        
        $!misses++;
        
        # Evict least recently used if at capacity
        if %!pool.elems >= $!max-size {
            my $lru = @!access-order.shift;
            %!pool{$lru}:delete;
        }
        
        # Intern the string
        %!pool{$string} = $string;
        @!access-order.push($string);
        
        return %!pool{$string};
    }
    
    method get(Str $string) {
        return %!pool{$string} // Nil;
    }
    
    method clear() {
        %!pool = ();
        @!access-order = ();
        $!hits = 0;
        $!misses = 0;
    }
    
    method stats() {
        return {
            hits => $!hits,
            misses => $!misses,
            'hit-rate' => $!hits + $!misses > 0 ?? $!hits / ($!hits + $!misses) !! 0,
            size => %!pool.elems,
            'max-size' => $!max-size,
            'total-chars' => %!pool.values.map(*.chars).sum // 0,
        };
    }
}

# Global string pool instance
my $STRING-POOL = Inline::Python3::Cache::String.new;

sub get-string-pool() is export {
    $STRING-POOL
}