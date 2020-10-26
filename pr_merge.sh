#!/bin/bash

# If a script errors, force the script to fail immediately.
set -e

# Note: requires hub and jq to be installed

# https://hub.github.com/hub-api.1.html
# https://github.com/github/hub/issues/1483#issuecomment-458182625
# https://github.com/vitorgalvao/tiny-scripts/blob/master/climergebutton

# https://gist.github.com/OliverJAsh/929c761c8ecbf14d0010634a3f015740

# https://github.com/cli/cli/issues/373
# https://github.com/cli/cli/pull/899
# `gh pr merge`

# https://github.com/cli/cli/issues/380
# https://github.com/github/hub/pull/2280

# Differences from `hub merge`:
# https://github.com/github/hub/issues/1483#issuecomment-395723161

# Delete local head branch
# Delete remote head branch
# Update/sync local base branch
# Update other PR's base branch (dependent) to this PR's base branch
# Warn about other dependent PRs

ID=$1
# https://unix.stackexchange.com/questions/225943/except-the-1st-argument/225951#225951
REST=${@:2}

REPO_PATH="repos/{owner}/{repo}"
PR_PATH="$REPO_PATH/pulls/$ID"

function merge_pr () {
    echo "Merging $ID"

    # https://developer.github.com/v3/pulls/#merge-a-pull-request-merge-button
    hub api -XPUT $PR_PATH/merge
    # TODO: ?
    # echo $REST | xargs hub api -XPUT $PR_PATH/merge
}

function after () {
    # https://developer.github.com/v3/pulls/#get-a-single-pull-request
    RESPONSE=$(hub api $PR_PATH)

    BASE_BRANCH=$(echo $RESPONSE | jq -r '.base.ref')
    HEAD_BRANCH=$(echo $RESPONSE | jq -r '.head.ref')
    # TODO: use correct remote, as in
    # https://github.com/tj/git-extras/blob/500ea2b11981b43742b26f85ba4c43633230ff63/bin/git-delete-branch
    # Why does `git config branch.$branch.remote` return nothing?
    # REMOTE="origin"
    # TODO: careful, could exist on other remotes?
    # TODO: support no config, e.g. revert PR
    REMOTE=`git config branch.$HEAD_BRANCH.remote`

    echo "Updating local base branch ($BASE_BRANCH)"

    git checkout $BASE_BRANCH
    git pull --rebase

    echo "Deleting remote head branch ($REMOTE/$HEAD_BRANCH)"

    # Don't fail if remote fails
    set +e
    git push $REMOTE :$HEAD_BRANCH
    set -e

    echo "Deleting local head branch ($HEAD_BRANCH)"

    git branch --delete $HEAD_BRANCH
}

merge_pr

after
