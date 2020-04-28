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

if ! test -f ${github_lower_case}-oneshot-tsukurepo_backend.jsonnet ; then
    echo "${github_lower_case}-oneshot-tsukurepo_backend.jsonnet not found"
    exit 1;
fi

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 some command arguments"
    echo "  ex.) $0 bundle exec ridgepole:apply"
    exit 2;
fi

bundle check || bundle install
bundle exec hako oneshot ${github_lower_case}-oneshot-tsukurepo_backend.jsonnet -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 -- $@
