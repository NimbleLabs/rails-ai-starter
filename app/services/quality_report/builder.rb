class QualityReport
  # Turns one run's raw tool output into the report `bin/rails quality` writes:
  # Minitest results (test/support/quality_test_reporter.rb), SimpleCov's
  # coverage.json, RuboCop and Brakeman JSON, and the reports already committed
  # (newest first) for history and the coverage trend.
  #
  # Pure: QualityReport::Run gathers the inputs.
  class Builder
    VERSION = 1
    # Failures, offenses and warnings listed individually; the counts are always complete.
    LISTED = 20

    def initialize(tests:, coverage:, lint:, security:, previous: [], fingerprints: {}, generated_at: Time.current)
      @tests = tests
      @coverage = coverage
      @lint = lint
      @security = security
      @previous = previous
      @fingerprints = fingerprints
      @generated_at = generated_at
    end

    def build
      tests = tests_section
      coverage = coverage_section
      lint = lint_section
      security = security_section
      checks = [
        tests_check(tests), skips_check(tests), coverage_check(coverage), trend_check(coverage),
        lint_check(lint), security_check(security)
      ].compact

      {
        "version" => VERSION,
        "generated_at" => @generated_at.iso8601,
        "status" => checks.all? { |check| check["status"] == "pass" } ? "passing" : "failing",
        "checks" => checks,
        "thresholds" => {
          "minimum_line_coverage" => MINIMUM_LINE_COVERAGE,
          "target_line_coverage" => TARGET_LINE_COVERAGE,
          "max_coverage_drop" => MAX_COVERAGE_DROP
        },
        "tests" => tests,
        "coverage" => coverage,
        "lint" => lint,
        "security" => security,
        "history" => history,
        "source" => { "files" => @fingerprints }
      }
    end

    private

    # --- sections ---------------------------------------------------------

    def tests_section
      return unless @tests

      @tests.merge("problems" => @tests.fetch("problems", []).first(LISTED))
    end

    def coverage_section
      return unless @coverage

      total = @coverage.fetch("total")
      {
        "line" => percent(total.dig("lines", "percent")),
        "branch" => percent(total.dig("branches", "percent")),
        "lines" => total["lines"]&.slice("covered", "total"),
        "branches" => total["branches"]&.slice("covered", "total"),
        "groups" => @coverage.fetch("groups", {}).map do |name, group|
          { "name" => name == "Ungrouped" ? "Other" : name,
            "line" => percent(group.dig("lines", "percent")),
            "files" => group.fetch("files", []).size }
        end.sort_by { |group| group["name"] },
        "files" => @coverage.fetch("coverage", {}).map do |path, file|
          { "path" => path,
            "line" => percent(file["lines_covered_percent"]),
            "branch" => percent(file["branches_covered_percent"]),
            "missed" => file["missed_lines"],
            "lines" => file["total_lines"] }
        end.sort_by { |file| file["path"] }
      }
    end

    def lint_section
      return unless @lint
      return @lint if @lint["error"]

      offenses = @lint.fetch("files", []).flat_map do |file|
        file.fetch("offenses", []).map do |offense|
          { "path" => file["path"], "line" => offense.dig("location", "line"),
            "cop" => offense["cop_name"], "message" => offense["message"] }
        end
      end
      {
        "offenses" => @lint.dig("summary", "offense_count"),
        "files" => @lint.dig("summary", "inspected_file_count"),
        "listed" => offenses.first(LISTED)
      }
    end

    def security_section
      return unless @security
      return @security if @security["error"]

      warnings = @security.fetch("warnings", [])
      {
        "warnings" => warnings.size,
        "version" => @security.dig("scan_info", "brakeman_version"),
        "listed" => warnings.first(LISTED).map do |warning|
          { "type" => warning["warning_type"], "confidence" => warning["confidence"],
            "path" => warning["file"], "line" => warning["line"], "message" => warning["message"] }
        end
      }
    end

    def history
      @previous.map do |entry|
        report = entry.fetch("report")
        {
          "commit" => entry["commit"],
          "committed_at" => entry["committed_at"],
          "status" => report["status"],
          "tests" => report.dig("tests", "count"),
          "failing" => report.dig("tests", "failures").to_i + report.dig("tests", "errors").to_i,
          "line" => report.dig("coverage", "line"),
          "branch" => report.dig("coverage", "branch")
        }
      end
    end

    # --- checks -----------------------------------------------------------

    def tests_check(tests)
      return check("tests", "Tests pass", false, "The suite didn't finish. Run bin/rails test:all to see why.") unless tests

      failing = tests["failures"].to_i + tests["errors"].to_i
      check("tests", "Tests pass", failing.zero?,
        failing.zero? ? "#{tests['count']} tests, #{tests['assertions']} assertions." : "#{failing} of #{tests['count']} tests failing.")
    end

    def skips_check(tests)
      return unless tests

      skips = tests["skips"].to_i
      check("skips", "Nothing skipped", skips.zero?,
        skips.zero? ? "Every test ran." : "#{skips} skipped. A skipped test hides a failure: fix it or delete it.")
    end

    def coverage_check(coverage)
      return check("coverage", "Coverage", false, "No coverage was recorded.") unless coverage&.dig("line")

      check("coverage", "Coverage", coverage["line"] >= MINIMUM_LINE_COVERAGE,
        "#{coverage['line']}% of lines (minimum #{MINIMUM_LINE_COVERAGE}%, target #{TARGET_LINE_COVERAGE}%).")
    end

    def trend_check(coverage)
      before = @previous.first
      was = before&.dig("report", "coverage", "line")
      now = coverage&.dig("line")
      return check("trend", "Coverage held", true, "No earlier report to compare with.") unless was && now

      change = (now - was).round(1)
      since = "since #{before['commit']} (#{was}% → #{now}%)"
      if change < -MAX_COVERAGE_DROP
        check("trend", "Coverage held", false, "Down #{-change} points #{since}. Add tests for the code you changed.")
      elsif change.zero?
        check("trend", "Coverage held", true, "Unchanged since #{before['commit']}.")
      else
        check("trend", "Coverage held", true, "#{change.positive? ? 'Up' : 'Down'} #{change.abs} points #{since}.")
      end
    end

    def lint_check(lint)
      return unless lint
      return check("lint", "RuboCop", false, lint["error"]) if lint["error"]

      offenses = lint["offenses"].to_i
      check("lint", "RuboCop", offenses.zero?,
        offenses.zero? ? "No offenses in #{lint['files']} files." : "#{offenses} #{'offense'.pluralize(offenses)}. bin/rubocop -a fixes most.")
    end

    def security_check(security)
      return unless security
      return check("security", "Brakeman", false, security["error"]) if security["error"]

      warnings = security["warnings"].to_i
      check("security", "Brakeman", warnings.zero?,
        warnings.zero? ? "No security warnings." : "#{warnings} security #{'warning'.pluralize(warnings)}.")
    end

    def check(key, label, passed, detail)
      { "key" => key, "label" => label, "status" => passed ? "pass" : "fail", "detail" => detail }
    end

    def percent(value)
      value&.round(1)
    end
  end
end
