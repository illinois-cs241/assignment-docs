#!/bin/bash

git clone --recurse-submodules -j8 -b develop https://github.com/illinois-cs241/illinois-cs241.github.io.git ${CLONE_DIR}
cd ${CLONE_DIR}
git remote add token-origin "https://${GITHUB_TOKEN}@github.com/illinois-cs241/illinois-cs241.github.io.git" > /dev/null 2>&1
git checkout develop
cd _docs/
git pull origin master
export DOCS_SHA=$(git rev-parse --short HEAD)
cd ..
git add _docs
git commit -m "Updating docs to ${DOCS_SHA}"
git push --quiet token-origin develop