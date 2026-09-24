require "test_helper"

# /up must go red when the app boots but cannot serve pages. These cover the
# failures an automated deploy would otherwise wave through.
class HealthTest < ActionDispatch::IntegrationTest
  test "reports ok when everything is in place" do
    get rails_health_check_url
    assert_response :success
    body = response.parsed_body
    assert_equal "ok", body["status"]
    assert body["checks"].values.all? { |check| check["ok"] }, body.inspect
  end

  test "fails with 503 and names a missing table" do
    ActiveRecord::Base.connection.execute("ALTER TABLE solid_cache_entries RENAME TO solid_cache_entries_hidden")
    get rails_health_check_url
    assert_response :service_unavailable
    assert_not response.parsed_body["checks"]["tables"]["ok"]
    assert_match(/solid_cache_entries/, response.parsed_body["checks"]["tables"]["detail"])
  ensure
    ActiveRecord::Base.connection.execute("ALTER TABLE solid_cache_entries_hidden RENAME TO solid_cache_entries")
  end

  test "fails when a migration has not been run" do
    latest = ActiveRecord::Base.connection.select_value("SELECT MAX(version) FROM schema_migrations")
    ActiveRecord::Base.connection.execute("DELETE FROM schema_migrations WHERE version = '#{latest}'")
    get rails_health_check_url
    assert_response :service_unavailable
    assert_match(/db:migrate/, response.parsed_body["checks"]["migrations"]["detail"])
  ensure
    ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES ('#{latest}') ON CONFLICT DO NOTHING")
  end

  test "a failing cache is reported rather than swallowed" do
    broken = Class.new do
      def write(*) = raise(ActiveRecord::StatementInvalid, 'relation "solid_cache_entries" does not exist')
      def read(*) = nil
    end.new
    original = Rails.cache
    Rails.cache = broken
    get rails_health_check_url
    assert_response :service_unavailable
    assert_match(/solid_cache_entries/, response.parsed_body["checks"]["cache"]["detail"])
  ensure
    Rails.cache = original
  end
end
