#!/bin/bash -e

version=jobcom-2.0.9164
timestamp=$(date +%Y%m%d)
git_sha=$(git rev-parse --short HEAD)
git_tag="${version}-${timestamp}-${git_sha}"
echo "New git tag: $git_tag"

git tag $git_tag
git push origin $git_tag
