#!/bin/bash

set -eu

source ./utils.sh

trap 'exit_on_error "$0:" $?' ERR

staging_dir="../staging"
repo_list="tracked"

case "$*" in
	*" -h"*|"-h"|*" --help"*|"--help"|"")
	echo "usage: $0 <git remote url>"
	exit 0
	;;
esac

if [ ! -f $repo_list ]; then
	touch $repo_list
fi

if [ ! -d "$staging_dir" ]; then
	mkdir $staging_dir
fi

# check if remote is valid
git ls-remote $1 

remote_url=$1

remote_name=$(echo $remote_url | sed 's!.*/\([^\/]*\)!\1!' | sed 's/.git$//')
if [ "|$remote_name|" == "||" ]; then
	exit_on_error "cannot get repository name from $remote_url"
fi

if [ $(grep "$remote_name " $repo_list | sed 's/.* \(.*\)/\1/' | wc -c) -gt 0 ]; then
	tracked_url=$(grep "$remote_name " $repo_list | sed 's/.* \(.*\)/\1/')
	if [ $tracked_url != $remote_url ]; then
		echo "remote $remote_name tracked with url $tracked_url"
		# prefer url in repo_list file
		remote_url=$tracked_url
	fi
else
	echo "$remote_name $remote_url" >> $repo_list
fi

if [ $(git remote get-url $remote_name | wc -c) -eq 0 ]; then
	git remote add $remote_name $remote_url
fi

# check if directory is present on subtree_dir
if [ ! -d "$staging_dir/$remote_name" ]; then
	git rev-parse --symbolic-full-name --abbrev-ref HEAD >/dev/null 2>&1 || exit_on_error "invalid ref HEAD, cannot add subtree" $?

	git diff-index --quiet HEAD || exit_on_error "Git status not clean, aborting !!\\n\\n$(git status)" $?

	# repo either newly created
	ref=$(git show-ref remotes/$dir/master -s)
	git subtree add --prefix="$dir/" "$dir" --squash master
	echo "Added new subtree $repo"
	git commit -m "tracking new subtree $dir"
else
	echo "$staging_dir/$remote_name already exists"
fi

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
		git rev-parse --symbolic-full-name --abbrev-ref HEAD >/dev/null 2>&1 || exit_on_error "invalid ref HEAD, cannot add subtree" $?

		git diff-index --quiet HEAD || exit_on_error "Git status not clean, aborting !!\\n\\n$(git status)" $?

		# repo either newly created
		ref=$(git show-ref remotes/$dir/master -s)
		git subtree add --prefix="$dir/" "$dir" --squash master || exit_on_error "failed to add subtree" $?
		echo "$ref" > $dir.UPSTREAM_VERSION
		git add $dir.UPSTREAM_VERSION
		git commit -m "tracking new subtree $dir"
		echo "Added new subtree $repo"
	fi
done
