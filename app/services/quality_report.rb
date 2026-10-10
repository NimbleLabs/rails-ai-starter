# How well tested this app is, as of the last `bin/rails quality` run.
#
# Tests run on a developer's or an agent's machine, never in production, so the
# result travels with the code: `bin/rails quality` writes quality/report.json,
# the report is committed with the change it tested, and it deploys with that
# change. The admin's Quality page (/admin/quality) reads it here. There is no
# upload step, no token and no table.
#
# A committed report can go stale: code edited after the run, or two branches
# merged. So the report records a fingerprint of every source file, and this
# class compares them with the files actually running. The page can then say
# exactly which files changed since the suite last ran, instead of vouching for
# code nobody tested.
class QualityReport
  PATH = "quality/report.json"
  COMMAND = "bin/rails quality"

  # Raise these as the suite improves. Never lower one to turn a red report green.
  MINIMUM_LINE_COVERAGE = 78.0
  TARGET_LINE_COVERAGE = 90.0
  # How many points line coverage may fall below the last committed report.
  MAX_COVERAGE_DROP = 0.5

  # The files whose change makes a report stale. Generated assets and deploy
  # config are left out: they differ between a laptop and the production image.
  SOURCE_GLOBS = %w[
    app/**/*.{rb,erb,jsx,js,ts,tsx,css}
    lib/**/*.{rb,rake}
    config/**/*.rb
    db/**/*.rb
    test/**/*.{rb,yml}
    Gemfile.lock
    package.json
  ].freeze
  GENERATED = %r{\Aapp/assets/builds/}

  # How many changed paths the page lists.
  CHANGES_LISTED = 25

  class Unreadable < StandardError; end

  # nil when no report has been committed yet.
  def self.current(root: Rails.root)
    path = File.join(root, PATH)
    return unless File.exist?(path)

    new(JSON.parse(File.read(path)), running: running_fingerprints(root), root: root)
  rescue JSON::ParserError => e
    raise Unreadable, "#{PATH} isn't valid JSON (#{e.message.lines.first.strip}). " \
                      "If it has merge conflict markers, rerun #{COMMAND} rather than merging it by hand."
  end

  # { "app/models/user.rb" => "3f1c0a9be2d4", ... }
  def self.fingerprints(root = Rails.root)
    Dir.glob(SOURCE_GLOBS, base: root.to_s).grep_v(GENERATED).sort.to_h do |path|
      [ path, Digest::SHA256.file(File.join(root, path)).hexdigest[0, 12] ]
    end
  end

  # Production code can't change without a restart, so fingerprint it once.
  def self.running_fingerprints(root)
    return fingerprints(root) unless Rails.env.production? && root.to_s == Rails.root.to_s

    @running_fingerprints ||= fingerprints(root)
  end

  attr_reader :data

  def initialize(data, running:, root: Rails.root)
    @data = data
    @running = running
    @root = root.to_s
  end

  # "passing", "failing", or "stale" (passed, but the code has changed since).
  def status
    return "failing" unless data["status"] == "passing"

    fresh? ? "passing" : "stale"
  end

  def fresh?
    changes.values.all?(&:empty?)
  end

  # Source files that differ from the ones the suite ran against. A top-level
  # directory that doesn't ship (say test/ left out of an image) isn't compared,
  # since its absence says nothing about whether the tests are current.
  def changes
    @changes ||= begin
      recorded = data.dig("source", "files").to_h.select { |path, _| shipped?(path) }
      {
        "modified" => (recorded.keys & @running.keys).reject { |path| recorded[path] == @running[path] },
        "added" => @running.keys - recorded.keys,
        "removed" => recorded.keys - @running.keys
      }
    end
  end

  def checks
    data.fetch("checks", []) + [ freshness_check ]
  end

  def as_json(*)
    data.except("source").merge(
      "status" => status,
      "checks" => checks,
      "changes" => changes.transform_values { |paths| paths.first(CHANGES_LISTED) },
      "changed_count" => changes.values.sum(&:size)
    )
  end

  private

  def shipped?(path)
    File.exist?(File.join(@root, path.split("/").first))
  end

  def freshness_check
    count = changes.values.sum(&:size)
    detail = if count.zero?
      "No source file has changed since this run."
    else
      "#{count} #{'file'.pluralize(count)} changed since this run. Rerun #{COMMAND} and commit the report."
    end
    { "key" => "fresh", "label" => "Matches the running code", "status" => count.zero? ? "pass" : "warn", "detail" => detail }
  end
end
