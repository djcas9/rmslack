VERSION=$(shell cat rmslack.go | grep -oP "Version\s+?\=\s?\"\K.*?(?=\"$|$\)")

export GO15VENDOREXPERIMENT=1

DEPS = $(go list -f '{{range .TestImports}}{{.}} {{end}}' ./... | grep -v /vendor/)
NAME=rmslack
DESCRIPTION="Remove slack messages"

CCOS=windows freebsd darwin linux
CCARCH=386 amd64
CCOUTPUT="pkg/{{.OS}}-{{.Arch}}/$(NAME)"

GO_VERSION=$(shell go version)

# Get the git commit
SHA=$(shell git rev-parse --short HEAD)
BUILD_COUNT=$(shell git rev-list --count HEAD)

BUILD_TAG="${BUILD_COUNT}.${SHA}"

NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m
UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
	ECHO=echo
else
	ECHO=/bin/echo -e
endif

build: banner generate
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

gox: 
	@$(ECHO) "$(OK_COLOR)==> Cross Compiling $(NAME)$(NO_COLOR)"
	@gox -os="$(CCOS)" -arch="$(CCARCH)" -output=$(CCOUTPUT)

release: clean build gox
	@mkdir -p release/
	@echo $(VERSION) > .Version
	@for os in $(CCOS); do \
		for arch in $(CCARCH); do \
			cd pkg/$$os-$$arch/; \
			tar -zcvf ../../release/$(NAME)-$$os-$$arch.tar.gz rmslack* > /dev/null 2>&1; \
			cd ../../; \
		done \
	done
	@$(ECHO) "$(OK_COLOR)==> Done Cross Compiling $(NAME)$(NO_COLOR)"

clean:
	@$(ECHO) "$(OK_COLOR)==> Cleaning$(NO_COLOR)"
	@rm -rf .Version
	@rm -rf release/
	@rm -rf bin/
	@rm -rf pkg/

test:
	go list ./... | xargs -n1 go test

strip:
	strip bin/$(NAME)

.PHONY: build test
