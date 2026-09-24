#!/bin/bash
set -eo pipefail

# Usage: select-mirror-tags.sh <image> <scope> [tag...]
#
# Prints (one per line) the tags of <image> that should be mirrored to Docker Hub.
#
#   latest-release    tags sharing the digest of "latest", i.e. one image, all its tags
#   current-releases  all floating tags, plus the fixed tags they point to
#   all-tags          every tag in the repository
#   custom            the tags given as extra arguments
#
# crane is invoked through $CRANE, so this runs both in CI and on a local machine.

IMAGE="$1"
SCOPE="$2"
shift 2 || true

if [ -z "$IMAGE" ] || [ -z "$SCOPE" ]; then
    echo "Error: IMAGE and SCOPE arguments are required." >&2
    echo "Usage: $0 <image> <scope> [tag...]" >&2
    exit 1
fi

CRANE="${CRANE:-docker run --rm -v $HOME/.docker:/root/.docker gcr.io/go-containerregistry/crane:latest}"

# Floating tags as documented in README.md: latest, ghc-m.n.p, stackage-lts-m.n
FLOATING_PATTERN='^(latest|ghc-[0-9]+\.[0-9]+\.[0-9]+|stackage-lts-[0-9]+\.[0-9]+)$'

case "$SCOPE" in
    custom)
        if [ "$#" -eq 0 ]; then
            echo "Error: scope 'custom' needs at least one tag." >&2
            exit 1
        fi
        printf '%s\n' "$@"
        ;;

    all-tags)
        $CRANE ls "$IMAGE"
        ;;

    latest-release|current-releases)
        ALL_TAGS=$($CRANE ls "$IMAGE")

        if [ "$SCOPE" = "latest-release" ]; then
            ANCHORS="latest"
        else
            ANCHORS=$(echo "$ALL_TAGS" | grep -E "$FLOATING_PATTERN" || true)
        fi

        if [ -z "$ANCHORS" ]; then
            echo "Error: no floating tags found on $IMAGE for scope '$SCOPE'." >&2
            exit 1
        fi

        echo "Anchor tags: $(echo "$ANCHORS" | tr '\n' ' ')" >&2

        # Resolve the anchors to digests; every tag pointing at one of them is mirrored.
        WANTED_DIGESTS=""
        for tag in $ANCHORS; do
            digest=$($CRANE digest "$IMAGE:$tag")
            echo "  $tag -> $digest" >&2
            WANTED_DIGESTS="$WANTED_DIGESTS $digest"
        done

        for tag in $ALL_TAGS; do
            digest=$($CRANE digest "$IMAGE:$tag")
            case " $WANTED_DIGESTS " in
                *" $digest "*) echo "$tag" ;;
            esac
        done
        ;;

    *)
        echo "Error: unknown scope '$SCOPE'." >&2
        echo "Expected: latest-release, current-releases, all-tags or custom" >&2
        exit 1
        ;;
esac
