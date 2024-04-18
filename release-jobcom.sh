#!/bin/bash -e

version=jobcom-2.0.9258-transcriber-libs
timestamp=$(date +%Y%m%d%h)
git_tag="${version}-${timestamp}"
echo "New git tag: $git_tag"

git tag $git_tag
git push origin $git_tag
