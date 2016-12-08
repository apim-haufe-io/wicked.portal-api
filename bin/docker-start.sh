#!/bin/bash

set -e

runtimeEnv=$(uname)

if [ "$runtimeEnv" != "Linux" ] || [ ! -f /.dockerenv ]; then
    echo "Do not use this script in non-dockerized environments."
    echo "Detected non-Linux runtime $runtimeEnv, or /.dockerenv is not present."
    echo "Use 'node bin/api' or 'npm start'.'"
    exit 1
fi

if [ ! -z "$GIT_REPO" ]; then

    tmpDir=$(mktemp -d)

    echo "Cloning configuration repository from $GIT_REPO into $tmpDir..."
    pushd $tmpDir

    if [ -z "$GIT_BRANCH" ]; t  hen
        echo "Checking out branch 'master'..."
        if [ ! -z "$GIT_CREDENTIALS" ]; then
            git clone https://${GIT_CREDENTIALS}@${GIT_REPO} --depth 1 .
        else
            echo "Assuming public repository, GIT_CREDENTIALS is empty"
            git clone https://${GIT_REPO} --depth 1 .
        fi
    else
        echo "Checking out branch '$GIT_BRANCH'..."
        if [ ! -z "$GIT_CREDENTIALS" ]; then
            git clone https://${GIT_CREDENTIALS}@${GIT_REPO} --depth 1 --branch ${GIT_BRANCH} .
        else
            echo "Assuming public repository, GIT_CREDENTIALS is empty"
            git clone https://${GIT_REPO} --depth 1 --branch ${GIT_BRANCH} .
        fi
    fi

    if [ ! -d "$tmpDir/static" ]; then
        echo "===================================================================================="
        echo "ERROR: Could not find directory 'static' in $tmpDir, wrong repository?"
        echo "===================================================================================="
        exit 1
    fi

    echo Adding metadata to static directory...
    git log -1 > static/last_commit
    date -u "+%Y-%m-%d %H:%M:%S" > static/build_date

    echo "Cleaning up old configuration (if applicable)"
    rm -rf /var/portal-api/static
    echo "Copying configuration to /var/portal-api/static"
    cp -R static /var/portal-api
    echo "Done."

    popd

    echo "Cleanining up temp dir."
    rm -rf $tmpDir

else
    echo "Assuming /var/portal-api/static is prepopulated, not cloning configuration repo."
fi

echo "Calculating config hash..."

tempMd5Hash=$(find . -type f -exec md5sum {} \; | sort -k 2 | md5sum)
printf ${tempMd5Hash:0:32} > /var/portal-api/static/confighash

echo "Starting API..."

npm start
