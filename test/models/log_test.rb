require "test_helper"

class LogTest < ActiveSupport::TestCase
  setup do
    Log.delete_all
    LogSubscription.delete_all
  end

  def raise_and_record(message, **opts)
    raise ArgumentError, message
  rescue => e
    Log.record(e, **opts)
  end

  test "records an exception with class, backtrace and level" do
    log = raise_and_record("something broke", source: "web")

    assert log.persisted?
    assert_equal "ArgumentError", log.error_class
    assert_equal "something broke", log.message
    assert_equal "error", log.level
    assert_equal "web", log.source
    assert log.backtrace.present?
    assert_equal 1, log.occurrences
  end

  test "records a plain string message" do
    log = Log.warn("Stripe webhook signature mismatch", source: "web")

    assert_equal "warn", log.level
    assert_nil log.error_class
    assert_equal "Stripe webhook signature mismatch", log.message
  end

  test "rolls up repeats of the same problem instead of creating rows" do
    first  = raise_and_record("Couldn't find User with id=42", source: "web")
    second = raise_and_record("Couldn't find User with id=99", source: "web")

    assert_equal first.id, second.id, "numeric variants should share a fingerprint"
    assert_equal 2, second.occurrences
    assert_equal 1, Log.count
  end

  test "rollup escalates the level but never lowers it" do
    log = raise_and_record("boom", source: "web")
    assert_equal "error", log.level

    raise_and_record("boom", source: "web", level: :fatal)
    assert_equal "fatal", log.reload.level

    raise_and_record("boom", source: "web", level: :warn)
    assert_equal "fatal", log.reload.level, "a lower level must not downgrade the row"
  end

  test "a resolved log does not absorb new occurrences" do
    first = raise_and_record("boom", source: "web")
    first.resolve!

    second = raise_and_record("boom", source: "web")

    assert_not_equal first.id, second.id
    assert_equal 1, second.occurrences
  end

  test "rollup ignores occurrences older than the dedupe window" do
    first = raise_and_record("boom", source: "web")
    first.update_column(:last_seen_at, (Log::DEDUPE_WINDOW + 1.hour).ago)

    second = raise_and_record("boom", source: "web")

    assert_not_equal first.id, second.id
  end

  test "promotes request context onto columns" do
    log = raise_and_record("boom", source: "web", context: { path: "/checkout", request_id: "req-1" })

    assert_equal "/checkout", log.path
    assert_equal "req-1", log.request_id
  end

  test "associates a user when given one" do
    user = users(:two)
    log = raise_and_record("boom", source: "web", user: user)

    assert_equal user.id, log.user_id
  end

  test "coerces an unknown source rather than raising" do
    log = Log.record("hello", source: "not-a-real-source")

    assert log.persisted?
    assert_includes Log::SOURCES, log.source
  end

  test "never raises on bad input" do
    assert_nothing_raised do
      Log.record(nil)
      Log.record("")
      Log.record("x", context: { bad: Object.new })
    end
  end

  test "truncates an oversized message" do
    log = Log.record("x" * (Log::MAX_MESSAGE_BYTES + 500), source: "web")

    assert_operator log.message.bytesize, :<=, Log::MAX_MESSAGE_BYTES
  end

  test "truncates an oversized single context value" do
    log = Log.record("boom", source: "web", context: { blob: "y" * (Log::MAX_CONTEXT_BYTES + 1_000) })

    assert_operator log.context["blob"].bytesize, :<=, Log::MAX_CONTEXT_VALUE_BYTES
  end

  test "replaces an oversized context as a whole with a truncated preview" do
    wide = (1..40).to_h { |i| [ "key#{i}", "z" * (Log::MAX_CONTEXT_VALUE_BYTES - 1) ] }
    log = Log.record("boom", source: "web", context: wide)

    assert log.context["truncated"]
    assert log.context["preview"].present?
  end

  test "caps the number of context entries" do
    many = (1..(Log::MAX_CONTEXT_ENTRIES + 25)).to_h { |i| [ "k#{i}", i ] }
    log = Log.record("boom", source: "web", context: many)

    assert_operator log.context.keys.size, :<=, Log::MAX_CONTEXT_ENTRIES
  end

  test "survives a context value that recurses under to_json" do
    # Regression: some Rails internals (routing nodes) are Enumerables whose
    # JSON serialization recurses forever. Recording one must not blow the stack.
    recursive = []
    recursive << recursive

    log = nil
    assert_nothing_raised do
      log = Log.record("boom", source: "web", context: { route: recursive })
    end
    assert log.present?
  end

  test "survives a context value whose to_json raises" do
    hostile = Object.new
    hostile.define_singleton_method(:to_json) { |*| raise "no json for you" }
    hostile.define_singleton_method(:to_s) { "hostile object" }

    log = Log.record("boom", source: "web", context: { thing: hostile })

    assert log.present?
    assert_equal "hostile object", log.context["thing"]
  end

  test "coerces non-primitive context values to strings" do
    log = Log.record("boom", source: "web", context: { when: Time.utc(2026, 1, 2, 3, 4, 5), sym: :abc, num: 7, flag: true })

    assert_equal "abc", log.context["sym"]
    assert_equal 7, log.context["num"]
    assert_equal true, log.context["flag"]
    assert_match "2026-01-02", log.context["when"]
  end

  test "caps context nesting depth" do
    deep = current = {}
    10.times { |i| nxt = {}; current["level#{i}"] = nxt; current = nxt }
    current["bottom"] = "reached"

    log = Log.record("boom", source: "web", context: deep)

    assert log.present?
    assert_match "too deep", log.context.to_s
  end

  test "captures the exception cause" do
    log = begin
      begin
        raise "the root cause"
      rescue
        raise ArgumentError, "the surface error"
      end
    rescue => e
      Log.record(e, source: "web")
    end

    assert_match "the root cause", log.context["cause"]
  end

  test "fingerprint ignores line-number drift within the same frame" do
    a = Log.fingerprint_for("RuntimeError", "boom", [ "app/models/thing.rb:10:in 'call'" ])
    b = Log.fingerprint_for("RuntimeError", "boom", [ "app/models/thing.rb:57:in 'call'" ])

    assert_equal a, b
  end

  test "fingerprint separates different error classes" do
    a = Log.fingerprint_for("RuntimeError", "boom", [ "app/models/thing.rb:10" ])
    b = Log.fingerprint_for("ArgumentError", "boom", [ "app/models/thing.rb:10" ])

    assert_not_equal a, b
  end

  test "resolve! and unresolve! flip state" do
    log = Log.record("boom", source: "web")

    log.resolve!(by: users(:one))
    assert log.resolved?
    assert_equal users(:one).email, log.context["resolved_by"]

    log.unresolve!
    assert_not log.resolved?
  end

  test "scopes filter as expected" do
    error = Log.record("an error", source: "web", level: :error)
    warn  = Log.record("a warning", source: "job", level: :warn)
    Log.record("resolved one", source: "web").resolve!

    assert_includes Log.unresolved, error
    assert_equal 1, Log.resolved.count
    assert_includes Log.at_or_above(:error), error
    assert_not_includes Log.at_or_above(:error), warn
    assert_includes Log.from_source("job"), warn
    assert_includes Log.search("warning"), warn
    assert_not_includes Log.search("warning"), error
  end

  test "enqueues a notification only when a subscription exists" do
    assert_no_enqueued_jobs(only: LogNotificationJob) do
      Log.record("nobody is listening", source: "web")
    end

    LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :error)

    assert_enqueued_jobs(1, only: LogNotificationJob) do
      Log.record("somebody is listening", source: "web")
    end
  end

  test "a rollup re-notifies but a resolve does not" do
    LogSubscription.create!(channel: :email, destination: "ops@example.com", min_level: :error)
    log = Log.record("recurring", source: "web")

    assert_enqueued_jobs(1, only: LogNotificationJob) do
      Log.record("recurring", source: "web")
    end

    assert_no_enqueued_jobs(only: LogNotificationJob) do
      log.reload.resolve!
    end
  end
end
