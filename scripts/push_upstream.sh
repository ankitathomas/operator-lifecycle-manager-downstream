#!/bin/bash

set -eu

source "$(dirname $0)/utils.sh"

if [ $# -lt 2 ]; then
	echo "Push a commit range or ref to a staged upstream repository"
	echo "usage: $0 <subtree to push> <ref>"
	exit 0
fi

remote=$1
ref=$2
repodir=staging/$1

git fetch -t $remote

shortref=$(echo "$ref" | sed 's/.*\.\([^.]\{,6\}\)[^.]*/\1/')
newbranch="$repodir-$shortref-$(date "+%s")"

localrev=$(git subtree split --prefix="$repodir") || exit_on_error "failed to create subtree branch"
echo git push "$remote" "$localrev":"$newbranch"
git push "$remote" "$localrev":"refs/heads/$newbranch" || exit_on_error "push failed"

echo "pushed to remote branch $newbranch"
