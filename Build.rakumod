use v6.d;

class Build {
    method build($dist-path) {
        say "Building Inline::Python3...";
        
        # Detect Python configuration - ONLY from pyenv
        my %config = self!detect-python-config();
        
        say "Found Python {%config<version>} at {%config<executable>}";
        say "Using pyenv: yes (required)";
        
        # Prepare build directory
        my $build-dir = $dist-path.IO.add('resources/libraries');
        $build-dir.mkdir unless $build-dir.e;
        
        # Compile the C helper library
        my $src = $dist-path.IO.add('src/python3_helper.c');
        my $lib-name = self!get-library-name();
        my $lib-path = $build-dir.add($lib-name);
        
        # Build the library
        self!compile-library($src, $lib-path, %config);
        
        say "Build complete! Library created at: $lib-path";
        return True;
    }
    
    method !detect-python-config() {
        my %config;
        
        # ONLY use pyenv - no fallbacks
        my $pyenv-root = %*ENV<PYENV_ROOT> // %*ENV<HOME>.IO.add('.pyenv').Str;
        unless $pyenv-root.IO.d {
            die "PYENV_ROOT not found. Please install pyenv and set PYENV_ROOT environment variable.";
        }
        
        # Try to find pyenv - it might be in PATH (homebrew) or in PYENV_ROOT/bin
        my $pyenv;
        
        # First check if pyenv is in PATH
        my $which-pyenv = qqx{which pyenv}.trim;
        if $which-pyenv && $which-pyenv.IO.e {
            $pyenv = $which-pyenv;
        } elsif "$pyenv-root/bin/pyenv".IO.e {
            $pyenv = "$pyenv-root/bin/pyenv";
        } else {
            die "pyenv executable not found. Please install pyenv via homebrew or pyenv-installer.";
        }
        
        # Get the current pyenv version
        my $pyenv-version = qqx{$pyenv version-name}.trim;
        if !$pyenv-version || $pyenv-version eq 'system' {
            die "No pyenv Python version selected. Please run 'pyenv install 3.11.5' and 'pyenv global 3.11.5' (or your preferred version).";
        }
        
        %config<is-pyenv> = True;
        %config<pyenv-version> = $pyenv-version;
        
        # Get the actual Python executable from pyenv
        %config<executable> = qqx{$pyenv which python3}.trim || qqx{$pyenv which python}.trim;
        unless %config<executable> && %config<executable>.IO.e {
            die "Could not find Python executable for pyenv version $pyenv-version. Please ensure it's properly installed.";
        }
        
        # Set up pyenv environment
        %*ENV<PATH> = "$pyenv-root/shims:$pyenv-root/bin:{%*ENV<PATH>}";
        %*ENV<PYENV_ROOT> = $pyenv-root;
        
        # Get version
        my $version-proc = run(%config<executable>, '--version', :out, :err);
        %config<version> = $version-proc.out.slurp(:close).trim;
        
        # Get Python configuration using python3-config from pyenv
        my $py-config = qqx{$pyenv which python3-config}.trim || qqx{$pyenv which python-config}.trim;
        
        if $py-config && $py-config.IO.e {
            # Get include directories
            my $includes = qqx{$py-config --includes}.trim;
            %config<includes> = $includes.split(/\s+/).grep(/^'-I'/).map(*.substr(2));
            
            # Get library flags
            my $ldflags = qqx{$py-config --ldflags}.trim;
            my $libs = qqx{$py-config --libs}.trim || '';
            %config<ldflags> = "$ldflags $libs".trim;
            
            # Parse library directories and libraries
            my @parts = %config<ldflags>.split(/\s+/);
            %config<lib-dirs> = @parts.grep(/^'-L'/).map(*.substr(2));
            %config<libs> = @parts.grep(/^'-l'/).map(*.substr(2));
        } else {
            # For pyenv Python without python-config, detect manually
            %config<includes> = self!find-pyenv-python-includes(%config<executable>, $pyenv-root, $pyenv-version);
            %config<lib-dirs> = [];
            %config<libs> = [];
        }
        
        return %config;
    }
    
