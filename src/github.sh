github_create_label() {
  local name=$1
  local color=$2
  local description=$3

  curl -s -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/labels" \
    -d "{\"name\":\"${name}\",\"color\":\"${color}\",\"description\":\"${description}\"}"
}

github_list_pull_requests() {
  local pulls_endpoint=$1

  curl -s \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${pulls_endpoint}"
}

github_create_pull_request() {
  local branch=$1
  local title=$2
  local body=$3

  local response=$(curl -s -X POST \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls" \
    -d "{
      \"title\": \"${title}\",
      \"body\": \"${body}\",
      \"head\": \"${branch}\",
      \"base\": \"${GITHUB_REF#refs/heads/}\"
    }")

  local pr_number=$(echo "$response" | jq -r '.number')

  if [ "$pr_number" = "null" ] || [ -z "$pr_number" ]; then
    echo "::error::Error creating PR: ${response}"
    exit 1
  fi

  echo "$pr_number"
}


# This function uses `gh` since the GitHub API has no easy way to mimic the --admin flag.
github_merge_pull_request() {
  local pr_number=$1

  gh pr merge ${pr_number} --admin --merge --delete-branch

  if [ $? -ne 0 ]; then
    echo "::error::Error merging PR #${pr_number}"
    exit 1
  fi
}

github_create_release() {
  local tag_name=$1
  local release_name=$2
  local release_body=$3

  # Need to get the latest commit SHA from main after merge
  git fetch origin "${GITHUB_REF#refs/heads/}"
  local latest_sha=$(git rev-parse "origin/${GITHUB_REF#refs/heads/}")

  local response=$(curl -s -X POST \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases" \
    -d "{
      \"tag_name\": \"${tag_name}\",
      \"target_commitish\": \"${latest_sha}\",
      \"name\": \"${release_name}\",
      \"body\": \"${release_body}\",
      \"draft\": false,
      \"prerelease\": false
    }")

  local release_id=$(echo "$response" | jq -r '.id')

  if [ "$release_id" = "null" ] || [ -z "$release_id" ]; then
    echo "::error::Error creating release: ${response}"
    exit 1
  fi
}
