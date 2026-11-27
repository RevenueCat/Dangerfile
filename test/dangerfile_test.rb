# Runs the Dangerfile's helpers against a real git repository, with Danger's DSL stubbed.
# Usage: ruby test/dangerfile_test.rb
require "minitest/autorun"
require "shellwords"
require "tmpdir"

DANGERFILE = File.read(File.expand_path("../Dangerfile", __dir__)).split("#### ENTRY POINT").first

class DangerHarness
  Diff = Struct.new(:patch)
  Git = Struct.new(:modified_files, :added_files, :patches) do
    def diff_for_file(file)
      patches[file] && Diff.new(patches[file])
    end
  end
  GitHub = Struct.new(:pr_labels)

  attr_reader :git, :github, :failures, :warnings

  def initialize(added:, modified: [], patches: {}, labels: [])
    @git = Git.new(modified, added, patches)
    @github = GitHub.new(labels)
    @failures = []
    @warnings = []
    instance_eval(DANGERFILE)
  end

  def fail(text) = @failures << text
  def warn(text) = @warnings << text
  def message(_text) = nil
end

class DangerfileTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    git "init -q -b main"
    git "config user.email test@example.com"
    git "config user.name test"
    Dir.mkdir(File.join(@repo, "sdk"))
    File.write(File.join(@repo, "sdk", "README.md"), "x")
    git "add -A"
    git "commit -qm base"
  end

  def teardown
    FileUtils.rm_rf(@repo)
  end

  def git(command)
    system("git -C #{Shellwords.escape(@repo)} #{command}", exception: true)
  end

  def write(path, content)
    full = File.join(@repo, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  def danger_in(dir, **kwargs)
    Dir.chdir(File.join(@repo, dir)) { DangerHarness.new(**kwargs).tap { |danger| yield danger } }
  end

  def test_size_check_fails_a_big_file_from_the_repository_root
    write("big.bin", "x" * 300_000)
    danger_in(".", added: ["big.bin"]) do |danger|
      danger.check_pr_size_increase
      assert_equal 1, danger.failures.size
    end
  end

  def test_size_check_fails_a_big_file_from_an_sdk_folder
    write("sdk/big.bin", "x" * 300_000)
    danger_in("sdk", added: ["sdk/big.bin"]) do |danger|
      danger.check_pr_size_increase
      assert_equal 1, danger.failures.size
    end
  end

  def test_generated_guard_fails_an_edit_from_the_repository_root
    danger_in(".", added: [], modified: ["lib/generated/codes.dart"]) do |danger|
      danger.fail_on_generated_edits(["lib/generated/"])
      assert_equal 1, danger.failures.size
    end
  end

  def test_generated_guard_fails_an_edit_from_an_sdk_folder
    danger_in("sdk", added: [], modified: ["sdk/lib/generated/codes.dart"]) do |danger|
      danger.fail_on_generated_edits(["lib/generated/"])
      assert_equal 1, danger.failures.size
    end
  end

  def test_generated_guard_ignores_another_folder_with_the_same_layout
    danger_in("sdk", added: [], modified: ["other/lib/generated/codes.dart"]) do |danger|
      danger.fail_on_generated_edits(["lib/generated/"])
      assert_empty danger.failures
    end
  end

  def test_generated_guard_respects_the_label
    danger_in("sdk", added: [], modified: ["sdk/lib/generated/codes.dart"], labels: ["pr:auto_codegen"]) do |danger|
      danger.fail_on_generated_edits(["lib/generated/"])
      assert_empty danger.failures
    end
  end

  def test_github_api_check_fails_a_fastlane_action_from_the_repository_root
    file = "fastlane/actions/x.rb"
    danger_in(".", added: [file], patches: { file => "+  github_api(path: 'x')\n" }) do |danger|
      danger.fail_on_direct_github_api_calls
      assert_equal 1, danger.failures.size
    end
  end

  def test_github_api_check_fails_a_fastlane_action_from_an_sdk_folder
    file = "sdk/fastlane/actions/x.rb"
    danger_in("sdk", added: [file], patches: { file => "+  github_api(path: 'x')\n" }) do |danger|
      danger.fail_on_direct_github_api_calls
      assert_equal 1, danger.failures.size
    end
  end
end
