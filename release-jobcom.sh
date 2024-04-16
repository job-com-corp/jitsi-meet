#!/bin/bash -e

echo "Run $0 -stable for stable release (without timestamp)"
arg=$1

version_internal=3.12.0
version_jitsi=2.0.9258

# Check release-jitsi-meet-assets.yml workflow for version/tag regex
version=jobcom-${version_jitsi}-${version_internal}

timestamp=$(date +%Y%m%d%H%M)
if [[ $arg == '-stable' ]]; then
  git_tag="${version}"
  echo "STABLE release!"
else
  git_tag="${version}-${timestamp}"
fi
echo -e "Publishing new git release:\n\n$git_tag\n"

read -p "Are you sure? [y/N]: " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git tag $git_tag
  git push origin $git_tag
else
  echo -e "\nNope"
fi
