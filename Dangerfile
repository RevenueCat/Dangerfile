require 'shellwords'

#### GITHUB LABEL CHECK
def fail_if_no_supported_label_found
  supported_types = ["feat", "fix", "RevenueCatUI", "next_release", "dependencies", "phc_dependencies", "other"]
  supported_types += supported_types.map { |type| "pr:#{type}" }

  supported_labels_in_pr = supported_types & github.pr_labels
  no_supported_label = supported_labels_in_pr.empty?
  only_revenuecatui = supported_labels_in_pr == ["pr:RevenueCatUI"]

  if no_supported_label || only_revenuecatui
    fail_message = if only_revenuecatui
                     "The PR is tagged with pr:RevenueCatUI only. Please add another appropriate label."
                   else
                     "Label the PR using one of the change type labels. If you are not sure which label to use, choose *pr:other*."
                   end
    fail(fail_message)
    markdown <<-MARKDOWN
  | Label | Description |
  |-------|-------------|
  | *pr:feat* | A new feature. Use along with pr:breaking to force a major release. |
  | *pr:fix* | A bug fix. Use along with pr:force_minor to force a minor release. |
  | *pr:other* | Other changes. Catch-all for anything that doesn't fit the above categories. Releases that only contain this label will not be released. Use along with pr:force_patch, or pr:force_minor to force a patch or minor release. |
  | *pr:RevenueCatUI* | Use along any other tag to mark a PR that only contains RevenueCatUI changes |
  | *pr:next_release* | Preparing a new release |
  | *pr:dependencies* | Updating a dependency |
  | *pr:phc_dependencies* | Updating purchases-hybrid-common dependency |
    MARKDOWN
  end
end

#### REQUIRED LABEL MAPPINGS
# Map trigger labels to required labels that must be present.
# Supports String or Array as a value:
# "trigger" => "required"        # one required label
# "trigger" => ["r1","r2"]       # multiple required labels
REQUIRED_LABEL_MAP = {
  "feat:Customer Center" => "pr:RevenueCatUI",
  # Add more mappings here:
  # "feat:Payments" => ["pr:RevenueCatUI", "pr:next_release"]
}

def fail_if_required_labels_missing
  # Normalize possible "feat: Something" vs "feat:Something"
  normalized_labels = github.pr_labels.map { |l| l.gsub(": ", ":") }

  REQUIRED_LABEL_MAP.each do |trigger, required|
    required = Array(required) # allow string or array
    has_trigger = normalized_labels.include?(trigger.gsub(": ", ":"))
    next unless has_trigger

    missing_required = required.reject { |r| normalized_labels.include?(r) }
    next if missing_required.empty?

    fail(%(PR has label "#{trigger}" but is missing required label(s): #{missing_required.map { |l| %("#{l}") }.join(", ")}.))
  end
end

#### PR SIZE INCREASE CHECK

# Thresholds
WARN_SIZE_INCREASE = 102_400  # 100kb
FAIL_SIZE_INCREASE = 256_000  # 250kb

# Bypass
BYPASS_LABEL = "danger-bypass-size-limit"

def check_pr_size_increase
  added_and_modified_files = git.added_files + git.modified_files
  total_size_increase = calculate_total_size_increase(added_and_modified_files)

  bypass_size_check = github.pr_labels.any? { |s| s == BYPASS_LABEL }

  if bypass_size_check
    warn("Size check is being bypassed due to the presence of the label \"#{BYPASS_LABEL}\"")
    if total_size_increase > WARN_SIZE_INCREASE
      warn("Size increase: #{'%.2f' % toKB(total_size_increase)} KB")
    end
    return
  end

  if total_size_increase > FAIL_SIZE_INCREASE
    fail("This PR increases the size of the repo by more than #{'%.2f' % toKB(FAIL_SIZE_INCREASE)} KB (increased by #{'%.2f' % toKB(total_size_increase)} KB).")
    message("You can bypass the size check failure by adding the label \"#{BYPASS_LABEL}\". Please exercise caution.")
  elsif total_size_increase > WARN_SIZE_INCREASE
    warn("This PR increases the size of the repo by more than #{'%.2f' % toKB(WARN_SIZE_INCREASE)} KB (increased by #{'%.2f' % toKB(total_size_increase)} KB).")
  end
end

def toKB(bytes)
  bytes / 1024.0
end

def calculate_total_size_increase(files)
  total_increase = 0
  files.each do |file|
    file_size_in_branch = size_of_file(file)
    file_size_in_main = size_of_file_in_main(file)
    size_increase = file_size_in_branch - file_size_in_main
    total_increase += size_increase if size_increase > 0
  end
  total_increase
end

# File size in the current branch
def size_of_file(file_path)
  if File.exist?(file_path)
    File.size(file_path)
  else
    0
  end
end

# File size in main branch
def size_of_file_in_main(file)
  escaped_file = Shellwords.shellescape(file)
  if system("git cat-file -e main:#{escaped_file} 2> /dev/null")
    `git show main:#{escaped_file} 2>/dev/null | wc -c`.to_i
  else
    0
  end
end

#### ENTRY POINT

# Fail when required label mappings are missing
fail_if_required_labels_missing

# Fail when GitHub PR label is missing
fail_if_no_supported_label_found

# Fail/warn when PR size increase exceeds threshold
check_pr_size_increase