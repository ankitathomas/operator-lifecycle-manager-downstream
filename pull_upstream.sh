#!/bin/bash

source ./utils.sh

if [ $# -lt 1 ]; then
	echo "usage: $0 <subtree to pull>"
	exit 0
fi

repodir=$1
remote="$repodir"
versionfile="$repodir.UPSTREAM_VERSION"

git diff-index --quiet HEAD || exit_on_error "Git status not clean, aborting !!\\n\\n$(git status)"

git fetch --all
git fetch $remote master || exit_on_error "Failed to fetch remote"

ref=$(git rev-parse "$remote/FETCH_HEAD")

shortref=$(echo "$ref" | sed 's/.*\.\([^.]\{,6\}\)[^.]*/\1/')
newbranch="$repodir-$shortref-$(date "+%s")"

git checkout -b "$newbranch"

git merge --no-commit -Xsubtree=$repodir $ref

unmerged_files=$(git diff --name-only --diff-filter=U --exit-code)
differences=$?
if [[ $differences -eq 1 ]]; then
  unmerged_files_oneline=$(echo "$unmerged_files" | paste -s -d ' ')
  git checkout --theirs -- $unmerged_files_oneline
  if [[ $(git diff --check) ]]; then
    echo "All conflict markers should have been taken care of, aborting."
    exit 1
  fi
  git add -- $unmerged_files_oneline
else
  unmerged_files="<NONE>"
fi

# bump UPSTREAM-VERSION file
echo "$version" > $versionfile
git add $versionfile

# just to make sure an old version merge is not being made
git diff --staged --quiet && { echo "No changed files in merge?! Aborting."; exit 0; }

# make local commit
git commit -m "Merge upstream master" -m "Merge executed via $0 $1" -m "$(printf "Overwritten conflicts:\\n%s" "$unmerged_files")"

printf "\\n** Upstream merge complete! **\\n"
echo "$ git checkout $newbranch"
echo "$ git push origin $newbranch:master"

