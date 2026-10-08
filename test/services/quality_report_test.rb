require "test_helper"

class QualityReportTest < ActiveSupport::TestCase
  setup do
    @root = Pathname(Dir.mktmpdir("quality"))
    write "app/models/widget.rb", "class Widget; end\n"
    write "test/models/widget_test.rb", "# tests\n"
  end

  teardown { FileUtils.rm_rf(@root) }

  def write(path, content)
    @root.join(path).dirname.mkpath
    @root.join(path).write(content)
  end

  # A passing report recorded against the files as they are right now.
  def commit_report(status: "passing", files: QualityReport.fingerprints(@root))
    report = {
      "status" => status,
      "checks" => [ { "key" => "tests", "label" => "Tests pass", "status" => status == "passing" ? "pass" : "fail", "detail" => "" } ],
      "source" => { "files" => files }
    }
    write QualityReport::PATH, report.to_json
  end

  test "there is no report until one is committed" do
    assert_nil QualityReport.current(root: @root)
  end

  test "fingerprints source files, but not generated assets or other files" do
    write "app/assets/builds/tailwind.css", "/* built */"
    write "app/assets/tailwind/application.css", "/* source */"
    write "app/models/.DS_Store", "junk"
    write "config/deploy.yml", "servers: []"
    write "config/routes.rb", "# routes"

    fingerprints = QualityReport.fingerprints(@root)

    assert_equal %w[app/assets/tailwind/application.css app/models/widget.rb config/routes.rb test/models/widget_test.rb],
      fingerprints.keys
    assert_match(/\A\h{12}\z/, fingerprints["app/models/widget.rb"])
  end

  test "a passing report that matches the code is passing" do
    commit_report
    report = QualityReport.current(root: @root)

    assert_equal "passing", report.status
    assert report.fresh?
    assert_equal "pass", report.checks.last["status"]
  end

  test "editing, adding or deleting a source file makes it stale, and says which" do
    commit_report
    write "app/models/widget.rb", "class Widget; def changed; end; end\n"
    write "app/models/gadget.rb", "class Gadget; end\n"
    @root.join("test/models/widget_test.rb").delete

    report = QualityReport.current(root: @root)

    assert_equal "stale", report.status
    assert_equal({ "modified" => [ "app/models/widget.rb" ], "added" => [ "app/models/gadget.rb" ],
                   "removed" => [ "test/models/widget_test.rb" ] }, report.changes)
    assert_equal "warn", report.checks.last["status"]
    assert_match "3 files changed", report.checks.last["detail"]
  end

  test "a failing report stays failing whether or not it is stale" do
    commit_report(status: "failing")
    assert_equal "failing", QualityReport.current(root: @root).status

    write "app/models/widget.rb", "# changed\n"
    assert_equal "failing", QualityReport.current(root: @root).status
  end

  test "a directory that doesn't ship isn't counted as removed" do
    commit_report
    FileUtils.rm_rf(@root.join("test"))

    assert QualityReport.current(root: @root).fresh?, "an image without test/ still runs the tested app code"
  end

  test "as_json leaves out the fingerprints and adds what changed" do
    commit_report
    write "app/models/gadget.rb", "class Gadget; end\n"

    json = QualityReport.current(root: @root).as_json

    assert_not json.key?("source")
    assert_equal "stale", json["status"]
    assert_equal [ "app/models/gadget.rb" ], json["changes"]["added"]
    assert_equal 1, json["changed_count"]
  end

  test "a report with merge conflict markers is unreadable, with a way out" do
    write QualityReport::PATH, "<<<<<<< HEAD\n{}\n=======\n{}\n>>>>>>> feature\n"

    error = assert_raises(QualityReport::Unreadable) { QualityReport.current(root: @root) }
    assert_match "rerun bin/rails quality", error.message
  end
end
