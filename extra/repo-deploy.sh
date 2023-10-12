#!/bin/bash
#
# Quick and dirty deployer
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

echo -e "${GPG_PACKAGE_SIGNING_KEY}" | gpg --import

echo "Uploading data"
deb-s3 upload $(\
	find /tmp/buildd-results/ \
		-maxdepth 1 \
		-regextype posix-egrep \
		-regex "/tmp/buildd-results/.*\.(u?deb)$" \
		-print)\
	--arch="$(dpkg --print-architecture)" \
	--no-fail-if-exists \
	--bucket=deb.cutie-shell.org \
	--prefix=${TARGET} \
	--codename="${CODENAME}" \
	--lock \
	--no-preserve-versions \
	--access-key-id=${AWS_ACCESS_KEY_ID} \
	--secret-access-key=${AWS_SECRET_ACCESS_KEY} \
	--s3-region=${AWS_DEFAULT_REGION} \
	--sign=8BA0C00869CDCD4D

