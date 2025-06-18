use v6.d;
use NativeCall;

# Integer cache for small integers
class Inline::Python3::Cache::Integer {
    has Int $.min = -128;
    has Int $.max = 256;
    has @.cache;
    has Bool $.initialized = False;
    has Int $.hits = 0;
    has Int $.misses = 0;
    
    method initialize(:&python3_int_from_long) {
        return if $!initialized;
        
        # Pre-allocate Python integer objects
        for $!min..$!max -> $i {
            my $idx = $i - $!min;
            @!cache[$idx] = &python3_int_from_long($i);
        }
        
        $!initialized = True;
    }
    
    method get(Int $value) {
        return Nil unless $!initialized;
        
        if $!min <= $value <= $!max {
            $!hits++;
            my $idx = $value - $!min;
            return @!cache[$idx];
        }
        
        $!misses++;
        return Nil;
    }
    
    method in-range(Int $value) {
        return $!min <= $value <= $!max;
    }
    
    method clear() {
        # Don't actually clear the cache, just reset stats
        # Python objects will be cleaned up on shutdown
        $!hits = 0;
        $!misses = 0;
    }
    
    method stats() {
        return {
            hits => $!hits,
            misses => $!misses,
            'hit-rate' => $!hits + $!misses > 0 ?? $!hits / ($!hits + $!misses) !! 0,
            range => "$!min..$!max",
            size => @!cache.elems,
            initialized => $!initialized,
        };
    }
}

# Global integer cache instance
my $INTEGER-CACHE = Inline::Python3::Cache::Integer.new;

sub get-integer-cache() is export {
    $INTEGER-CACHE
}