#!/bin/sh
set -e

source /bump-in-pull-request.sh
source /github.sh
source /labels.sh

cd "${GITHUB_WORKSPACE}" || exit 1

# Setup these env variables.
# - LABELS
# - PR_NUMBER
# - PR_TITLE
setup_from_push_event() {
  echo "::group::📊 Analyzing merged PR"
  local pull_request="$(list_pulls | jq ".[] | select(.merge_commit_sha==\"${GITHUB_SHA}\")")"
  LABELS=$(echo "${pull_request}" | jq '.labels | .[].name')
  PR_NUMBER=$(echo "${pull_request}" | jq -r .number)
  PR_TITLE=$(echo "${pull_request}" | jq -r .title)
  BUMP_LEVEL=$(get_bump_level)
  echo "::endgroup::"
}

list_pulls() {
  local pulls_endpoint="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls?state=closed&sort=updated&direction=desc"
  if [ -n "${INPUT_GITHUB_TOKEN}" ]; then
    github_list_pull_requests "${pulls_endpoint}"
  else
    echo "::warning::INPUT_GITHUB_TOKEN is not available. Subsequent GitHub API call may fail due to API limit." >&2
    curl -s "${pulls_endpoint}"
  fi
}

get_bump_level() {
  if echo "${LABELS}" | grep -q "bump:major" ; then
    echo "major"
  elif echo "${LABELS}" | grep -q "bump:minor" ; then
    echo "minor"
  elif echo "${LABELS}" | grep -q "bump:patch" ; then
    echo "patch"
  else
    echo ""
  fi
}

setup_git() {
  git config --global --add safe.directory "$GITHUB_WORKSPACE"
  git config user.name "${GITHUB_ACTOR}"
  git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
}

setup_gem_credentials() {
  mkdir -p ~/.gem
  touch ~/.gem/credentials
  chmod 600 ~/.gem/credentials
  echo ":github: Bearer ${INPUT_GITHUB_TOKEN}" > ~/.gem/credentials
}

setup_env() {
  export GEM_RELEASE_RELEASE_TOKEN="${INPUT_GITHUB_TOKEN}"
  export GEM_RELEASE_RELEASE_HOST=https://rubygems.pkg.github.com/${GITHUB_REPOSITORY_OWNER}
  export GEM_RELEASE_RELEASE_KEY=github
  export GEM_RELEASE_RELEASE_DESCR="${PR_TITLE}"
  export GEM_RELEASE_RELEASE_GITHUB=true
}

create_labels
setup_git
setup_from_push_event

if [ -z "${BUMP_LEVEL}" ]; then
  echo "::notice::No bump label found on pull request. Do nothing."
  echo "skipped=true" >> $GITHUB_OUTPUT
  exit
fi

echo "level=${BUMP_LEVEL}" >> $GITHUB_OUTPUT
echo "skipped=false" >> $GITHUB_OUTPUT
echo "::notice::Bump ${BUMP_LEVEL} version"

setup_gem_credentials
setup_env

if [ "${INPUT_STRATEGY}" = "gem-release" ]; then
  echo "::group::🌟 Bump the version"
  gem bump --commit --version ${BUMP_LEVEL} --push --tag --release
  echo "::endgroup::"
elif [ "${INPUT_STRATEGY}" = "pull-request" ]; then
  bump_with_pull_request
elif [ "${INPUT_STRATEGY}" = "dry-run" ]; then
  echo "::warning::Dry run mode - skipping actual version bump"
  exit
else
  echo "::error::Unknown strategy: ${INPUT_STRATEGY}"
  exit 1
fi
