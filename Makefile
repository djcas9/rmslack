export GO15VENDOREXPERIMENT=1

DEPS = $(go list -f '{{range .TestImports}}{{.}} {{end}}' ./... | grep -v /vendor/)
NAME=rmslack
DESCRIPTION="Remove slack messages"

GO_VERSION=$(shell go version)

# Get the git commit
SHA=$(shell git rev-parse --short HEAD)
BUILD_COUNT=$(shell git rev-list --count HEAD)

BUILD_TAG="${BUILD_COUNT}.${SHA}"

build: banner lint generate
	@echo "Building $(NAME)..."
	@mkdir -p bin/
	@go build \
		-ldflags "-X main.build=${BUILD_TAG}" \
		${ARGS} \
		-o bin/$(NAME)

banner:
	@echo "$(NAME)"
	@echo "${GO_VERSION}"
	@echo "Go Path: ${GOPATH}"
	@echo

generate:
	@echo "Running go generate..."
	@go generate $$(go list ./... | grep -v /vendor/)

lint:
	@go vet  $$(go list ./... | grep -v /vendor/)
	@for pkg in $$(go list ./... |grep -v /vendor/ |grep -v /kuber/) ; do \
		golint -min_confidence=1 $$pkg ; \
		done

test:
	go list ./... | xargs -n1 go test

strip:
	strip bin/$(NAME)

.PHONY: build test
