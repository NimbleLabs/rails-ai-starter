require "json"
require "fileutils"

# Writes the results of a test run to JSON for `bin/rails quality`, which folds
# them into quality/report.json. Loaded by test_helper only when
# QUALITY_TEST_RESULTS names the output file.
#
# It runs in the parent process, which is where Rails' parallel workers send
# every result, so it sees the whole suite.
class QualityTestReporter < Minitest::StatisticsReporter
  SLOWEST = 5
  MESSAGE_LIMIT = 1_000

  def self.install(path)
    @path = path
    Minitest.register_plugin(self)
  end

  def self.minitest_plugin_init(_options)
    Minitest.reporter << new(@path)
  end

  def initialize(path)
    super($stdout, {})
    @path = path
    @by_type = Hash.new(0)
    @timings = []
  end

  def record(result)
    super
    file, line = result.source_location
    @by_type[test_type(file)] += 1
    @timings << { name: name(result), location: location(file, line), time: result.time.round(2) }
  end

  def report
    super
    FileUtils.mkdir_p(File.dirname(@path))
    File.write(@path, JSON.pretty_generate(summary))
  end

  private

  def summary
    {
      count: count,
      assertions: assertions,
      failures: failures,
      errors: errors,
      skips: skips,
      duration: total_time.round(1),
      seed: Minitest.seed,
      by_type: @by_type.sort.to_h,
      slowest: @timings.max_by(SLOWEST) { |timing| timing[:time] },
      problems: results.map { |result| problem(result) }
    }
  end

  def problem(result)
    file, line = result.source_location
    kind = if result.skipped? then "skip" elsif result.error? then "error" else "failure" end
    {
      kind: kind,
      name: name(result),
      location: location(file, line),
      message: result.failure.message.to_s.strip[0, MESSAGE_LIMIT]
    }
  end

  def name(result)
    "#{result.klass}##{result.name}"
  end

  # test/controllers/api/logs_test.rb -> "controllers"
  def test_type(file)
    relative = relative_path(file)
    relative.start_with?("test/") ? relative.split("/")[1].delete_suffix("_test.rb") : "other"
  end

  def location(file, line)
    "#{relative_path(file)}:#{line}"
  end

  def relative_path(file)
    file.to_s.delete_prefix("#{Dir.pwd}/")
  end
end
