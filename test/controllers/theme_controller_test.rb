require "test_helper"

class ThemeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @user = users(:two)
    @dir = Pathname(Dir.mktmpdir("theme"))
    AppConfig.path = @dir.join("app.yml").to_s
    AppConfig.new.write
  end

  teardown do
    AppConfig.path = nil
    FileUtils.rm_rf(@dir)
  end

  def teal(**theme)
    { name: "Acme", short_name: "AC", theme: { display_font: "Fraunces", body_font: "Inter", primary: "#0f766e",
                                               secondary: "#f59e0b", corners: "round" }.merge(theme) }
  end

  test "requires an admin" do
    get "/theme.json"
    assert_response :unauthorized

    sign_in @user
    get "/theme.json"
    assert_response :forbidden
  end

  test "shows the saved config with its presets, fonts and derived look" do
    sign_in @admin
    get "/theme.json"

    assert_response :success
    body = response.parsed_body
    assert_equal "Starter", body["config"]["name"]
    assert_equal "starter", body["presets"].first["slug"]
    assert_includes body["fonts"], { "family" => "Orbitron", "category" => "sans", "display_only" => true }
    assert_equal %w[sharp soft round], body["corners"]
    assert_equal "#7c3aed", body["preview"]["css_variables"]["light"]["--theme-primary"]
    assert body["can_save"]
  end

  test "previews a draft without saving it" do
    sign_in @admin
    post "/theme/preview.json", params: { config: teal }, as: :json

    preview = response.parsed_body
    assert_empty preview["errors"]
    assert_equal "#0f766e", preview["css_variables"]["light"]["--theme-primary"]
    assert_match "family=Fraunces", preview["fonts_url"]
    assert_match 'name: "Acme"', preview["yaml"]
    assert_equal "Starter", AppConfig.current.name, "nothing was written"
  end

  test "a preview of an invalid draft explains, and still shows the contrast" do
    sign_in @admin
    post "/theme/preview.json", params: { config: teal(primary: "#facc15", body_font: "Papyrus") }, as: :json

    preview = response.parsed_body
    assert_includes preview["errors"], %("Papyrus" isn't on the approved font list.)
    assert_nil preview["css_variables"]
    assert_equal 1.5, preview["contrast"]["primary_on_white"]
  end

  test "saves to config/app.yml in development" do
    sign_in @admin
    put "/theme.json", params: { config: teal }, as: :json

    assert_response :success
    assert_equal "Acme", AppConfig.current.name
    assert_equal "round", AppConfig.current.theme.corners
    assert_equal "#0f766e", response.parsed_body["config"]["theme"]["primary"]
  end

  test "won't save an invalid config" do
    sign_in @admin
    put "/theme.json", params: { config: teal(primary: "#facc15") }, as: :json

    assert_response :unprocessable_entity
    assert_match "too light", response.parsed_body["errors"]["base"].first
    assert_equal "Starter", AppConfig.current.name
  end

  test "production previews but doesn't save" do
    sign_in @admin
    Rails.env.stub(:local?, false) do
      put "/theme.json", params: { config: teal }, as: :json
      assert_response :forbidden

      get "/theme.json"
      assert_not response.parsed_body["can_save"]
    end
    assert_equal "Starter", AppConfig.current.name
  end
end
