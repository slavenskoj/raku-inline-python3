# Makefile for Inline::Python3 Docker operations

.PHONY: help build test dev prod clean all docs benchmark multi-python

# Default target
help:
	@echo "Inline::Python3 Docker Commands:"
	@echo "  make build       - Build all Docker images"
	@echo "  make dev         - Start development container"
	@echo "  make test        - Run test suite"
	@echo "  make prod        - Build production image"
	@echo "  make jupyter     - Start Jupyter notebook server"
	@echo "  make docs        - Generate documentation"
	@echo "  make benchmark   - Run performance benchmarks"
	@echo "  make multi-python - Test with multiple Python versions"
	@echo "  make clean       - Remove all containers and images"
	@echo "  make all         - Build and test everything"

# Build all images
build:
	docker-compose build

# Development environment
dev: build
	docker-compose run --rm dev

# Run tests
test: build
	docker-compose run --rm test

# Production build
prod: build
	docker-compose build prod
	@echo "Production image built: inline-python3:prod"

# Jupyter notebook
jupyter: build
	@echo "Starting Jupyter notebook on http://localhost:8888"
	docker-compose up jupyter

# Generate documentation
docs: build
	docker-compose run --rm docs

# Run benchmarks
benchmark: build
	docker-compose run --rm benchmark

# Test with multiple Python versions
multi-python:
	@echo "Testing with Python 3.8..."
	docker-compose build python38
	docker-compose run --rm python38
	@echo "\nTesting with Python 3.9..."
	docker-compose build python39
	docker-compose run --rm python39
	@echo "\nTesting with Python 3.10..."
	docker-compose build python310
	docker-compose run --rm python310

# Run all tests and builds
all: build test multi-python docs benchmark
	@echo "All builds and tests completed!"

# Clean up
clean:
	docker-compose down -v
	docker images | grep inline-python3 | awk '{print $$3}' | xargs -r docker rmi -f
	@echo "Cleaned up all containers and images"

# Quick test - just run basic tests in dev container
quick-test:
	docker-compose run --rm dev raku -I lib t/01-basic.t

# Interactive Python shell in container
python-shell:
	docker-compose run --rm dev python3

# Interactive Raku shell in container
raku-shell:
	docker-compose run --rm dev raku

# Build C library only
build-lib:
	docker-compose run --rm dev bash -c "cd src && make"

# Run specific example
run-example:
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "Usage: make run-example EXAMPLE=data-science"; \
		echo "Available examples:"; \
		echo "  - data-science"; \
		echo "  - web-scraping"; \
		echo "  - machine-learning"; \
		echo "  - natural-language"; \
		echo "  - async-operations"; \
		echo "  - interactive-visualization"; \
	else \
		docker-compose run --rm dev raku examples/$(EXAMPLE).raku; \
	fi

# Check for security vulnerabilities
security-scan:
	@echo "Scanning images for vulnerabilities..."
	docker scan inline-python3:prod || echo "Docker scan not available. Install with: docker scan --accept-license"

# Show image sizes
image-sizes:
	@echo "Docker image sizes:"
	@docker images | grep inline-python3 | awk '{printf "%-20s %s\n", $$1":"$$2, $$7}'

# Export production image
export-image:
	docker save inline-python3:prod | gzip > inline-python3-prod.tar.gz
	@echo "Production image exported to inline-python3-prod.tar.gz"

# Import production image
import-image:
	docker load < inline-python3-prod.tar.gz
	@echo "Production image imported"