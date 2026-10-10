require "test_helper"

# bin/sync-mobile-theme against a stand-in Expo app, without touching npm.
class SyncMobileThemeTest < ActiveSupport::TestCase
  setup do
    @mobile = Pathname(Dir.mktmpdir("mobile"))
    @mobile.join("src/constants").mkpath
    @mobile.join("package.json").write({ dependencies: { "expo" => "57", "@expo-google-fonts/inter" => "^0.4.2" } }.to_json)
  end

  teardown { FileUtils.rm_rf(@mobile) }

  def sync(*args)
    Open3.capture2e(Rails.root.join("bin/sync-mobile-theme").to_s, *args)
  end

  test "writes branding.ts from config/app.yml and lists the font packages to change" do
    output, status = sync(@mobile.to_s, "--no-install")

    assert status.success?, output
    assert_equal MobileBranding.new(AppConfig.load(Rails.root.join(AppConfig::PATH))).to_ts,
                 @mobile.join(MobileBranding::PATH).read
    assert_match "npm install @expo-google-fonts/outfit", output
    assert_match "npm uninstall @expo-google-fonts/inter", output
  end

  test "refuses a directory that isn't an Expo app" do
    output, status = sync(@mobile.join("nope").to_s, "--no-install")

    assert_not status.success?
    assert_match "No Expo app", output
  end
end
