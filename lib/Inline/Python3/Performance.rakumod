unit module Inline::Python3::Performance;

# Performance tips and utilities

=begin pod

=head1 NAME

Inline::Python3::Performance - Performance optimization guide and utilities

=head1 DESCRIPTION

This module provides performance optimization techniques and utilities for Inline::Python3.

=head1 PERFORMANCE TIPS

=head2 1. Use Lazy Evaluation

Don't force conversion of large data structures unless necessary:

    # Bad - forces immediate conversion
    my @data = $py.call('make_large_list', 10000).raku-value;
    
    # Good - lazy evaluation
    my $data = $py.call('make_large_list', 10000);
    my $first = $data.raku-value[0];  # Only converts what's needed

=head2 2. Cache Python Objects

Reuse Python objects instead of recreating them:

    # Bad - creates object every time
    for ^1000 {
        my $obj = $py.call('MyClass');
        $obj.process($data);
    }
    
    # Good - reuse object
    my $obj = $py.call('MyClass');
    for ^1000 {
        $obj.process($data);
    }

=head2 3. Batch Operations

Process data in batches:

    # Bad - many individual calls
    my @results;
    for @data -> $item {
        @results.push: $py.call('process', $item);
    }
    
    # Good - single batch call
    my @results = $py.call('process_batch', @data);

=head2 4. Use Native Python Loops

For heavy computation, use Python's native loops:

    # Bad - Raku loop calling Python
    my $sum = 0;
    for @data -> $x {
        $sum += $py.call('compute', $x);
    }
    
    # Good - Python does the loop
    $py.run(q:to/PYTHON/);
    def compute_all(data):
        return sum(compute(x) for x in data)
    PYTHON
    my $sum = $py.call('compute_all', @data);

=head2 5. Minimize Type Conversions

Keep data in Python when doing multiple operations:

    # Bad - converts back and forth
    my @data = $py.call('load_data');
    @data = @data.map(* * 2);
    my $result = $py.call('process', @data);
    
    # Good - stay in Python
    $py.run(q:to/PYTHON/);
    data = load_data()
    data = [x * 2 for x in data]
    result = process(data)
    PYTHON
    my $result = $py.run('result', :eval);

=end pod

# Performance monitoring
class PerformanceMonitor is export {
    has %.timings;
    has %.counts;
    has Bool $.enabled = True;
    
    method time-call(Str $name, &code) {
        return &code() unless $!enabled;
        
        my $start = now;
        my $result = &code();
        my $elapsed = now - $start;
        
        %!timings{$name}.push: $elapsed;
        %!counts{$name}++;
        
        return $result;
    }
    
    method report() {
        say "Performance Report";
        say "=" x 50;
        
        for %!timings.keys.sort -> $name {
            my @times = %!timings{$name};
            my $total = @times.sum;
            my $avg = $total / @times.elems;
            my $count = %!counts{$name};
            
            say sprintf("%-30s: %6d calls, avg %.3fms, total %.3fs",
                        $name, $count, $avg * 1000, $total);
        }
    }
    
    method reset() {
        %!timings = ();
        %!counts = ();
    }
}

# Profiling utilities
sub profile-python-code($py, Str $code, :$name = 'Python code') is export {
    say "Profiling: $name";
    
    # Setup Python profiler
    $py.run(q:to/PYTHON/);
    import cProfile
    import pstats
    import io
    
    def profile_code(code):
        pr = cProfile.Profile()
        pr.enable()
        exec(code)
        pr.disable()
        
        s = io.StringIO()
        ps = pstats.Stats(pr, stream=s).sort_stats('cumulative')
        ps.print_stats(20)
        return s.getvalue()
    PYTHON
    
    my $profile = $py.call('__main__', 'profile_code', $code);
    say $profile;
}

