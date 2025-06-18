unit module Inline::Python3::Config;

use NativeCall;

class PythonConfig is export {
    has Str $.python-executable;
    has Str $.python-version;
    has @.include-dirs;
    has @.library-dirs;
    has @.libraries;
    has %.compile-flags;
    has %.link-flags;
    has Bool $.is-pyenv = False;
    
    method detect-python() {
        # Require pyenv for Python management
        self!ensure-pyenv-installed;
        
        # Priority order:
        # 1. INLINE_PYTHON_VERSION environment variable (pyenv version)
        # 2. pyenv local version
        # 3. pyenv global version
        
        my $python-version = self!determine-python-version;
        my $python = self!get-pyenv-python($python-version);
        
        self!validate-python($python);
        $!is-pyenv = True;
        self!configure-from-python($python);
    }
    
    method !ensure-pyenv-installed() {
        # Set PYENV_ROOT if not already set
        unless %*ENV<PYENV_ROOT> {
            my $default-pyenv = %*ENV<HOME>.IO.add('.pyenv');
            if $default-pyenv.d {
                %*ENV<PYENV_ROOT> = $default-pyenv.Str;
            } else {
                die qq:to/ERROR/;
                    pyenv is required but not found.
                    
                    The installer should have installed it automatically.
                    If you're seeing this error, please install pyenv manually:
                      - macOS: brew install pyenv
                      - Linux: curl https://pyenv.run | bash
                      
                    Then add to your shell configuration:
                      export PYENV_ROOT="\$HOME/.pyenv"
                      export PATH="\$PYENV_ROOT/bin:\$PATH"
                      eval "\$(pyenv init -)"
                    ERROR
            }
        }
        
        # Ensure pyenv bin is in PATH
        my $pyenv-root = %*ENV<PYENV_ROOT>;
        my $pyenv-bin-dir = "$pyenv-root/bin";
        unless %*ENV<PATH>.contains($pyenv-bin-dir) {
            %*ENV<PATH> = "$pyenv-bin-dir:{%*ENV<PATH>}";
        }
        
        # Check if pyenv exists
        my $pyenv-cmd = "$pyenv-bin-dir/pyenv";
        unless $pyenv-cmd.IO.e {
            # Try to find pyenv in PATH (e.g., from Homebrew)
            my $which-pyenv = qqx{which pyenv}.trim;
            if $which-pyenv && $which-pyenv.IO.e {
                $pyenv-cmd = $which-pyenv;
            } else {
                die "pyenv binary not found. Please ensure pyenv is properly installed.";
            }
        }
        
        # Initialize pyenv by setting up shims
        my $pyenv-shims = "$pyenv-root/shims";
        unless %*ENV<PATH>.contains($pyenv-shims) {
            %*ENV<PATH> = "$pyenv-shims:{%*ENV<PATH>}";
        }
        
        # Run pyenv init to get any additional setup
        my $init-cmd = qqx{$pyenv-cmd init -}.trim;
        if $init-cmd {
            # Parse and apply any environment exports from pyenv init
            for $init-cmd.lines -> $line {
                if $line ~~ /export \s+ (\w+) '=' '"' (<-["]>*) '"'/ {
                    %*ENV{~$0} = ~$1;
                }
            }
        }
    }
    
    method !determine-python-version() {
        # Check for explicit version request
        if %*ENV<INLINE_PYTHON_VERSION> {
            my $version = %*ENV<INLINE_PYTHON_VERSION>;
            self!ensure-pyenv-version($version);
            return $version;
        }
        
        # First check for .python-version file in current directory
        my $version-file = $*CWD.add('.python-version');
        if $version-file.e {
            my $version = $version-file.slurp.trim;
            if $version && $version ne '' && $version ne 'system' {
                self!ensure-pyenv-version($version);
                return $version;
            }
        }
        
        # Check for local version via pyenv
        my $pyenv-cmd = self!get-pyenv-command;
        my $local = run($pyenv-cmd, 'local', :out, :err);
        if $local.exitcode == 0 {
            my $version = $local.out.slurp(:close).trim;
            if $version && $version ne '' {
                return $version;
            }
        }
        
        # Check global version
        my $global = run($pyenv-cmd, 'global', :out, :err);
        if $global.exitcode == 0 {
            my $version = $global.out.slurp(:close).trim;
            if $version && $version ne 'system' {
                return $version;
            }
        }
        
        die qq:to/ERROR/;
            No Python version configured in pyenv.
            
            Please set a Python version:
              pyenv install 3.11.5
              pyenv global 3.11.5
            
            Or set locally for this project:
              pyenv local 3.11.5
            
            Or set via environment:
              INLINE_PYTHON_VERSION=3.11.5
            ERROR
    }
    
    method !get-pyenv-command() {
        # Try to find pyenv in various locations
        my @locations = (
            %*ENV<PYENV_ROOT> ?? "{%*ENV<PYENV_ROOT>}/bin/pyenv" !! Nil,
            '/opt/homebrew/bin/pyenv',
            '/usr/local/bin/pyenv',
            %*ENV<HOME> ?? "{%*ENV<HOME>}/.pyenv/bin/pyenv" !! Nil,
        ).grep(*.defined);
        
        for @locations -> $loc {
            return $loc if $loc.IO.e;
        }
        
        # Fall back to PATH
        return 'pyenv';
    }
    
    method !ensure-pyenv-version(Str $version) {
        # Check if version is installed
        my $pyenv-cmd = self!get-pyenv-command;
        my $versions = run($pyenv-cmd, 'versions', '--bare', :out);
        my @installed = $versions.out.slurp(:close).lines;
        
        unless $version ∈ @installed {
            die qq:to/ERROR/;
                Python $version is not installed in pyenv.
                
                Install it with:
                  pyenv install $version
                
                Available versions:
                  pyenv install --list | grep -E "^  3\\.(8|9|10|11|12)\\."
                ERROR
        }
    }
    
    method !get-pyenv-python(Str $version) {
        # Get the python executable for this version
        my $pyenv-cmd = self!get-pyenv-command;
        my $python-path = run($pyenv-cmd, 'prefix', $version, :out, :err);
        unless $python-path.exitcode == 0 {
            die "Failed to get pyenv prefix for version $version";
        }
        
        my $prefix = $python-path.out.slurp(:close).trim;
        my $python = "$prefix/bin/python3";
        
        unless $python.IO.e {
            # Try without the 3
            $python = "$prefix/bin/python";
            unless $python.IO.e {
                die "Python executable not found in pyenv prefix: $prefix";
            }
        }
        
        return $python;
    }
    
    
    method !validate-python(Str $python) {
        # Check if it's actually Python 3
        my $version-check = run($python, '-c', 'import sys; print(sys.version_info.major)', :out, :err);
        unless $version-check.exitcode == 0 {
            die "Failed to run Python at $python";
        }
        
        my $major = $version-check.out.slurp(:close).trim.Int;
        unless $major == 3 {
            die "Python at $python is version $major, but version 3 is required";
        }
        
        # Get full version
        my $full-version = run($python, '-c', 'import sys; print(".".join(map(str, sys.version_info[:3])))', :out);
        $!python-version = $full-version.out.slurp(:close).trim;
        
        # Check minimum version (3.8+)
        my @parts = $!python-version.split('.');
        my $minor = @parts[1].Int;
        unless $minor >= 8 {
            die "Python $!python-version found, but version 3.8+ is required";
        }
    }
    
    method !configure-from-python(Str $python) {
        $!python-executable = $python;
        
        # Get configuration using python3-config or fallback to Python itself
        my $config-script = self!find-python-config($python);
        
        if $config-script {
            self!parse-python-config($config-script);
        } else {
            self!parse-python-sysconfig($python);
        }
    }
    
    method !find-python-config(Str $python) {
        # Try to find python3-config
        my $base = $python.IO.basename;
        my $dir = $python.IO.dirname;
        
        # Try exact match first (e.g., python3.11 -> python3.11-config)
        my $config = "$dir/{$base}-config";
        return $config if $config.IO.e;
        
        # Try generic python3-config in same directory
        $config = "$dir/python3-config";
        return $config if $config.IO.e;
        
        # Try system python3-config
        my $which = run('which', 'python3-config', :out, :err);
        if $which.exitcode == 0 {
            $config = $which.out.slurp(:close).trim;
            return $config if $config && $config.IO.e;
        }
        
        return Nil;
    }
    
    method !parse-python-config(Str $config-script) {
        # Get include directories
        my $includes = run($config-script, '--includes', :out);
        my $include-str = $includes.out.slurp(:close);
        @!include-dirs = $include-str.comb(/ '-I' \s* (<-[\s]>+) /)>>.[ 0 ]>>.Str;
        
        # Get link flags
        my $ldflags = run($config-script, '--ldflags', '--embed', :out);
        my $ld-str = $ldflags.out.slurp(:close);
        
        # Parse library directories and libraries
        @!library-dirs = $ld-str.comb(/ '-L' \s* (<-[\s]>+) /)>>.[ 0 ]>>.Str;
        @!libraries = $ld-str.comb(/ '-l' \s* (<-[\s]>+) /)>>.[ 0 ]>>.Str;
        
        # Get compile flags
        my $cflags = run($config-script, '--cflags', :out);
        my $cflags-str = $cflags.out.slurp(:close);
        %!compile-flags = self!parse-flags($cflags-str);
        
        # Store full link flags
        %!link-flags = self!parse-flags($ld-str);
    }
    
    method !parse-python-sysconfig(Str $python) {
        # Fallback: get configuration directly from Python
        my $script = q:to/PYTHON/;
            import sysconfig
            import json
            config = {
                'include': sysconfig.get_path('include'),
                'stdlib': sysconfig.get_path('stdlib'),
                'platstdlib': sysconfig.get_path('platstdlib'),
                'platinclude': sysconfig.get_path('platinclude'),
                'LIBDIR': sysconfig.get_config_var('LIBDIR'),
                'LIBRARY': sysconfig.get_config_var('LIBRARY'),
                'LDLIBRARY': sysconfig.get_config_var('LDLIBRARY'),
                'LIBS': sysconfig.get_config_var('LIBS'),
                'CFLAGS': sysconfig.get_config_var('CFLAGS'),
                'LDFLAGS': sysconfig.get_config_var('LDFLAGS'),
            }
            print(json.dumps(config))
            PYTHON
        
        my $result = run($python, '-c', $script, :out);
        my $json-str = $result.out.slurp(:close);
        
        # Simple JSON parsing (for basic needs)
        my %config;
        for $json-str.comb(/ '"' (<-["]>+) '":' \s* '"' (<-["]>*) '"' /) -> $match {
            %config{$match[0].Str} = $match[1].Str;
        }
        
        @!include-dirs = [%config<include>, %config<platinclude>].grep(*.defined);
        @!library-dirs = [%config<LIBDIR>].grep(*.defined);
        
        # Extract library name
        if %config<LDLIBRARY> && %config<LDLIBRARY> ~~ / 'lib' (<-[.]>+) '.' / {
            @!libraries = ~$0;
        }
    }
    
    method !parse-flags(Str $flags-str) {
        my %flags;
        my @parts = $flags-str.words;
        my $current-flag;
        
        for @parts -> $part {
            if $part ~~ /^ '-' / {
                $current-flag = $part;
                %flags{$current-flag} = True;
            } elsif $current-flag {
                %flags{$current-flag} = $part;
                $current-flag = Nil;
            }
        }
        
        return %flags;
    }
    
    method build-dir() {
        # Always use pyenv-based directory naming
        my $base = $*CWD;
        my $subdir = "pyenv-{$!python-version}";
        return $base.add("resources/libraries/$subdir");
    }
}