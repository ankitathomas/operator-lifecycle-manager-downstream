#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Pull from specified upstream staged repository. Syncs with upstream master if branch isn't specified."
	echo "usage: $0 <remote> [<branch>]"
	exit 0
fi

source "$(dirname $0)/utils.sh"

upstream_remote_url=$(git remote get-url "$1")
upstream_remote_name="$(grep $upstream_remote_name $repo_list | awk '{print $1}')"
staged_dir="$staging_dir/$upstream_remote_name"
split_branch="$remote_name-$(date %+s)"
target_branch=${2:-master}

if [ "$staged_dir" == "$staging_dir/" ] || [ ! -d "$staged_dir" ]; then
	echo "Missing remote from $repo_list"
	exit 1
fi

git fetch -t $remote_name $target_branch
git subtree split --prefix=$staging_dir/$remote_name --rejoin -b $split_branch 

git subtree pull --squash -m "Sync upstream $remote_name" --prefix=$staging_dir/$remote_name $remote_name $target_branch
git branch -D $split_branch || true

sh -c "cd $staged_dir \
	&& go mod edit -replace $downstream_repo=../../ "
git add $staged_dir/go.mod

git commit --amend --no-edit

printf "\\n** Upstream merge complete! **\\n"
echo "** You can now inspect the branch. **"
echo ""
git diff --dirstat ${current_branch}..${temp_branch}
echo "** Push the changes to remote with **"
echo ""
echo "$ git checkout $temp_branch"
echo "$ git push origin $temp_branch:<BRANCH>"
# echo "$ git checkout $temp_branch"
# echo "$ git push origin $temp_branch:master"

