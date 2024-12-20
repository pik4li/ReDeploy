# Default values for image name and tag
IMAGE_NAME ?= redeploy
IMAGE_TAG ?= latest

# Build the Docker image
build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Clean up dangling images
clean:
	docker image prune -f

# Help message
help:
	@echo "Usage:"
	@echo "  make build IMAGE_NAME=<name> IMAGE_TAG=<tag>  - Build the Docker image with specified name and tag"
	@echo "  make clean                                    - Remove dangling images"
	@echo "  make help                                     - Show this help message"