    method !find-pyenv-python-includes($python, $pyenv-root, $version-name) {
        # First try using sysconfig from Python itself
        my $sysconfig = qqx{$python -c "import sysconfig; print(sysconfig.get_path('include'))"}.trim;
        if $sysconfig && $sysconfig.IO.e {
            return [$sysconfig];
        }
        
        # Get the actual Python version
        my $py-version = qqx{$python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"}.trim;
        
        # Try pyenv version paths
        my @possible = (
            "$pyenv-root/versions/$version-name/include/python$py-version",
            "$pyenv-root/versions/$version-name/include/python{$py-version}m",
            "$pyenv-root/versions/$version-name/include",
        );
        
        for @possible -> $dir {
            return [$dir] if $dir.IO.e;
        }
        
        die "Could not find Python include directory for pyenv version $version-name";
    }
    
    method !compile-library($src, $lib-path, %config) {
        my @cc = self!get-compiler();
        
        # Compile command
        my @compile-cmd = |@cc, '-c', '-fPIC', '-O2', '-Wall';
        
        # Add include directories
        for %config<includes>.list -> $inc {
            @compile-cmd.push: "-I$inc";
        }
        
        # Output object file
        my $obj = $lib-path.Str.subst(/\.\w+$/, '.o');
        @compile-cmd.push: '-o', $obj, $src.Str;
        
        say "Compiling: {@compile-cmd.join(' ')}";
        my $compile = run(|@compile-cmd);
        die "Compilation failed" unless $compile.exitcode == 0;
        
        # Link command
        my @link-cmd = |@cc, '-shared', '-fPIC';
        
        # Add library directories
        for %config<lib-dirs>.list -> $dir {
            @link-cmd.push: "-L$dir";
        }
        
        # For macOS with pyenv, we need to set rpath and link against Python
        if $*DISTRO.name eq 'macos' {
            # Find the Python library in pyenv
            if %config<pyenv-version> {
                my $pyenv-root = %*ENV<PYENV_ROOT>;
                my $py-version = qqx{%config<executable> -c "import sys; print(str(sys.version_info.major) + '.' + str(sys.version_info.minor))"}.trim;
                
                # Add rpath to find Python library at runtime
                my $python-lib-dir = "$pyenv-root/versions/{%config<pyenv-version>}/lib";
                @link-cmd.push: '-Wl,-rpath,' ~ $python-lib-dir;
                
                # Link against Python library
                @link-cmd.push: "-L$python-lib-dir";
                @link-cmd.push: "-lpython$py-version";
            }
            
            # Still use dynamic lookup as fallback
            @link-cmd.push: '-undefined', 'dynamic_lookup';
        } elsif $*DISTRO.is-win {
            # Windows requires linking against Python library
            for %config<libs>.list -> $lib {
                @link-cmd.push: "-l$lib" if $lib ~~ /^python/;
            }
        } else {
            # Linux can use either approach, but dynamic is more flexible
            @link-cmd.push: '-undefined', 'dynamic_lookup' if self!supports-undefined-dynamic-lookup();
            # Still link if python lib is available
            for %config<libs>.list -> $lib {
                @link-cmd.push: "-l$lib" if $lib ~~ /^python/;
            }
        }
        
        @link-cmd.push: '-o', $lib-path.Str, $obj;
        
        say "Linking: {@link-cmd.join(' ')}";
        my $link = run(|@link-cmd);
        die "Linking failed" unless $link.exitcode == 0;
        
        # Clean up object file
        $obj.IO.unlink;
    }
    
    method !supports-undefined-dynamic-lookup() {
        # Check if the linker supports -undefined dynamic_lookup (mainly for macOS)
        my @cc = self!get-compiler();
        my $test = run(|@cc, '-undefined', 'dynamic_lookup', '-shared', '-o', '/dev/null', '-x', 'c', '-', :in, :out, :err);
        $test.in.print("int main() { return 0; }");
        $test.in.close;
        return $test.exitcode == 0;
    }
    
    method !get-library-name() {
        if $*DISTRO.is-win {
            return 'python3_helper.dll';
        } elsif $*DISTRO.name eq 'macos' {
            return 'libpython3_helper.dylib';
        } else {
            return 'libpython3_helper.so';
        }
    }
    
    method !get-compiler() {
        # Try to find a C compiler
        my @compilers = <cc gcc clang>;
        
        for @compilers -> $cc {
            return ($cc) if self!command-exists($cc);
        }
        
        die "No C compiler found. Please install gcc or clang.";
    }
    
    method !command-exists($cmd) {
        my $which = $*DISTRO.is-win ?? 'where' !! 'which';
        my $proc = run($which, $cmd, :out, :err);
        return $proc.exitcode == 0;
    }
}