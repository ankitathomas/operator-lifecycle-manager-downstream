#!/bin/bash

function cleanup_and_reset_branch {
	if [ -n ${temp_branch} ]; then
		git checkout -f "${current_branch}" >/dev/null 2>&1 || true
		git branch -D "${temp_branch}" >/dev/null 2>&1 || true
	fi
	if [[ -n "${prtext}" ]]; then
		rm "${prtext}"
	fi
}

function exit_on_error {
        last="$#"
        code=1
        if [ $# -gt 0 ]; then
                usr_code=$(eval echo "\${$last}")
                if [[ "${usr_code}" =~ ^[0-9]+$ ]]; then
                        last=$(( $# - 1 ))
                        code=${usr_code}
                fi
        fi
        if [ -z $code ]; then
                return
        fi
        msg="[ERROR] line $(caller)"
        if [ ${last} -gt -1 ]; then
                msg="${msg}: ${@:1:${last}}"
        fi
        echo -e "\e[91m${msg}\e[0m"
	cleanup_and_reset_branch
        exit ${code}
}


if [[ -z ${GITHUB_USER:-} ]]; then
  exit_on_error "Please export GITHUB_USER=<your-user> (or GH organization, if that's where your fork lives)"
fi

if ! which git > /dev/null; then
  exit_on_error "Can't find git in PATH"
fi

git subtree &>/dev/null
if [ $? -eq 1 ]; then
	exit_on_error "installed git version does not support subtree command, please see https://github.com/git/git/tree/master/contrib/subtree"
fi

if git_status=$(git status --porcelain --untracked=no 2>/dev/null) && [[ -n "${git_status}" ]]; then
  exit_on_error "Git status not clean, aborting !!\\n\\n$(git status)" $?
  exit 1
fi

trap 'exit_on_error "$0:" $?' ERR

current_branch=$(git symbolic-ref --short HEAD)
repo_root=$(git rev-parse --show-toplevel)
staging_dir="staging"
repo_list="scripts/tracked"
temp_branch="automated-sync-$(date +%s)"

cd ${repo_root}

if [[ -e ".git/rebase-apply" ]]; then
  exit_on_error "!!! 'git rebase' or 'git am' in progress, aborting"
fi

git checkout -b ${temp_branch}

if [ ! -f ${repo_list} ]; then
	touch ${repo_list}
fi

if [ ! -d "${staging_dir}" ]; then
	mkdir ${staging_dir}
fi

cleanup_and_reset_branch
