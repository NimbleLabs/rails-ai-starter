# What `/up` actually needs to prove.
#
# Rails' built-in health check returns 200 whenever the app boots. That is the
# wrong answer for the failure that matters on deploy: a missing table or a
# pending migration leaves the app booting fine while pages return 500, and an
# automated deploy (or load balancer) keeps trusting it. A health check that
# cannot fail is not a health check. Ported from RealInsightHQ, which hit this.
#
# It checks, cheaply enough to poll: the database answers, migrations are
# current, the tables the app cannot run without exist, and the cache
# round-trips. Returns 503 naming what is broken.
class HealthController < ApplicationController
  # Deliberately short: the tables whose absence causes confusing failures.
  # Add a product's own core tables here as it grows.
  REQUIRED_TABLES = %w[users solid_queue_jobs solid_cache_entries solid_cable_messages].freeze

  def show
    checks = {
      "database" => database_check,
      "migrations" => migrations_check,
      "tables" => tables_check,
      "cache" => cache_check
    }
    failed = checks.reject { |_, check| check[:ok] }
    Rails.logger.error("[health] FAILING: #{failed.map { |name, check| "#{name}=#{check[:detail]}" }.join(' ')}") if failed.any?

    render json: { status: failed.any? ? "error" : "ok", checks: checks },
           status: failed.any? ? :service_unavailable : :ok
  end

  private

  def database_check
    ActiveRecord::Base.connection.select_value("SELECT 1")
    { ok: true }
  rescue => e
    failure(e)
  end

  # Code shipped ahead of its migrations boots fine, then breaks on the first
  # page that touches the new column.
  def migrations_check
    if ActiveRecord::Base.connection_pool.migration_context.needs_migration?
      { ok: false, detail: "pending migrations — run bin/rails db:migrate" }
    else
      { ok: true }
    end
  rescue => e
    failure(e)
  end

  def tables_check
    missing = REQUIRED_TABLES - ActiveRecord::Base.connection.tables
    missing.empty? ? { ok: true } : { ok: false, detail: "missing: #{missing.join(', ')}" }
  rescue => e
    failure(e)
  end

  # A cache backed by a missing table raises here instead of on a visitor's page.
  # A deliberately disabled cache (the test environment's null store) is fine.
  def cache_check
    return { ok: true } if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)

    Rails.cache.write("health/probe", Time.current.to_i, expires_in: 1.minute)
    Rails.cache.read("health/probe") ? { ok: true } : { ok: false, detail: "wrote to the cache but read nothing back" }
  rescue => e
    failure(e)
  end

  def failure(error)
    { ok: false, detail: "#{error.class}: #{error.message.to_s.first(120)}" }
  end
end
