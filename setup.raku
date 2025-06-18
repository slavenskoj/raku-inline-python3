#!/usr/bin/env raku

use v6.d;
use lib 'lib';
use Inline::Python3::Installer;

# Interactive setup script for Inline::Python3

say q:to/WELCOME/;
    ╔═══════════════════════════════════════════╗
    ║     Inline::Python3 Setup Assistant      ║
    ╚═══════════════════════════════════════════╝
    
    This script will help you set up everything needed
    for Inline::Python3 to work properly.
    
    WELCOME

# Check current status
sub check-status() {
    my %status;
    
    # Check pyenv
    if %*ENV<PYENV_ROOT> && %*ENV<PYENV_ROOT>.IO.d {
        %status<pyenv> = 'installed';
        %status<pyenv-path> = %*ENV<PYENV_ROOT>;
    } elsif %*ENV<HOME>.IO.add('.pyenv').d {
        %status<pyenv> = 'installed-not-configured';
        %status<pyenv-path> = %*ENV<HOME>.IO.add('.pyenv').Str;
    } else {
        %status<pyenv> = 'not-installed';
    }
    
    # Check Python
    if %status<pyenv> eq 'installed' {
        my $version = run('pyenv', 'version', :out, :err);
        if $version.exitcode == 0 {
            my $ver-str = $version.out.slurp(:close);
            if $ver-str ~~ /'3.' (\d+) '.' (\d+)/ {
                %status<python-version> = "3.$0.$1";
                %status<python-ok> = $0.Int >= 8;
            } elsif $ver-str ~~ /system/ {
                %status<python-version> = 'system';
                %status<python-ok> = False;
            }
        }
    }
    
    return %status;
}

# Display status
sub show-status(%status) {
    say "\nCurrent Status:";
    say "─" x 40;
    
    given %status<pyenv> {
        when 'installed' {
            say "✅ pyenv: Installed at %status<pyenv-path>";
        }
        when 'installed-not-configured' {
            say "⚠️  pyenv: Installed but not in PATH";
        }
        default {
            say "❌ pyenv: Not installed";
        }
    }
    
    if %status<python-version> {
        if %status<python-ok> {
            say "✅ Python: %status<python-version> (compatible)";
        } else {
            say "⚠️  Python: %status<python-version> (needs upgrade)";
        }
    } else {
        say "❌ Python: Not configured";
    }
    
    say "";
}

# Main setup flow
my %status = check-status();
show-status(%status);

# Determine what needs to be done
my @tasks;

if %status<pyenv> eq 'not-installed' {
    @tasks.push: 'install-pyenv';
} elsif %status<pyenv> eq 'installed-not-configured' {
    @tasks.push: 'configure-pyenv';
}

if !%status<python-ok> {
    @tasks.push: 'install-python';
}

if @tasks {
    say "Setup needed:";
    for @tasks -> $task {
        given $task {
            when 'install-pyenv' { say "  • Install pyenv" }
            when 'configure-pyenv' { say "  • Configure pyenv in your shell" }
            when 'install-python' { say "  • Install Python 3.8+" }
        }
    }
    
    my $proceed = prompt("\nProceed with automatic setup? [Y/n] ") || 'Y';
    unless $proceed ~~ /:i y/ {
        say "Setup cancelled.";
        exit 0;
    }
} else {
    say "✨ Everything is already set up correctly!";
    exit 0;
}

# Execute tasks
for @tasks -> $task {
    given $task {
        when 'install-pyenv' {
            say "\n📦 Installing pyenv...";
            
            my $installer = PythonInstaller.new(verbose => True);
            try {
                $installer.install-pyenv;
                CATCH {
                    default {
                        say "❌ Failed to install pyenv: $_";
                        say "\nPlease install pyenv manually and run this script again.";
                        exit 1;
                    }
                }
            }
            
            # Update status
            %*ENV<PYENV_ROOT> = %*ENV<HOME> ~ '/.pyenv';
            %*ENV<PATH> = %*ENV<PYENV_ROOT> ~ '/bin:' ~ %*ENV<PATH>;
        }
        
        when 'configure-pyenv' {
            say "\n⚙️  Configuring pyenv...";
            
            %*ENV<PYENV_ROOT> = %status<pyenv-path>;
            %*ENV<PATH> = %status<pyenv-path> ~ '/bin:' ~ %*ENV<PATH>;
            
            # Initialize pyenv
            my $init = qqx{pyenv init -};
            say "✅ pyenv configured for this session";
            
            say "\n📝 Add these lines to your shell configuration file:";
            say "   (~/.bashrc, ~/.zshrc, or equivalent)\n";
            say '   export PYENV_ROOT="$HOME/.pyenv"';
            say '   export PATH="$PYENV_ROOT/bin:$PATH"';
            say '   eval "$(pyenv init -)"';
        }
        
        when 'install-python' {
            say "\n🐍 Installing Python...";
            
            my $preferred = '3.11.5';
            my $version = prompt("Which Python version? [$preferred] ") || $preferred;
            
            say "Installing Python $version (this may take 5-10 minutes)...";
            
            my $result = auto-install-python(version => $version, verbose => True);
            
            if $result {
                say "✅ Python $version installed successfully!";
            } else {
                say "❌ Failed to install Python $version";
                exit 1;
            }
        }
    }
}

# Final check
say "\n" ~ "=" x 50;
say "Setup Complete!";
say "=" x 50;

%status = check-status();
show-status(%status);

if %status<python-ok> {
    say "✨ Inline::Python3 is ready to use!";
    say "\nYou can now install the module with:";
    say "  zef install .";
    
    if 'configure-pyenv' ∈ @tasks {
        say "\n⚠️  Remember to restart your shell or run:";
        say "  source ~/.bashrc  # or ~/.zshrc";
    }
} else {
    say "⚠️  Setup completed but Python is still not configured.";
    say "Please restart your shell and run this script again.";
}

# Offer to run tests
if %status<python-ok> {
    say "";
    my $test = prompt("Would you like to run a quick test? [Y/n] ") || 'Y';
    if $test ~~ /:i y/ {
        say "\nRunning test...";
        
        use Inline::Python3;
        my $py = Inline::Python3.new;
        
        my $result = $py.run('2 + 2', :eval);
        say "Python says: 2 + 2 = $result";
        
        if $result == 4 {
            say "✅ Test passed! Python is working correctly.";
        } else {
            say "❌ Test failed. Something is wrong.";
        }
    }
}