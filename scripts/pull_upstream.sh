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

printf "\\n** Upstream merge complete! **\\n"
echo "$ git checkout $temp_branch"
echo "$ git push origin $temp_branch:master"