# Memory tracking
sub track-memory(&code, :$label = 'Operation') is export {
    my $get-memory = -> {
        return 0 if $*DISTRO.is-win;
        my $mem = qqx{ps -o rss= -p $*PID}.trim;
        $mem ?? $mem.Int !! 0
    };
    
    my $before = $get-memory();
    my $result = &code();
    my $after = $get-memory();
    
    my $used = ($after - $before) / 1024;
    say "$label: {$used.fmt('%.1f')} MB";
    
    return $result;
}

# Optimization helpers
class OptimizationHelper is export {
    has $.py;
    
    method optimize-numpy-arrays() {
        # Pre-import numpy for faster array operations
        $!py.run(q:to/PYTHON/);
        try:
            import numpy as np
            
            def fast_array_op(op, *arrays):
                """Perform operations on numpy arrays efficiently"""
                arrays = [np.asarray(a) for a in arrays]
                return getattr(np, op)(*arrays).tolist()
            
            def fast_array_create(data):
                """Create numpy array from data"""
                return np.asarray(data)
                
        except ImportError:
            pass
        PYTHON
    }
    
    method optimize-pandas() {
        # Pre-import pandas for faster dataframe operations
        $!py.run(q:to/PYTHON/);
        try:
            import pandas as pd
            
            def fast_df_from_dict(data):
                """Create DataFrame from dict efficiently"""
                return pd.DataFrame(data)
                
            def fast_df_op(df, op, *args, **kwargs):
                """Perform DataFrame operations efficiently"""
                return getattr(df, op)(*args, **kwargs)
                
        except ImportError:
            pass
        PYTHON
    }
    
    method compile-regex(Str $pattern) {
        # Pre-compile regex in Python for reuse
        # Use a simple identifier for now
        my $id = $pattern.comb(/\w/).join('_');
        $!py.run(qq:to/PYTHON/);
        import re
        compiled_regex_{$id} = re.compile(r'{$pattern}')
        PYTHON
    }
}

# Benchmarking utilities
sub compare-implementations(&raku-version, &python-version, :$iterations = 1000, :$name = 'Operation') is export {
    say "\nComparing: $name";
    say "-" x 40;
    
    # Warmup
    &raku-version() for ^10;
    &python-version() for ^10;
    
    # Benchmark Raku
    my $start-raku = now;
    &raku-version() for ^$iterations;
    my $time-raku = now - $start-raku;
    
    # Benchmark Python
    my $start-python = now;
    &python-version() for ^$iterations;
    my $time-python = now - $start-python;
    
    # Results
    say "Raku:   {($time-raku / $iterations * 1000).fmt('%.3f')}ms per iteration";
    say "Python: {($time-python / $iterations * 1000).fmt('%.3f')}ms per iteration";
    
    my $ratio = $time-raku / $time-python;
    if $ratio > 1 {
        say "Python is {$ratio.fmt('%.1f')}x faster";
    } else {
        say "Raku is {(1/$ratio).fmt('%.1f')}x faster";
    }
}

# Export optimization settings
sub optimize-for-performance($py) is export {
    # Set Python optimization flags
    $py.run(q:to/PYTHON/);
    import sys
    import gc
    
    # Disable debugging features
    sys.dont_write_bytecode = True
    
    # Optimize garbage collection
    gc.disable()  # Disable automatic GC
    
    # Pre-import common modules
    import math
    import itertools
    import functools
    import operator
    
    # Create optimized functions
    def fast_map(func, iterable):
        """Optimized map using list comprehension"""
        return [func(x) for x in iterable]
    
    def fast_filter(func, iterable):
        """Optimized filter using list comprehension"""
        return [x for x in iterable if func(x)]
    
    def fast_reduce(func, iterable, initial=None):
        """Optimized reduce using functools"""
        if initial is None:
            return functools.reduce(func, iterable)
        return functools.reduce(func, iterable, initial)
    PYTHON
    
    say "Python optimized for performance";
}

# Caching decorator for Raku functions that call Python
sub cached(&func) is export {
    my %cache;
    
    return sub (|args) {
        my $key = args.gist;
        %cache{$key} //= &func(|args);
    }
}