# GitHub Actions sometimes cannot push directly to protected branches when a
# branch protection rule requires a pull request. This means that we cannot
# use one single `gem bump` command to do all the work. We have to take a
# more complex route.

bump_with_pull_request() {
  echo "::group::🔀 Create a new branch for the version bump"
  local branch="bump/version-${BUMP_LEVEL}-$(date +%s)"
  git checkout -b "${branch}"
  echo "::endgroup::"

  echo "::group::🌟 Bump the version"
  gem bump --version ${BUMP_LEVEL} --commit
  local new_version=$(get_version_from_gemspec)
  echo "new_version=${new_version}" >> $GITHUB_OUTPUT
  echo "::notice::Bumped to version ${new_version}."

  if [ -z "$new_version" ]; then
    echo "::error::Could not extract version from commit message"
    git log -1 --pretty=%B
    exit 1
  fi
  echo "::endgroup::"

  if [ -f "Gemfile.lock" ]; then
    echo "::group::⭐ Update Gemfile.lock"
    bundle install
    git add Gemfile.lock
    git commit --amend --no-edit
    echo "::endgroup::"
  fi

  echo "::group::⏫ Push the bump branch:"
  git push origin "${branch}"
  echo "::endgroup::"

  echo "::group::⤵️ Create a pull request:"
  pr_title="Bump version to ${new_version}"
  pr_body="Bump version to ${new_version} following merge of PR #${PR_NUMBER}."
  pull_request=$(github_create_pull_request "${branch}" "${pr_title}" "${pr_body}")
  echo "pull_request_number=${pull_request}" >> $GITHUB_OUTPUT
  echo "::notice::Version bump PR created: #${pull_request}."
  echo "::endgroup::"

  echo "::group::↩️ Merge the pull request:"
  github_merge_pull_request "${pull_request}"
  echo "::endgroup::"

  echo "::group::📦 Create a release v${new_version}:"
  github_create_release "v${new_version}" "Release v${new_version}"
  echo "::notice::v${new_version} released."
  echo "::endgroup::"
}

get_version_from_gemspec() {
  gemspec_file=$(ls *.gemspec | head -1)
  version=$(ruby -e "puts Gem::Specification.load(\"${gemspec_file}\").version")
  echo "$version"
}
