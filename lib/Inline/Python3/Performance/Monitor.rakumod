use v6.d;

# Performance monitoring for Inline::Python3
class Inline::Python3::Performance::Monitor {
    has %.timings;
    has %.counts;
    has Bool $.enabled = True;
    has Instant $.start-time = now;
    
    method time-call($label, &code) {
        return &code() unless $!enabled;
        
        my $start = now;
        my $result = &code();
        my $elapsed = now - $start;
        
        %!timings{$label}.push: $elapsed;
        %!counts{$label}++;
        
        return $result;
    }
    
    method record($label, $value) {
        return unless $!enabled;
        %!timings{$label}.push: $value;
        %!counts{$label}++;
    }
    
    method stats($label?) {
        if $label {
            return self!compute-stats($label);
        }
        
        # Return stats for all labels
        my %all-stats;
        for %!timings.keys -> $key {
            %all-stats{$key} = self!compute-stats($key);
        }
        return %all-stats;
    }
    
    method !compute-stats($label) {
        my @times = %!timings{$label} // [];
        return {} unless @times;
        
        my $count = +@times;
        my $total = @times.sum;
        my $mean = $total / $count;
        
        # Calculate percentiles
        my @sorted = @times.sort;
        my $p50 = @sorted[$count div 2];
        my $p95 = @sorted[($count * 0.95).Int min ($count - 1)];
        my $p99 = @sorted[($count * 0.99).Int min ($count - 1)];
        
        return {
            count => $count,
            total => $total,
            mean => $mean,
            min => @sorted[0],
            max => @sorted[*-1],
            p50 => $p50,
            p95 => $p95,
            p99 => $p99,
        };
    }
    
    method report(:$top = 10) {
        say "=== Performance Report ===";
        say "Monitoring duration: {(now - $!start-time).fmt('%.2f')}s\n";
        
        my @labels = %!counts.keys.sort({ %!counts{$^b} <=> %!counts{$^a} });
        
        for @labels[^$top] -> $label {
            my %stats = self!compute-stats($label);
            say "$label:";
            say "  Calls: %stats<count>";
            say "  Total: {%stats<total>.fmt('%.3f')}s";
            say "  Mean:  {(%stats<mean> * 1000).fmt('%.3f')}ms";
            say "  P50:   {(%stats<p50> * 1000).fmt('%.3f')}ms";
            say "  P95:   {(%stats<p95> * 1000).fmt('%.3f')}ms";
            say "  P99:   {(%stats<p99> * 1000).fmt('%.3f')}ms";
            say "";
        }
    }
    
    method clear() {
        %!timings = ();
        %!counts = ();
        $!start-time = now;
    }
}

# Global monitor instance
my $MONITOR = Inline::Python3::Performance::Monitor.new;

sub get-performance-monitor() is export {
    $MONITOR
}

# Convenience functions
sub time-operation($label, &code) is export {
    $MONITOR.time-call($label, &code)
}

sub record-metric($label, $value) is export {
    $MONITOR.record($label, $value)
}

sub performance-report(:$top = 10) is export {
    $MONITOR.report(:$top)
}

sub reset-performance-monitor() is export {
    $MONITOR.clear()
}