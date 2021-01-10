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
	split_branch="$remote_name-$(date +%s)"
	git subtree split --prefix=$staging_dir/$remote_name --rejoin -b $split_branch 

	git subtree pull --squash -m "Sync upstream $remote_name" --prefix=$staging_dir/$remote_name $remote_name master
	git branch -D $split_branch || true
done <$repo_list

for f in $(ls $staging_dir); do
	sh -c "cd $staging_dir/$f \
		&& go mod edit -replace $downstream_repo=../../ "
	git add $staging_dir/$f/go.mod
done

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

