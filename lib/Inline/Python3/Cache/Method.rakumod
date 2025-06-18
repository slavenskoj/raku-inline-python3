use v6.d;

# Method cache with LRU eviction
class Inline::Python3::Cache::Method {
    has %.cache;
    has @.access-order;
    has Int $.max-size = 1000;
    has Int $.hits = 0;
    has Int $.misses = 0;
    
    # Cache key format: "type_name.method_name"
    method get(Str $type, Str $method) {
        my $key = "$type.$method";
        
        if %!cache{$key}:exists {
            $!hits++;
            # Move to end (most recently used)
            @!access-order .= grep(* ne $key);
            @!access-order.push($key);
            return %!cache{$key};
        }
        
        $!misses++;
        return Nil;
    }
    
    method set(Str $type, Str $method, $value) {
        my $key = "$type.$method";
        
        # Evict least recently used if at capacity
        if %!cache.elems >= $!max-size && !(%!cache{$key}:exists) {
            my $lru-key = @!access-order.shift;
            %!cache{$lru-key}:delete;
        }
        
        %!cache{$key} = $value;
        @!access-order .= grep(* ne $key);
        @!access-order.push($key);
    }
    
    method clear() {
        %!cache = ();
        @!access-order = ();
        $!hits = 0;
        $!misses = 0;
    }
    
    method hit-rate() {
        my $total = $!hits + $!misses;
        return 0 if $total == 0;
        return $!hits / $total;
    }
    
    method stats() {
        return {
            hits => $!hits,
            misses => $!misses,
            'hit-rate' => self.hit-rate(),
            size => %!cache.elems,
            'max-size' => $!max-size,
        };
    }
}

# Global method cache instance
my $METHOD-CACHE = Inline::Python3::Cache::Method.new;

sub get-method-cache() is export {
    $METHOD-CACHE
}