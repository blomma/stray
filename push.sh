#!/bin/sh

#
# push.sh
#
# What does this do?
# ==================
# - Bumps build numbers in your project using agvtool
# - Builds your app and packages it for testing/ad-hoc distribution
# - Commits build number changes to git
# - Tags successful builds in git
# - Uploads builds to testflight with notes based on commits since the last build
# - If your branch is remote-tracking, it will ensure all changes are pushed first,
#   and will push the tagging on a successful build.
#
# Requirements
# ============
# - your target is an iOS App
# - you have a valid code signing identity & mobileprovision file
# - you use git for your version control
# - you use agvtool for versioning your builds, it's easy to enable:
#    1. In your project build settings:
#       a. set "Versioning System" to "Apple Generic"
#       b. set "Current Project Version" to "1"
#    2. In your applications info.plist file, set "Bundle version" (NOTE: not "Bundle versions string, short") to "1"
# - you use testflight for publishing builds
# - Xcode is configured to place build products in locations specified by targets
#     (Under Preferences > Locations, in the section labelled "Build Location")
#
# Known issues
# ============
# When agvtool bumps the version numbers, for some reason the platform build selector
# in Xcode gets messed up.  It returns to normal if you close and re-open the project.
#

#
# BUILD SETTINGS
#
# Name of target
TARGET_NAME=Stray
BUILD_TARGET_NAME=Drift

# Target SDK
# If you need to specify a specific version you can change this
TARGET_SDK=iphoneos

# Build configuration to use
CONFIGURATION="Ad Hoc"

# Build workspace
WORKSPACE="Drift.xcworkspace"

# Build workspace schema
WORKSPACE_SCHEMA="Drift"

# Name of .mobileprovision file in the PROFILES_PATH directory (see below)
PROVISIONING=""

# Code signing identity, as it appears in Xcode's Organizer (e.g. "iPhone Developer: John Doe")
SIGNER="iPhone Distribution: Mikael Hultgren"

#
# TESTFLIGHT SETTINGS
#
# Your testflightapp.com API token (see https://testflightapp.com/account/)
TESTFLIGHT_API_TOKEN=
# Your testflightapp.com Team Token (see https://testflightapp.com/dashboard/team/edit/)
TESTFLIGHT_TEAM_TOKEN=
# List of testflightapp.com distribution lists to send the build to (and send notifications)
TESTFLIGHT_GROUPS=""

#
# GIT SETTINGS
#
# The prefix for build tags.  Change this if "build-n" will collide with other tags you create in git.
GIT_BRANCH=$(git name-rev --name-only HEAD)
GIT_REMOTE=$(git branch -r | grep -v \/HEAD | grep \/${GIT_BRANCH} | sed -E 's/ +([^\/]+).*/\1/g')

