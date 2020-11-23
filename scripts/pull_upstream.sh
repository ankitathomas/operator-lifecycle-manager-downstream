#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Pull updated from all upstream staged repositories"
	echo "usage: $0"
	exit 0
fi

source "$(dirname $0)/utils.sh"

while read -r line; do
        remote_name=$(echo "$line" | awk '{print $1}')
	git fetch -t $remote_name master

	ref=$(git rev-parse "FETCH_HEAD")

	git merge --no-commit -Xsubtree=$repodir $ref

	unmerged_files=$(git diff --name-only --diff-filter=U --exit-code)
	differences=$?
	# TODO: amend and continue, instead of prefering theirs
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
done <$repo_list

# just to make sure an old version merge is not being made
git diff --staged --quiet && { echo "No changed files in merge?! Aborting."; exit 0; }

# make local commit
git commit -m "Sync upstream master" 

printf "\\n** Upstream merge complete! **\\n"
echo "$ git checkout $temp_branch"
echo "$ git push origin $temp_branch:master"

