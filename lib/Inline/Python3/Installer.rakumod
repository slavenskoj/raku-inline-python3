unit module Inline::Python3::Installer;

use Inline::Python3::Config;

class PythonInstaller is export {
    has Str $.preferred-version = '3.11.5';
    has Str @.acceptable-versions = <3.11.5 3.11.4 3.10.13 3.10.12 3.9.18>;
    has Bool $.verbose = True;
    
    method install-python() {
        self!ensure-pyenv-installed;
        
        # Check if any acceptable version is already installed
        my $installed-version = self!find-installed-version;
        if $installed-version {
            self!log("Found Python $installed-version already installed");
            return $installed-version;
        }
        
        # No acceptable version found, install preferred
        self!log("No suitable Python version found. Installing Python $!preferred-version...");
        
        # Check if version is available
        unless self!version-available($!preferred-version) {
            die "Python $!preferred-version is not available for installation";
        }
        
        # Install Python
        my $success = self!install-python-version($!preferred-version);
        unless $success {
            die "Failed to install Python $!preferred-version";
        }
        
        # Set as global if no global version is set
        self!maybe-set-global($!preferred-version);
        
        return $!preferred-version;
    }
    
    method !ensure-pyenv-installed() {
        unless %*ENV<PYENV_ROOT> {
            self!log("pyenv not found. Installing pyenv first...");
            self!install-pyenv;
        }
        
        # Verify pyenv is working
        my $check = run('pyenv', '--version', :out, :err);
        unless $check.exitcode == 0 {
            die "pyenv is not working properly. Please check your installation.";
        }
    }
    
    method !install-pyenv() {
        given $*DISTRO {
            when .is-darwin {
                self!install-pyenv-macos;
            }
            when .is-win {
                self!install-pyenv-windows;
            }
            default {
                self!install-pyenv-unix;
            }
        }
    }
    
    method !install-pyenv-macos() {
        # Check for Homebrew
        my $brew = run('which', 'brew', :out, :err);
        if $brew.exitcode == 0 {
            self!log("Installing pyenv via Homebrew...");
            my $install = run('brew', 'install', 'pyenv', :out, :err);
            if $install.exitcode != 0 {
                die "Failed to install pyenv via Homebrew";
            }
        } else {
            self!log("Homebrew not found. Installing pyenv manually...");
            self!install-pyenv-unix;
        }
        
        self!setup-shell-integration;
    }
    
    method !install-pyenv-unix() {
        self!log("Installing pyenv via pyenv-installer...");
        
        # Download and run the installer
        my $installer-url = 'https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer';
        my $cmd = run('curl', '-L', $installer-url, :out);
        
        if $cmd.exitcode == 0 {
            my $script = $cmd.out.slurp(:close);
            
            # Save and run the installer
            my $temp = $*TMPDIR.add('pyenv-installer.sh');
            $temp.spurt($script);
            $temp.chmod(0o755);
            
            my $install = run('bash', $temp.Str, :out, :err);
            if $install.exitcode != 0 {
                die "pyenv installation failed";
            }
            
            $temp.unlink;
        } else {
            die "Failed to download pyenv installer";
        }
        
        self!setup-shell-integration;
    }
    
    method !install-pyenv-windows() {
        self!log("For Windows, please install pyenv-win manually:");
        self!log("  1. Visit: https://github.com/pyenv-win/pyenv-win");
        self!log("  2. Follow the installation instructions");
        self!log("  3. Restart your terminal");
        self!log("  4. Run the installer again");
        
        die "Manual installation required for Windows";
    }
    
