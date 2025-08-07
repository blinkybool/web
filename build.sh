#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Build the Jekyll site and publish it to a git work-tree that tracks branch
# `gh-pages`.  If that work-tree (or even the branch) doesn’t exist yet,
# create it automatically.
# -----------------------------------------------------------------------------
set -euo pipefail

WORKTREE_DIR="gh-pages"   # folder that will contain the work-tree
BRANCH="gh-pages"         # branch to publish to
DEST="$WORKTREE_DIR/docs" # final site location  (<branch>/docs)

# Ensure we are being run from the web/ directory
cd "$(dirname "$0")"

# ────────────────────────────────────────────────────────────────────────────
# 1. Make sure the work-tree exists and is on the right branch
# ────────────────────────────────────────────────────────────────────────────
if [ ! -d "$WORKTREE_DIR" ]; then
  echo "▶ Creating work-tree '$WORKTREE_DIR' for branch '$BRANCH' …"

  # Does the branch already exist?
  if git show-ref --quiet "refs/heads/$BRANCH"; then
    # Local branch exists – just check it out into a new work-tree
    git worktree add "$WORKTREE_DIR" "$BRANCH"
  else
    # No local branch – create it (optionally from remote if it exists)
    if git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
      git worktree add -B "$BRANCH" "$WORKTREE_DIR" "origin/$BRANCH"
    else
      git worktree add -B "$BRANCH" "$WORKTREE_DIR"
    fi
  fi
  echo "✓ Work-tree ready."
fi

# ────────────────────────────────────────────────────────────────────────────
# 2. Build the site
# ────────────────────────────────────────────────────────────────────────────
echo "▶ Building Jekyll site → $DEST"
bundle install --quiet
bundle exec jekyll build --destination "$DEST"

# ────────────────────────────────────────────────────────────────────────────
# 3. Post-process output
# ────────────────────────────────────────────────────────────────────────────
touch "$DEST/.nojekyll"          # tell GitHub Pages not to run Jekyll again
cp -f CNAME "$DEST" 2>/dev/null || true
rm -f  "$DEST/build.sh"          # don’t publish the script itself

# ────────────────────────────────────────────────────────────────────────────
# 4. Commit & push
# ────────────────────────────────────────────────────────────────────────────
echo "▶ Committing and pushing to $BRANCH …"
(
  cd "$WORKTREE_DIR"
  git add -A
  git commit -m "build" --allow-empty
  git push origin "$BRANCH"
)

echo "✓ Deployment finished."
