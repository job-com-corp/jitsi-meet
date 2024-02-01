#!/bin/bash -e

version=2.0.9164
git_sha=$(git rev-parse --short HEAD)
git_tag="jobcom-${version}.${git_sha}"
echo "New git tag: $git_tag"

git tag $git_tag
git push origin $git_tag
