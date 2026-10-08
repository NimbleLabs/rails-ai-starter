require "test_helper"

class QualityReport::BuilderTest < ActiveSupport::TestCase
  TESTS = {
    "count" => 120, "assertions" => 400, "failures" => 0, "errors" => 0, "skips" => 0, "duration" => 12.3,
    "by_type" => { "models" => 80, "system" => 40 }, "slowest" => [], "problems" => []
  }.freeze

  # The shape of SimpleCov's coverage.json (schema 1.3), trimmed to what's read.
  def simplecov(line: 85.04, branch: 70.0)
    {
      "total" => {
        "lines" => { "covered" => 850, "missed" => 150, "total" => 1000, "percent" => line },
        "branches" => { "covered" => 70, "missed" => 30, "total" => 100, "percent" => branch }
      },
      "groups" => {
        "Models" => { "lines" => { "percent" => 95.55 }, "files" => [ "app/models/user.rb" ] },
        "Ungrouped" => { "lines" => { "percent" => 50.0 }, "files" => [ "app/services/thing.rb" ] }
      },
      "coverage" => {
        "app/services/thing.rb" => { "lines_covered_percent" => 50.0, "branches_covered_percent" => 25.0,
                                     "missed_lines" => 10, "total_lines" => 20 },
        "app/models/user.rb" => { "lines_covered_percent" => 95.55, "branches_covered_percent" => 100.0,
                                  "missed_lines" => 1, "total_lines" => 22 }
      }
    }
  end

  RUBOCOP_CLEAN = { "summary" => { "offense_count" => 0, "inspected_file_count" => 160 }, "files" => [] }.freeze
  BRAKEMAN_CLEAN = { "scan_info" => { "brakeman_version" => "8.1.0" }, "warnings" => [] }.freeze

  def build(tests: TESTS, coverage: simplecov, lint: RUBOCOP_CLEAN, security: BRAKEMAN_CLEAN, previous: [])
    QualityReport::Builder.new(tests: tests, coverage: coverage, lint: lint, security: security, previous: previous,
                               fingerprints: { "app/models/user.rb" => "abc123abc123" },
                               generated_at: Time.utc(2026, 10, 8, 12)).build
  end

  def check(report, key)
    report["checks"].find { |check| check["key"] == key }
  end

  def committed(line:, commit: "abc1234", tests: 100)
    { "commit" => commit, "committed_at" => "2026-10-01T10:00:00-05:00",
      "report" => { "status" => "passing", "tests" => { "count" => tests, "failures" => 0, "errors" => 1 },
                    "coverage" => { "line" => line, "branch" => 60.0 } } }
  end

  test "a clean run passes every check" do
    report = build

    assert_equal "passing", report["status"]
    assert_equal %w[tests skips coverage trend lint security], report["checks"].map { |check| check["key"] }
    assert report["checks"].all? { |check| check["status"] == "pass" }
    assert_equal "2026-10-08T12:00:00Z", report["generated_at"]
    assert_equal({ "files" => { "app/models/user.rb" => "abc123abc123" } }, report["source"])
  end

  test "summarizes coverage: rounded totals, named groups, files in path order" do
    coverage = build["coverage"]

    assert_equal 85.0, coverage["line"]
    assert_equal({ "covered" => 850, "total" => 1000 }, coverage["lines"])
    assert_equal [ { "name" => "Models", "line" => 95.6, "files" => 1 }, { "name" => "Other", "line" => 50.0, "files" => 1 } ],
      coverage["groups"]
    assert_equal %w[app/models/user.rb app/services/thing.rb], coverage["files"].map { |file| file["path"] }
    assert_equal({ "path" => "app/services/thing.rb", "line" => 50.0, "branch" => 25.0, "missed" => 10, "lines" => 20 },
      coverage["files"].last)
  end

  test "a failing test fails the report" do
    report = build(tests: TESTS.merge("failures" => 2, "errors" => 1))

    assert_equal "failing", report["status"]
    assert_equal "fail", check(report, "tests")["status"]
    assert_equal "3 of 120 tests failing.", check(report, "tests")["detail"]
  end

  test "a suite that never finished fails rather than passing with nothing" do
    report = build(tests: nil)

    assert_equal "failing", report["status"]
    assert_match "didn't finish", check(report, "tests")["detail"]
    assert_nil check(report, "skips")
  end

  test "a skipped test fails the report" do
    report = build(tests: TESTS.merge("skips" => 1))

    assert_equal "failing", report["status"]
    assert_match "hides a failure", check(report, "skips")["detail"]
  end

  test "coverage under the minimum fails" do
    report = build(coverage: simplecov(line: QualityReport::MINIMUM_LINE_COVERAGE - 0.1))

    assert_equal "fail", check(report, "coverage")["status"]
    assert_equal "fail", build(coverage: nil).then { |r| check(r, "coverage")["status"] }
  end

  test "coverage may not fall more than the allowed drop below the last committed report" do
    fell = build(coverage: simplecov(line: 84.0), previous: [ committed(line: 86.0) ])
    assert_equal "fail", check(fell, "trend")["status"]
    assert_equal "Down 2.0 points since abc1234 (86.0% → 84.0%). Add tests for the code you changed.", check(fell, "trend")["detail"]

    dipped = build(coverage: simplecov(line: 85.6), previous: [ committed(line: 86.0) ])
    assert_equal "pass", check(dipped, "trend")["status"]
    assert_match "Down 0.4 points", check(dipped, "trend")["detail"]

    rose = build(coverage: simplecov(line: 87.0), previous: [ committed(line: 86.0) ])
    assert_match "Up 1.0 points", check(rose, "trend")["detail"]
  end

  test "compares with the newest committed report and keeps them all as history" do
    report = build(previous: [ committed(line: 85.0, commit: "new1234"), committed(line: 99.0, commit: "old1234", tests: 90) ])

    assert_equal "Unchanged since new1234.", check(report, "trend")["detail"]
    assert_equal %w[new1234 old1234], report["history"].map { |entry| entry["commit"] }
    assert_equal({ "commit" => "old1234", "committed_at" => "2026-10-01T10:00:00-05:00", "status" => "passing",
                   "tests" => 90, "failing" => 1, "line" => 99.0, "branch" => 60.0 }, report["history"].last)
  end

  test "lint offenses and security warnings fail, and the first few are listed" do
    lint = { "summary" => { "offense_count" => 1, "inspected_file_count" => 10 },
             "files" => [ { "path" => "app/models/user.rb",
                            "offenses" => [ { "cop_name" => "Style/StringLiterals", "message" => "Prefer double quotes.",
                                              "location" => { "line" => 3 } } ] } ] }
    security = { "scan_info" => { "brakeman_version" => "8.1.0" },
                 "warnings" => [ { "warning_type" => "SQL Injection", "confidence" => "High", "file" => "app/models/user.rb",
                                   "line" => 9, "message" => "Possible SQL injection" } ] }

    report = build(lint: lint, security: security)

    assert_equal "failing", report["status"]
    assert_equal "1 offense. bin/rubocop -a fixes most.", check(report, "lint")["detail"]
    assert_equal [ { "path" => "app/models/user.rb", "line" => 3, "cop" => "Style/StringLiterals", "message" => "Prefer double quotes." } ],
      report["lint"]["listed"]
    assert_equal "1 security warning.", check(report, "security")["detail"]
    assert_equal "SQL Injection", report["security"]["listed"].first["type"]
  end

  test "a tool that couldn't produce a report fails with its own explanation" do
    report = build(security: { "error" => "Brakeman 7.1.1 is not the latest version 8.1.0" })

    assert_equal "fail", check(report, "security")["status"]
    assert_equal "Brakeman 7.1.1 is not the latest version 8.1.0", check(report, "security")["detail"]
  end

  test "a tool the app doesn't have is left out" do
    report = build(lint: nil, security: nil)

    assert_equal "passing", report["status"]
    assert_nil check(report, "lint")
    assert_nil check(report, "security")
  end

  test "lists a limited number of failures but counts them all" do
    problems = Array.new(QualityReport::Builder::LISTED + 5) { |i| { "kind" => "failure", "name" => "T##{i}" } }
    report = build(tests: TESTS.merge("failures" => problems.size, "problems" => problems))

    assert_equal QualityReport::Builder::LISTED, report["tests"]["problems"].size
    assert_equal problems.size, report["tests"]["failures"]
  end
end
