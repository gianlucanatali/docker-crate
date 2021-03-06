#!/bin/bash -x

function usage() {
    echo ""
    echo "./update.sh"
    echo -e "\t--crate-version CRATE_VERSION"
    echo -e "\t--crash-version CRASH_VERSION"
    echo -e "\t--jdk-version JDK_VERSION"
    echo -e "\t--jdk-url JDK_URL"
    echo -e "\t--template TEMPLATE"
    echo ""
}

while [[ $# -gt 1 ]]; do
    case "${1}" in
    --crate-version)
        CRATE_VERSION="${2}"
        shift
        ;;
    --crash-version)
        CRASH_VERSION="${2}"
        shift
        ;;
    --jdk-version)
        JDK_VERSION="${2}"
        shift
        ;;
    --jdk-url)
        JDK_URL="${2}"
        shift
        ;;
    --template)
        TEMPLATE="${2}"
        shift
        ;;
    *)
        echo "ERROR: unknown parameter \"$PARAM\""
        usage
        exit 1
        ;;
    esac
    shift
done

if [[ -z "${CRATE_VERSION}" || -z "${CRASH_VERSION}" || -z "${TEMPLATE}" ]]; then
    usage
    exit 1
else
    TAG="${CRATE_VERSION}"
    TEMPLATE="${TEMPLATE}.j2"
    CRATE_VERSION=`echo ${TAG} | cut -d '-' -f 1`
    if [[ -z "${JDK_VERSION}" ]]; then
        JDK_VERSION=11.0.1
    else
        JDK_VERSION=${JDK_VERSION}
    fi
    if [[ -z "${JDK_URL}" ]]; then
        JDK_URL="https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_linux-x64_bin.tar.gz"
    else
        JDK_URL=${JDK_URL}
    fi
fi

JDK_SHA256=$(curl $JDK_URL.sha256)

VERSION_EXISTS=$(curl -fsSI https://cdn.crate.io/downloads/releases/crate-${CRATE_VERSION}.tar.gz)

if [ "$?" != "0" ]; then
    echo "version $VERSION doesn't exist!"
    exit 1
fi

CRASH_VERSION_EXISTS=$(curl -fsSI https://cdn.crate.io/downloads/releases/crash_standalone_$CRASH_VERSION)

if [ "$?" != "0" ]; then
    echo "crash version $CRASH_VERSION doesn't exist!"
    exit 1
fi

TAG_EXISTS=$(git tag | grep $TAG)

if [ "$TAG" == "$TAG_EXISTS" ]; then
    echo "Tag $TAG_EXISTS already in use"
    exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Template $TEMPLATE does not exist"
    exit 1
fi

BUILD_TIMESTAMP=$(TZ=UTC date '+%FT%T.%N%:z')

jinja2 \
    -D CRATE_VERSION=$CRATE_VERSION \
    -D CRASH_VERSION=$CRASH_VERSION \
    -D BUILD_TIMESTAMP=$BUILD_TIMESTAMP \
    -D JDK_VERSION=$JDK_VERSION \
    -D JDK_URL=$JDK_URL \
    -D JDK_SHA256=$JDK_SHA256 \
    $TEMPLATE > Dockerfile
