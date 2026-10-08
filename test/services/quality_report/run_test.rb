require "test_helper"

# Drives QualityReport::Run against a throwaway app whose bin/rails, bin/rubocop
# and bin/brakeman are stub scripts, so the real suite never runs inside itself.
class QualityReport::RunTest < ActiveSupport::TestCase
  TEST_RESULTS = { count: 3, assertions: 5, failures: 0, errors: 0, skips: 0, duration: 0.1,
                   by_type: { models: 3 }, slowest: [], problems: [] }.to_json
  COVERAGE = { total: { lines: { covered: 9, total: 10, percent: 90.0 } }, groups: {}, coverage: {} }.to_json

  setup do
    @root = Pathname(Dir.mktmpdir("quality-run"))
    write "app/models/widget.rb", "class Widget; end\n"
    stub_bin "rubocop", %(echo '{"summary":{"offense_count":0,"inspected_file_count":4},"files":[]}')
    stub_bin "brakeman", %(echo "Brakeman 7.1.1 is not the latest version 8.1.0" >&2; exit 5)
  end

  teardown { FileUtils.rm_rf(@root) }

  def write(path, content)
    @root.join(path).dirname.mkpath
    @root.join(path).write(content)
  end

  def stub_bin(name, script)
    write "bin/#{name}", "#!/bin/sh\n#{script}\n"
    @root.join("bin/#{name}").chmod(0o755)
  end

  # A bin/rails that "runs the suite": records how it was called, writes results.
  def stub_passing_suite
    stub_bin "rails", <<~SH
      echo "$COVERAGE $1" > called.txt
      mkdir -p "$(dirname "$QUALITY_TEST_RESULTS")" coverage
      printf '%s' '#{TEST_RESULTS}' > "$QUALITY_TEST_RESULTS"
      printf '%s' '#{COVERAGE}' > coverage/coverage.json
    SH
  end

  def git(*args)
    system("git", "-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false",
           *args, chdir: @root.to_s, out: File::NULL, err: File::NULL)
  end

  test "runs every test with coverage and writes the report" do
    stub_passing_suite

    report = QualityReport::Run.new(root: @root).call

    assert_equal "1 test:all", @root.join("called.txt").read.strip, "coverage on, system tests included"
    assert_equal report, JSON.parse(@root.join(QualityReport::PATH).read)
    assert_equal 3, report["tests"]["count"]
    assert_equal 90.0, report["coverage"]["line"]
    assert_equal 0, report["lint"]["offenses"]
    assert_equal QualityReport.fingerprints(@root), report["source"]["files"]
  end

  test "a tool that refuses to run fails the report with its message" do
    stub_passing_suite

    report = QualityReport::Run.new(root: @root).call

    assert_equal "failing", report["status"]
    assert_equal "Brakeman 7.1.1 is not the latest version 8.1.0", report["security"]["error"]
  end

  test "results left over from an earlier run never stand in for a crashed suite" do
    write QualityReport::Run::TEST_RESULTS, TEST_RESULTS
    write "coverage/coverage.json", COVERAGE
    stub_bin "rails", "exit 1"

    report = QualityReport::Run.new(root: @root).call

    assert_nil report["tests"]
    assert_nil report["coverage"]
    assert_equal "failing", report["status"]
  end

  test "reads committed reports from git, newest first, for history and the trend" do
    git "init", "-q"
    write QualityReport::PATH, { status: "passing", coverage: { line: 95.0 } }.to_json
    git "add", "."
    git "commit", "-q", "-m", "first"
    write QualityReport::PATH, { status: "passing", coverage: { line: 96.0 } }.to_json
    git "commit", "-q", "-am", "second"
    stub_passing_suite

    report = QualityReport::Run.new(root: @root).call

    assert_equal [ 96.0, 95.0 ], report["history"].map { |entry| entry["line"] }
    trend = report["checks"].find { |check| check["key"] == "trend" }
    assert_equal "fail", trend["status"], "90% is more than half a point below the last committed 96%"
  end

  test "without git there is simply no history" do
    assert_equal [], QualityReport::Run.new(root: @root).committed_reports
  end
end
