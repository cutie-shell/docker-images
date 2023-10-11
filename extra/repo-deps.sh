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
	# Codename is the second part of the tag
	_split_tag=(${TAG//\// })
	CODENAME=${_split_tag[1]}
elif [[ ${BRANCH} = feature/* ]]; then
	# Feature branch
	_project=${PROJECT_SLUG//\//-}
	_project=${_project//_/-}
	_branch=${BRANCH/feature\//}
	_branch=${_branch//./-}
	_branch=${_branch//_/-}
	_branch=${_branch//\//-}
	TARGET=$(echo ${_project}-${_branch} | tr '[:upper:]' '[:lower:]')
	# Codename is the second part of the branch name
	_split_branch=(${BRANCH//\// })
	CODENAME=${_split_branch[1]}
else
	# Staging
	TARGET="staging"
	# Codename is the branch unless branch is 'droidian'
	if [ "${BRANCH}" = "droidian" ]; then
		CODENAME="trixie"
	else
		CODENAME="${BRANCH}"
	fi
fi

if [[ "${TARGET}" = "production" ]]; then
	sed "s/@CODENAME@/${CODENAME}/g" /etc/cutie-build/cutie-production.list > /etc/apt/sources.list.d/cutie-production.list
else
	sed "s/@CODENAME@/${CODENAME}/g" /etc/cutie-build/cutie-staging.list > /etc/apt/sources.list.d/cutie-staging.list
fi

apt update || apt update
apt dist-upgrade -y || apt dist-upgrade -y
