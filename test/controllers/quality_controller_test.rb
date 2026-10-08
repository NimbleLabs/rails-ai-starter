require "test_helper"

class QualityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @user  = users(:two)
  end

  def report(status: "passing")
    QualityReport.new(
      { "status" => status, "checks" => [], "tests" => { "count" => 12 }, "source" => { "files" => {} } },
      running: {}
    )
  end

  test "requires authentication" do
    get "/quality.json"
    assert_response :unauthorized
  end

  test "forbids non-admins" do
    sign_in @user
    get "/quality.json"
    assert_response :forbidden
  end

  test "returns the report for an admin" do
    sign_in @admin
    QualityReport.stub(:current, report) { get "/quality.json" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "bin/rails quality", body["command"]
    assert_equal "passing", body["report"]["status"]
    assert_equal 12, body["report"]["tests"]["count"]
    assert_not body["report"].key?("source"), "fingerprints stay on the server"
  end

  test "says how to make a report when there isn't one" do
    sign_in @admin
    QualityReport.stub(:current, nil) { get "/quality.json" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["report"]
    assert_equal "quality/report.json", body["path"]
  end

  test "explains an unreadable report instead of erroring" do
    sign_in @admin
    QualityReport.stub(:current, -> { raise QualityReport::Unreadable, "has conflict markers" }) { get "/quality.json" }

    assert_response :success
    assert_equal "has conflict markers", JSON.parse(response.body)["error"]
  end

  test "accepts an admin api token" do
    QualityReport.stub(:current, report) do
      get "/quality.json", headers: { "x-api-token" => @admin.auth_token }
    end
    assert_response :success
  end
end
