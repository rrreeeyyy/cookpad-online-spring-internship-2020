#!/bin/bash -xe

cd "$(dirname $0)"

if ! test -f ../hako/hako.env; then
    echo "hako/hako.env not found"
    exit 1
fi

source ../hako/hako.env

echo "Your GitHub ID: ${github_id}"
github_lower_case=$(echo ${github_id} | tr '[:upper:]' '[:lower:]')

cd ../hako

if ! test -f ${github_lower_case}.jsonnet ; then
    echo "${github_lower_case}.jsonnet not found"
    exit 1s
fi

bundle check || bundle install
bundle exec hako deploy -f ${github_lower_case}.jsonnet -t "$(git rev-parse HEAD)"