#
# PATH SETTINGS
#
# Override these if you're experiencing problems with the script locating your build artifacts or
# provisioning profiles
PROFILES_PATH="${HOME}/Library/MobileDevice/Provisioning Profiles/"
BUILD_PATH=$(xcodebuild -workspace "${WORKSPACE}" -scheme "${WORKSPACE_SCHEMA}" -sdk "${TARGET_SDK}" -configuration "${CONFIGURATION}" -showBuildSettings | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

APP_PATH="${BUILD_PATH}/${TARGET_NAME}.app"
APP_DSYM_PATH="${BUILD_PATH}/${TARGET_NAME}.app.dSYM"

# Where the ipa file will be written prior to being uploaded to testflightapp.com
IPA_PATH="/tmp/${TARGET_NAME}.ipa"
APP_DSYM_ZIP_PATH="/tmp/${TARGET_NAME}.app.dSYM.zip"

#
# SCRIPT STARTS
#
echo "Pre-build checks..."

# Make sure there are no uncommitted changes
STATUS=x$(git status --porcelain)
if [ "${STATUS}" != "x" ]
then
	echo "!!! Git checkout is not clean.  Not building."
	exit 1
fi

BUILD_NUMBER=$(agvtool what-version -terse)

# Check if the tag actually exists in git
if [ "x" != "x"${GIT_REMOTE} ]
then
	git fetch
fi
OLD_BUILD_TAG=$(git tag -l "${BUILD_NUMBER}")

# Bump up version number, but don't commit yet
agvtool bump -all
BUILD_NUMBER=$(agvtool what-version -terse)
VERSION_STRING="(${BUILD_NUMBER})"
BUILD_TAG="${BUILD_NUMBER}"

# Build target
echo
echo Building target: "${BUILD_TARGET_NAME}" "${VERSION_STRING}"...
echo

xcodebuild -workspace "${WORKSPACE}" \
	-scheme "${WORKSPACE_SCHEMA}" \
	-sdk "${TARGET_SDK}" \
	-configuration "${CONFIGURATION}"

if [ $? -ne 0 ]
then
	echo
	echo "!!! xcodebuild failed"
	git reset --hard HEAD
	exit 1
fi

# Package .ipa
echo
echo Packaging target...
echo

xcrun -sdk "${TARGET_SDK}" \
	PackageApplication \
	-v "${APP_PATH}" \
	-o "${IPA_PATH}" \
	--sign "${SIGNER}" \
	--embed "${PROFILES_PATH}${PROVISIONING}"

if [ $? -ne 0 ]
then
	echo
	echo "!!! xcrun failed to package application"
	git reset --hard HEAD
	exit 1
fi

# Get build notes from commit messages, from the last build tag (if present, otherwise all)
if [ -n "${OLD_BUILD_TAG}" ]
then
	BUILD_LOG=$(git log "${OLD_BUILD_TAG}".. --pretty="format:  - %s" | grep -v 'Build')
	BUILD_NOTES="${BUILD_LOG}"
else
	BUILD_LOG=$(git log --pretty="format:  - %s" | grep -v 'Build')
	BUILD_NOTES="${BUILD_LOG}"
fi

# Testflight!
echo
echo Submitting to testflightapp...
echo

zip -r "${APP_DSYM_ZIP_PATH}" "${APP_DSYM_PATH}"

if [ $? -ne 0 ]
then
	echo
	echo "!!! zip failed to compress dSYM file"
	git reset --hard HEAD
	exit 1
fi

echo curl https://testflightapp.com/api/builds.json \
	-F file=@"${IPA_PATH}" \
	-F dsym=@"${APP_DSYM_ZIP_PATH}" \
	-F api_token="${TESTFLIGHT_API_TOKEN}" \
	-F team_token="${TESTFLIGHT_TEAM_TOKEN}" \
	-F notes="${BUILD_NOTES}" \
	-F notify=True \
	-F distribution_lists="${TESTFLIGHT_GROUPS}"

curl https://testflightapp.com/api/builds.json \
	-F file=@"${IPA_PATH}" \
	-F dsym=@"${APP_DSYM_ZIP_PATH}" \
	-F api_token="${TESTFLIGHT_API_TOKEN}" \
	-F team_token="${TESTFLIGHT_TEAM_TOKEN}" \
	-F notes="${BUILD_NOTES}" \
	-F notify=True \
	-F distribution_lists="${TESTFLIGHT_GROUPS}"

if [ $? -ne 0 ]
then
	echo
	echo "!!! Error uploading to testflightapp"
	git reset --hard HEAD
	exit 1
fi

# Commit version bump and tag build
echo
echo Committing version bump and tagging build...
echo

git commit -am "Build ${VERSION_STRING}"
git tag -a "${BUILD_TAG}" HEAD -m "Tagging build ${VERSION_STRING}"

if [ "x" != "x"${GIT_REMOTE} ]
then
	git push ${GIT_REMOTE} ${GIT_BRANCH}
	git push ${GIT_REMOTE} ${GIT_BRANCH} --tags
fi
