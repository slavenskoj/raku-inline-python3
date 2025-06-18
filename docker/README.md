# Docker Support for Inline::Python3

This directory contains Docker configurations for building, testing, and deploying Inline::Python3.

## Quick Start

```bash
# Build and start development environment
make dev

# Run tests
make test

# Start Jupyter notebook
make jupyter
```

## Available Images

### 1. Development Image (`inline-python3:dev`)
Full development environment with:
- Raku and Python 3.11
- All development tools (vim, gdb, etc.)
- Python scientific stack (numpy, pandas, scikit-learn)
- Jupyter notebook support
- Test frameworks

### 2. Production Image (`inline-python3:prod`)
Minimal runtime environment with:
- Raku and Python 3.11
- Only essential Python packages
- Non-root user for security
- Read-only filesystem capability

### 3. Test Image (`inline-python3:test`)
Testing environment with:
- All test dependencies
- Test runners configured
- Coverage tools

### 4. Multi-Python Images
- `inline-python3:py38` - Python 3.8
- `inline-python3:py39` - Python 3.9
- `inline-python3:py310` - Python 3.10

## Docker Compose Services

### Development Services

```bash
# Interactive development shell
docker-compose run --rm dev

# Run specific command
docker-compose run --rm dev raku examples/data-science.raku
```

### Testing Services

```bash
# Run all tests
docker-compose run --rm test

# Test with specific Python version
docker-compose run --rm python38
docker-compose run --rm python39
docker-compose run --rm python310
```

### Jupyter Notebook

```bash
# Start Jupyter (accessible at http://localhost:8888)
docker-compose up jupyter
```

### Documentation

```bash
# Generate API documentation
docker-compose run --rm docs
```

### Benchmarking

```bash
# Run performance benchmarks
docker-compose run --rm benchmark
```

## Makefile Commands

The Makefile provides convenient shortcuts:

```bash
make help          # Show all commands
make build         # Build all images
make dev           # Start development container
make test          # Run test suite
make prod          # Build production image
make jupyter       # Start Jupyter notebook
make docs          # Generate documentation
make benchmark     # Run benchmarks
make multi-python  # Test with all Python versions
make clean         # Remove all containers and images
```

## Building Images

### Development Build

```bash
docker build --target development -t inline-python3:dev .
```

### Production Build

```bash
docker build --target production -t inline-python3:prod .
```

### Custom Python Version

```bash
docker build -f Dockerfile.python38 -t inline-python3:py38 .
```

## Volume Mounts

The development container mounts several volumes:

- `.:/workspace` - Project files
- `raku-cache:/root/.raku` - Raku module cache
- `python-cache:/root/.cache/pip` - Python package cache

## Environment Variables

Key environment variables set in containers:

- `PERL6LIB=/workspace/lib` - Raku library path
- `LD_LIBRARY_PATH=/workspace/resources/libraries` - C library path
- `PYTHONUNBUFFERED=1` - Unbuffered Python output

## Security Considerations

The production image includes security features:
- Non-root user (`appuser`)
- Read-only root filesystem capability
- No new privileges flag
- Dropped Linux capabilities

## Troubleshooting

### C Library Issues

If the C library fails to build:

```bash
# Rebuild just the library
docker-compose run --rm dev bash -c "cd src && make clean && make"
```

### Python Version Conflicts

Check Python version in container:

```bash
docker-compose run --rm dev python3 --version
```

### Permission Issues

If you encounter permission issues with mounted volumes:

```bash
# Run as root user
docker-compose run --rm --user root dev
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests in Docker
        run: |
          docker build --target test -t inline-python3:test .
          docker run --rm inline-python3:test
```

### GitLab CI Example

```yaml
test:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build --target test -t inline-python3:test .
    - docker run --rm inline-python3:test
```

## Deployment

### Using Production Image

```dockerfile
FROM inline-python3:prod

# Copy your application
COPY my-app.raku /app/

# Run your application
CMD ["raku", "/app/my-app.raku"]
```

### Docker Swarm

```yaml
version: '3.8'
services:
  app:
    image: inline-python3:prod
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inline-python3-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: inline-python3:prod
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
```

## Best Practices

1. **Use specific targets**: Build only what you need (dev/prod/test)
2. **Cache dependencies**: Use volume mounts for package caches
3. **Multi-stage builds**: Keep production images small
4. **Security scanning**: Run `make security-scan` regularly
5. **Version pinning**: Pin Python and Raku versions for reproducibility