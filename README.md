![alt text](bump.png)

# bump gem version

A GitHub action to automatically bump the versions of your Ruby Gems after merging a pull request.

It will create a new version of your gem and a git tag with the latest version.


### inputs

**`GITHUB_TOKEN`** *Required*

The GitHub token to use for authentication. Usually set to `${{ secrets.GITHUB_TOKEN }}`.

**`STRATEGY`**

`gem-release`/`pull-request`/`"dry-run"`, default: 'gem-release'

By default the version will be bumped on the main branch. Branch protection rules might require a more complex strategy. Dry run is useful for testing.


### outputs

**`skipped`**

`true`/`false`
A boolean that indicates if the gem version was bumped.

**`level`**

`major`/`minor`/`patch`
The bump level that was used.


## Permissions Required

This action requires the following permissions for the gem-release strategy:

```yaml
permissions:
  # To commit changes (to the file containting the version):
  contents: write
  # For creating labels:
  issues: write
  # To analyze the merged PR that triggered the action:
  pull-requests: read
```

... and for the pull-request strategy:

```yaml
permissions:
  # To commit changes (to the file containting the version):
  contents: write
  # For creating labels:
  issues: write
  # To analyze the merged PR that triggered the action and to create and merge a pull request:
  pull-requests: write
```
