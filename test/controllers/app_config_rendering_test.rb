require "test_helper"

# config/app.yml reaches every page shell: the name, the brand mark, the fonts
# and the colors, with nothing left over from the starter.
class AppConfigRenderingTest < ActionDispatch::IntegrationTest
  setup do
    @dir = Pathname(Dir.mktmpdir("app-config"))
    AppConfig.path = @dir.join("app.yml").to_s
    AppConfig.new(name: "Acme Recipes", short_name: "AR", tagline: "Cook what you have.", support_email: "help@acme.test",
                  theme: { display_font: "Fraunces", body_font: "Inter", primary: "#0f766e", corners: "round" }).write
  end

  teardown do
    AppConfig.path = nil
    FileUtils.rm_rf(@dir)
  end

  def assert_themed
    assert_select "link[href=?]", "https://fonts.googleapis.com/css2?family=Fraunces:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700;800&display=swap"
    assert_select "style", text: /--theme-primary:#0f766e;/
  end

  test "marketing pages" do
    get root_url

    assert_themed
    assert_select "title", "Acme Recipes"
    assert_select "meta[name=description][content=?]", "Cook what you have."
    assert_select ".brand-mark", text: "AR"
    assert_select "footer", text: /Cook what you have\./
    assert_select "footer a[href=?]", "mailto:help@acme.test"
    assert_no_match(/\bStarter\b/, response.body)
  end

  test "sign-in pages" do
    get new_user_session_url

    assert_themed
    assert_select "p", text: "Sign in to Acme Recipes"
  end

  test "the admin and user app shells hand the name to React" do
    sign_in users(:one)
    [ "/admin", "/app" ].each do |path|
      get path

      assert_themed
      assert_match 'window.__app = {"name":"Acme Recipes","shortName":"AR"}', response.body
    end
  end

  test "the PWA manifest" do
    # Rendered directly: its route is off until a product turns on the PWA.
    manifest = JSON.parse(ApplicationController.render(template: "pwa/manifest", formats: :json, layout: false))
    assert_equal "Acme Recipes", manifest["name"]
    assert_equal "#0f766e", manifest["theme_color"]
  end

  test "emails" do
    user = users(:one)
    mail = UserMailer.with(user: user, token: "abc").admin_invite

    assert_equal "Your Acme Recipes admin account is ready", mail.subject
    assert_match "background:#0f766e; color:#ffffff;", mail.html_part&.body&.to_s || mail.body.to_s
  end
end
