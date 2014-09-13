branch=${1:-'master'}
buildNumber=$(expr $(git rev-list $branch --count) + $(git rev-list $branch..HEAD --count))
echo "Updating build number to $buildNumber using branch '$branch'."
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
