#!/bin/bash

source ./utils.sh

if [ $# -lt 1 ]; then
	echo "usage: $0 <subtree to push> [<ref>]"
	exit 0
fi

repodir=$1
remote="$repodir"
versionfile="$repodir.UPSTREAM_VERSION"

git diff-index --quiet HEAD || exit_on_error "Git status not clean, aborting !!\\n\\n$(git status)"

if [ $# -gt 2 ]; then
	ref=$2
else
	HEAD=$(git rev-parse HEAD)
	ls "$repodir.UPSTREAM_VERSION" || exit_on_error "upstream version file missing, "
	if [ ! -f "$versionfile" ]; then
		echo "$versionfile file missing, pushing HEAD"
		ref="$HEAD"	
	else
		ref="$(cat "$versionfile")..$HEAD"
		if [ $ref == "..$HEAD" ]; then
			echo "$versionfile file empty, pushing HEAD"
			ref="$HEAD"
		fi
	fi
fi

shortref=$(echo "$ref" | sed 's/.*\.\([^.]\{,6\}\)[^.]*/\1/')
newbranch="$repodir-$shortref-$(date "+%s")"

localrev=$(git subtree split --prefix="$repodir") || exit_on_error "failed to create subtree branch"
echo git push "$remote" "$localrev":"$newbranch"
git push "$remote" "$localrev":"refs/heads/$newbranch" || exit_on_error "push failed"

echo "pushed to remote branch $newbranch"
