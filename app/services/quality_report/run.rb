require "open3"

class QualityReport
  # What `bin/rails quality` does: run every test (system tests included) with
  # coverage, run RuboCop and Brakeman, then write quality/report.json.
  # Development only; it shells out to the suite, the linters and git.
  class Run
    TEST_RESULTS = "tmp/quality/tests.json"
    COVERAGE_JSON = "coverage/coverage.json"
    # Committed reports kept as history on the Quality page.
    HISTORY = 30

    def initialize(root: Rails.root)
      @root = Pathname(root)
    end

    def call
      tests = run_tests
      report = Builder.new(
        tests: tests,
        coverage: read_json(COVERAGE_JSON),
        lint: run_tool("bin/rubocop", "--format", "json"),
        security: run_tool("bin/brakeman", "--format", "json", "--no-pager", "--quiet", "--no-exit-on-warn"),
        previous: committed_reports,
        fingerprints: QualityReport.fingerprints(@root)
      ).build

      path = @root.join(PATH)
      FileUtils.mkdir_p(path.dirname)
      File.write(path, "#{JSON.pretty_generate(report)}\n")
      report
    end

    # Each committed version of the report reachable from HEAD, newest first.
    def committed_reports(limit: HISTORY)
      log, _, status = git("log", "-n", limit.to_s, "--format=%h %cI", "--", PATH)
      return [] unless status.success?

      log.lines.filter_map do |line|
        commit, committed_at = line.split
        json, _, shown = git("show", "#{commit}:#{PATH}")
        next unless shown.success?

        { "commit" => commit, "committed_at" => committed_at, "report" => JSON.parse(json) }
      rescue JSON::ParserError
        nil
      end
    end

    private

    def run_tests
      FileUtils.rm_rf([ @root.join("coverage"), @root.join(TEST_RESULTS) ])
      env = { "COVERAGE" => "1", "QUALITY_TEST_RESULTS" => @root.join(TEST_RESULTS).to_s }
      # The shell's environment, not this development process's: dotenv has
      # loaded development settings into ENV that the test run mustn't inherit.
      Bundler.with_original_env { system(env, "bin/rails", "test:all", chdir: @root.to_s) }
      read_json(TEST_RESULTS)
    end

    # nil when the app has dropped the tool; { "error" => ... } when it ran but
    # produced no report (Brakeman refusing to run when it's outdated, say).
    def run_tool(binstub, *args)
      return unless @root.join(binstub).exist?

      out, err, status = Bundler.with_original_env { Open3.capture3(binstub, *args, chdir: @root.to_s) }
      JSON.parse(out)
    rescue JSON::ParserError
      { "error" => err.to_s.strip.lines.last&.strip.presence || "#{binstub} exited with status #{status&.exitstatus}." }
    end

    def git(*args)
      Open3.capture3("git", *args, chdir: @root.to_s)
    rescue Errno::ENOENT
      [ "", "", Struct.new(:success?).new(false) ]
    end

    def read_json(relative)
      path = @root.join(relative)
      JSON.parse(path.read) if path.exist?
    rescue JSON::ParserError
      nil
    end
  end
end
