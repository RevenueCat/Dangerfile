#### HELPER METHODS
def fail_if_no_supported_label_found
  supported_types = ["breaking", "build", "ci", "docs", "feat", "fix", "perf", "refactor", "RevenueCatUI", "style", "test", "next_release", "dependencies", "phc_dependencies"]

  supported_labels_in_pr = supported_types & github.pr_labels
  no_supported_label = supported_labels_in_pr.empty?
  if no_supported_label
    fail("Label the PR using one of the change type labels")
    markdown <<-MARKDOWN
  | Label | Description |
  |-------|-------------|
  | *breaking* | Changes that are breaking |
  | *build* | Changes that affect the build system |
  | *ci* | Changes to our CI configuration files and scripts |
  | *docs* | Documentation only changes |
  | *feat* | A new feature |
  | *fix* | A bug fix |
  | *perf* | A code change that improves performance |
  | *RevenueCatUI* | A change to the RevenueCatUI library |
  | *refactor* | A code change that neither fixes a bug nor adds a feature |
  | *style* | Changes that don't affect the meaning of the code (white-space, formatting, missing semi-colons, etc |
  | *test* | Adding missing tests or correcting existing tests |
  | *next_release* | Preparing a new release |
  | *dependencies* | Updating a dependency |
  | *phc_dependencies* | Updating purchases-hybrid-common dependency |
  MARKDOWN
  end
end

# Fail when GitHub PR label is missing
fail_if_no_supported_label_found
