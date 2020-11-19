#!/bin/bash

source ./utils.sh

for repo in $(cat tracked); do
	dir=$(echo "$repo" | sed 's!.*/\(.*\)!\1!')
	git_repo_url="git@github.com:$repo.git"
	https_repo_url="https://github.com/$repo.git"
	remote=$(git remote get-url $dir)
	if [ $? -ne 0 ] ; then
		git remote add $dir "git@github.com:$repo.git" 2>&1 || exit_on_error "failed to add remote" $?
	        echo " new remote $repo"
	elif [ "$remote" != "$git_repo_url" ] && [ "$remote" != "$https_repo_url" ]; then
		exit_on_error "Cannot track subtree $i: existing remote $dir does not point to expected repository"
	fi

	if [ ! -d "$dir" ]; then
		# test to see if HEAD is a valid ref
		git rev-parse --symbolic-full-name --abbrev-ref HEAD >/dev/null 2>&1 || exit_on_error "invalid ref HEAD, cannot add subtree" 

		git diff-index --quiet HEAD || exit_on_error "Git status not clean, aborting !!\\n\\n$(git status)"

		# repo either newly created
		ref=$(git show-ref remotes/$dir/master -s)
		git subtree add --prefix="$dir/" "$dir" --squash master || exit_on_error "failed to add subtree" $?
		echo "$ref" > $dir.UPSTREAM_VERSION
		git add $dir.UPSTREAM_VERSION
		git commit -m "bump upstream version"
		echo "Added new subtree $repo"
	fi
done
