#!/usr/bin/env raku

use v6.d;

my @test-files = <
    t/01-basic.t
    t/02-types.t
    t/03-objects.t
    t/04-errors.t
    t/05-performance.t
    t/10-persistence.t
    t/11-fallback.t
    t/12-optimization.t
>;

my $total-tests = 0;
my $failed-tests = 0;
my @failed-files;

say "Running Inline::Python3 test suite...";
say "=" x 60;

for @test-files -> $test-file {
    if $test-file.IO.e {
        print "Running $test-file... ";
        
        my $proc = run 'raku', '-I', 'lib', $test-file, :out, :err;
        my $output = $proc.out.slurp(:close);
        my $error = $proc.err.slurp(:close);
        
        if $proc.exitcode == 0 && $output ~~ /^^ '1..' (\d+) / {
            my $num-tests = $0.Int;
            $total-tests += $num-tests;
            say "✓ ($num-tests tests)";
        } else {
            $failed-tests++;
            @failed-files.push($test-file);
            say "✗ FAILED";
            say "  Error: $error" if $error;
        }
    } else {
        say "Skipping $test-file (not found)";
    }
}

say "=" x 60;
say "Test Summary:";
say "  Total test files: {@test-files.elems}";
say "  Passed: {@test-files.elems - $failed-tests}";
say "  Failed: $failed-tests";
say "  Total tests run: $total-tests";

if @failed-files {
    say "\nFailed test files:";
    for @failed-files -> $file {
        say "  - $file";
    }
    exit 1;
} else {
    say "\nAll tests passed! 🎉";
}