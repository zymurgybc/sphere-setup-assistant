#!/usr/bin/env bash
set -ex

OWNER=ninjasphere
BIN_NAME=sphere-setup-assistant
PROJECT_NAME=sphere-setup-assistant


# Get the parent directory of where this script is.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

GIT_COMMIT="$(git rev-parse HEAD)"
GIT_DIRTY="$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)"
VERSION="$(grep "const Version " version.go | sed -E 's/.*"(.+)"$/\1/' )"

PRIVATE_PKG="ninjasphere/go-ninja ninjasphere/sphere-go-led-controller ninjasphere/sphere-client"

# remove working build
# rm -rf .gopath
if [ ! -d ".gopath" ]; then
	mkdir -p .gopath/src/github.com/${OWNER}
	ln -sf ../../../.. .gopath/src/github.com/${OWNER}/${PROJECT_NAME}
fi

export GOPATH="$(pwd)/.gopath"

for p in $PRIVATE_PKG; do
    if [ ! -d $GOPATH/src/github.com/$p ]; then
		git clone git@github.com:${p}.git $GOPATH/src/github.com/$p
    fi
done

# move the working path and build
cd .gopath/src/github.com/${OWNER}/${PROJECT_NAME}
go get -d -v ./...

# building the master branch on ci
export CGO_CFLAGS=
export CGO_LDFLAGS=
go clean -r github.com/ninjasphere/go-wireless github.com/ninjasphere/sphere-setup-assistant
if [ "$BUILDBOX_BRANCH" = "master" ]; then
	go build -ldflags "-X main.BugsnagKey ${BUGSNAG_KEY}" -tags release -o ./bin/${BIN_NAME}
else
	go build -o ./bin/${BIN_NAME}
fi
