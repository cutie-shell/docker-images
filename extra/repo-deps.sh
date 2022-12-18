#!/bin/bash
#
# Quick and dirty dependencies
#

if [ "${CIRCLECI}" == "true" ]; then
	# CircleCI

	BRANCH="${CIRCLE_BRANCH}"
	COMMIT="${CIRCLE_SHA1}"
	PROJECT_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
	if [ -n "${CIRCLE_TAG}" ]; then
		TAG="${CIRCLE_TAG}"
	fi
else
	# Sorry
	echo "This script runs only on CircleCI!"
	exit 1
fi

# Determine target.
echo "Determining target"
if [ -n "${TAG}" ]; then
	# Tag, should go to production
	TARGET="production"
elif [[ ${BRANCH} = feature/* ]]; then
	# Feature branch
	_project=${PROJECT_SLUG//\//-}
	_project=${_project//_/-}
	_branch=${BRANCH/feature\//}
	_branch=${_branch//./-}
	_branch=${_branch//_/-}
	_branch=${_branch//\//-}
	TARGET=$(echo ${_project}-${_branch} | tr '[:upper:]' '[:lower:]')
else
	# Staging
	TARGET="staging"
fi

if [[ "${TARGET}" = "production" ]]; then
	cp /etc/cutie-build/cutie-production.list /etc/apt/sources.list.d/
else
	cp /etc/cutie-build/cutie-staging.list /etc/apt/sources.list.d/
fi

apt update
apt dist-upgrade
