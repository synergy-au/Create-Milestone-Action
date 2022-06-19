# Create Milestone Action

This action is dedicated to help managing [GitHub Milestones](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones). It will check if there are any open and future dated milestones that exist within a lower and upper bound from the current date and if there are none it will automatically create a new milestone and assign it to the pull request. Alternatively, if a milestone is found within the lower and upper bounds then it will simply assign the existing one to the pull request instead.

This action is triggered when a draft pull request is marked as ready for review.

## Example Github Action Workflow File

```
name: Create Milestone

on:
  pull_request:
    types: [ready_for_review]

jobs:
  create-milestone:
    name: Create Milestone
    runs-on: ubuntu-latest
    steps:
    - name: Run Create Milestone Action
      id: run-create-milestone-action
      uses: synergy-au/Create-Milestone-Action@v1.0
      with:
        secrets-token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

**secrets-token**\
The Secrets Github Token used for authenticating Github API calls.
- required: true

## Outputs

None