    method !setup-shell-integration() {
        my $pyenv-root = %*ENV<HOME>.IO.add('.pyenv');
        %*ENV<PYENV_ROOT> = $pyenv-root.Str;
        %*ENV<PATH> = "{$pyenv-root}/bin:{%*ENV<PATH>}";
        
        # Initialize pyenv for current session
        my $init = qqx{pyenv init -};
        if $init {
            # This is a bit hacky but allows us to use pyenv immediately
            for $init.lines -> $line {
                if $line ~~ /'export' \s+ (\w+) '=' (.+)/ {
                    %*ENV{$0.Str} = $1.Str.subst(/^\"|\"$/, '', :g);
                }
            }
        }
        
        self!log("pyenv installed. Please add the following to your shell configuration:");
        self!log('  export PYENV_ROOT="$HOME/.pyenv"');
        self!log('  export PATH="$PYENV_ROOT/bin:$PATH"');
        self!log('  eval "$(pyenv init -)"');
    }
    
    method !find-installed-version() {
        my $versions = run('pyenv', 'versions', '--bare', :out, :err);
        return Nil unless $versions.exitcode == 0;
        
        my @installed = $versions.out.slurp(:close).lines;
        
        # Check preferred version first
        return $!preferred-version if $!preferred-version ∈ @installed;
        
        # Check other acceptable versions
        for @!acceptable-versions -> $version {
            return $version if $version ∈ @installed;
        }
        
        # Check if any Python 3.8+ is installed
        for @installed -> $version {
            if $version ~~ /^ '3.' (\d+) '.' / && $0.Int >= 8 {
                return $version;
            }
        }
        
        return Nil;
    }
    
    method !version-available(Str $version) {
        my $list = run('pyenv', 'install', '--list', :out);
        return False unless $list.exitcode == 0;
        
        my @available = $list.out.slurp(:close).lines.map(*.trim);
        return $version ∈ @available;
    }
    
    method !install-python-version(Str $version) {
        self!log("Installing Python $version (this may take several minutes)...");
        
        # Set build options for better compatibility
        %*ENV<PYTHON_CONFIGURE_OPTS> = '--enable-shared --enable-optimizations';
        
        # For macOS, ensure we use the right SDK
        if $*DISTRO.is-darwin {
            # Let pyenv handle SDK selection automatically
            %*ENV<PYTHON_CONFIGURE_OPTS> ~= ' --with-openssl=/usr/local/opt/openssl';
        }
        
        # Run the installation
        my $proc = Proc::Async.new('pyenv', 'install', '-v', $version);
        
        $proc.stdout.tap(-> $line {
            self!log("  | $line") if $!verbose;
        });
        
        $proc.stderr.tap(-> $line {
            self!log("  ! $line") if $!verbose || $line ~~ /error|fail/;
        });
        
        my $promise = $proc.start;
        my $result = await $promise;
        
        if $result.exitcode == 0 {
            self!log("Python $version installed successfully!");
            return True;
        } else {
            self!log("Failed to install Python $version");
            return False;
        }
    }
    
    method !maybe-set-global(Str $version) {
        my $global = run('pyenv', 'global', :out);
        if $global.exitcode == 0 {
            my $current = $global.out.slurp(:close).trim;
            if !$current || $current eq 'system' {
                self!log("Setting Python $version as global default...");
                run('pyenv', 'global', $version);
            }
        }
    }
    
    method !log(Str $message) {
        note "[Python3 Installer] $message" if $!verbose;
    }
}

# Convenience function for use in Build.rakumod
sub auto-install-python(:$version, :$verbose = True) is export {
    my $installer = PythonInstaller.new(
        preferred-version => $version // '3.11.5',
        verbose => $verbose
    );
    
    return $installer.install-python;
}

# Check if installation is needed
sub python-installation-needed() is export {
    return True unless %*ENV<PYENV_ROOT>;
    
    my $check = run('pyenv', 'version', :out, :err);
    return True unless $check.exitcode == 0;
    
    my $version = $check.out.slurp(:close);
    return True if $version ~~ /system/;
    
    # Check if version is 3.8+
    if $version ~~ /'3.' (\d+)/ {
        return $0.Int < 8;
    }
    
    return True;
}