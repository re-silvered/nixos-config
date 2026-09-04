set -euo pipefail

REPO="/etc/nixos"

if [ "$#" -lt 1 ]; then
    echo "Usage:"
    echo "  rebuild test [nixos-rebuild options]"
    echo "  rebuild switch [-m \"commit message\"] [nixos-rebuild options]"
    exit 1
fi

ACTION="$1"
shift

cd "$REPO"

case "$ACTION" in
    test)
        echo "==> Testing NixOS configuration..."

        sudo nixos-rebuild test "$@"

        echo "==> Test succeeded."

        git add -A

        if git diff --cached --quiet; then
            echo "==> No configuration changes to commit."
        else
            git commit -m "test: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "==> Created local test commit."
        fi
        ;;

    switch)
        COMMIT_MESSAGE=""
        REBUILD_ARGS=()

        while [ "$#" -gt 0 ]; do
            case "$1" in
                -m|--message)
                    if [ "$#" -lt 2 ]; then
                        echo "ERROR: $1 requires a commit message."
                        exit 1
                    fi

                    COMMIT_MESSAGE="$2"
                    shift 2
                    ;;

                *)
                    REBUILD_ARGS+=("$1")
                    shift
                    ;;
            esac
        done

        echo "==> Checking remote..."

        UPSTREAM="$(git rev-parse \
            --abbrev-ref \
            --symbolic-full-name '@{u}' \
            2>/dev/null || true)"

        if [ -z "$UPSTREAM" ]; then
            echo "ERROR: Current branch has no upstream."
            echo "Run something like:"
            echo "  git push -u origin main"
            exit 1
        fi

        git fetch

        REMOTE_HEAD="$(git rev-parse "$UPSTREAM")"
        MERGE_BASE="$(git merge-base HEAD "$UPSTREAM")"

        if [ "$MERGE_BASE" != "$REMOTE_HEAD" ]; then
            echo "ERROR: Remote contains commits not present locally."
            echo "Pull/rebase those changes before switching and pushing."
            exit 1
        fi

        echo "==> Switching NixOS configuration..."

        sudo nixos-rebuild switch "${REBUILD_ARGS[@]}"

        echo "==> Switch succeeded."

        echo "==> Running tree script..."
        "$REPO/scripts/update-readme-tree.sh"

        git add -A

        if ! git diff --cached --quiet; then
            git commit \
                -m "test: pre-switch $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        # Check the remote again in case it changed while building.
        git fetch

        REMOTE_HEAD="$(git rev-parse "$UPSTREAM")"
        MERGE_BASE="$(git merge-base HEAD "$UPSTREAM")"

        if [ "$MERGE_BASE" != "$REMOTE_HEAD" ]; then
            echo "ERROR: Remote changed while the rebuild was running."
            echo "System was switched successfully."
            echo "Nothing was squashed or pushed."
            exit 1
        fi

        AHEAD="$(git rev-list --count "$UPSTREAM"..HEAD)"

        if [ "$AHEAD" -eq 0 ]; then
            echo "==> No local commits to push."
            exit 0
        fi

        echo "==> Squashing $AHEAD local commit(s)..."

        git reset --soft "$UPSTREAM"

        if [ -z "$COMMIT_MESSAGE" ]; then
            COMMIT_MESSAGE="NixOS: $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        git commit -m "$COMMIT_MESSAGE"

        echo "==> Pushing..."
        git push

        echo "==> Done."
        ;;

    *)
        sudo nixos-rebuild "$ACTION" "$@"
        ;;
esac