VERSION=$(shell cat rmslack.go | grep -oP "Version\s+?\=\s?\"\K.*?(?=\"$|$\)")
NAME="rmslack"

CCOS=windows freebsd darwin linux
CCARCH=386 amd64
CCOUTPUT="pkg/{{.OS}}-{{.Arch}}/$(NAME)"

NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m
DEPS = $(go list -f '{{range .TestImports}}{{.}} {{end}}' ./...)
UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
	ECHO=echo
else
	ECHO=/bin/echo -e
endif

all: deps
	@mkdir -p bin/
	@$(ECHO) "$(OK_COLOR)==> Building $(NAME) - $(VERSION) $(NO_COLOR)"
	@godep go build -o bin/$(NAME)
	@chmod +x bin/$(NAME)
	@$(ECHO) "$(OK_COLOR)==> Done$(NO_COLOR)"


deps:
	@$(ECHO) "$(OK_COLOR)==> Installing dependencies$(NO_COLOR)"
	@godep get

updatedeps:
	@$(ECHO) "$(OK_COLOR)==> Updating all dependencies$(NO_COLOR)"
	@go get -d -v -u ./...
	@echo $(DEPS) | xargs -n1 go get -d -u
	@godep update ...

test: deps
	@$(ECHO) "$(OK_COLOR)==> Testing $(NAME)...$(NO_COLOR)"
	godep go test ./...

goxBuild:
	@gox -os="$(CCOS)" -arch="$(CCARCH)" -build-toolchain

gox: 
	@$(ECHO) "$(OK_COLOR)==> Cross Compiling $(NAME)$(NO_COLOR)"
	@mkdir -p Godeps/_workspace/src/github.com/mephux/rmslack
	@cp -R *.go Godeps/_workspace/src/github.com/mephux/rmslack
	@GOPATH=$(shell godep path) gox -os="$(CCOS)" -arch="$(CCARCH)" -output=$(CCOUTPUT)
	@rm -rf Godeps/_workspace/src/github.com/mephux/rmslack

release: clean all gox
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
	@rm -rf Godeps/_workspace/src/github.com/mephux/rmslack
	@rm -rf .Version
	@rm -rf release/
	@rm -rf bin/
	@rm -rf pkg/

install: clean all

uninstall: clean

tar: 

.PHONY: all clean deps
