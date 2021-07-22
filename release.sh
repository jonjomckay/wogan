#!/usr/bin/env sh

set -e

if [ -z "$1" ]; then
  echo "No version name was supplied"
  exit 1
fi

if git diff --quiet; then
  echo "No unstashed changes, so continuing"
else
  echo "You have unstashed or uncommitted changes. Please commit changes before running this!"
  exit 1
fi

VERSION_NAME=$1
VERSION_NUMBER=$(date +%Y%m%d)

FULL_VERSION="$VERSION_NAME"+"$VERSION_NUMBER"

# Set the new version in pubspec.yaml
sed -i "s/version: .*/version: $FULL_VERSION/g" pubspec.yaml

# Rename the draft changelog with the new version number
if [ -e fastlane/metadata/android/en-US/changelogs/next.txt ]; then
  mv fastlane/metadata/android/en-US/changelogs/next.txt fastlane/metadata/android/en-US/changelogs/"$VERSION_NUMBER".txt
fi

# Create a new draft changelog for the next release
touch fastlane/metadata/android/en-US/changelogs/next.txt

# Commit the changes
git add pubspec.yaml fastlane/metadata/android/en-US/changelogs/next.txt fastlane/metadata/android/en-US/changelogs/"$VERSION_NUMBER".txt
git commit -m "Tagging v$VERSION_NAME"
git tag v"$VERSION_NAME"
git push
git push --tags
