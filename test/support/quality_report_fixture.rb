# A realistic QualityReport for system tests, built the way `bin/rails quality`
# builds one, so the admin page is exercised against the real shape.
module QualityReportFixture
  LONG_PATH = "app/services/integrations/some_vendor/webhooks/subscription_lifecycle_reconciler.rb".freeze

  def quality_report(failing: false, stale: false)
    problems = failing ? [ { "kind" => "failure", "name" => "SubscriptionLifecycleReconcilerTest#test_#{'a_long_name_' * 6}",
                             "location" => "test/services/subscription_lifecycle_reconciler_test.rb:42",
                             "message" => "Expected: #{'x' * 300}\n  Actual: nil" } ] : []
    data = QualityReport::Builder.new(
      tests: { "count" => 158, "assertions" => 484, "failures" => problems.size, "errors" => 0, "skips" => 0,
               "duration" => 10.5, "by_type" => { "models" => 100, "controllers" => 48, "system" => 10 },
               "slowest" => [ { "name" => "AdminSpaTest#test_every_admin_page_mounts", "location" => "test/system/admin_spa_test.rb:37", "time" => 2.4 } ],
               "problems" => problems },
      coverage: {
        "total" => { "lines" => { "covered" => 830, "total" => 1000, "percent" => 83.0 },
                     "branches" => { "covered" => 60, "total" => 100, "percent" => 60.0 } },
        "groups" => { "Models" => { "lines" => { "percent" => 95.0 }, "files" => [ "app/models/user.rb" ] } },
        "coverage" => {
          LONG_PATH => { "lines_covered_percent" => 12.5, "branches_covered_percent" => 0.0, "missed_lines" => 70, "total_lines" => 80 },
          "app/models/user.rb" => { "lines_covered_percent" => 95.0, "branches_covered_percent" => 90.0, "missed_lines" => 2, "total_lines" => 40 }
        }
      },
      lint: { "summary" => { "offense_count" => 0, "inspected_file_count" => 160 }, "files" => [] },
      security: { "scan_info" => { "brakeman_version" => "8.1.0" }, "warnings" => [] },
      previous: [ 82.0, 80.5, 78.0 ].each_with_index.map do |line, i|
        { "commit" => "abc12#{i}", "committed_at" => "2026-10-0#{i + 1}T10:00:00Z",
          "report" => { "status" => "passing", "tests" => { "count" => 150 - i }, "coverage" => { "line" => line } } }
      end,
      fingerprints: { "app/models/user.rb" => "aaaaaaaaaaaa", LONG_PATH => "bbbbbbbbbbbb" }
    ).build

    running = data["source"]["files"].dup
    running[LONG_PATH] = "cccccccccccc" if stale
    QualityReport.new(data, running: running)
  end
end
