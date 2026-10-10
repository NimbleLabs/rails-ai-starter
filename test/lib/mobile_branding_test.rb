require "test_helper"

class MobileBrandingTest < ActiveSupport::TestCase
  def branding(theme = {}, **attributes)
    MobileBranding.new(AppConfig.new(attributes.merge(theme: theme)))
  end

  test "imports each font package once: body weights plus the heading weight" do
    ts = branding({ display_font: "Outfit", body_font: "Outfit" }).to_ts

    assert_equal 1, ts.scan("from '@expo-google-fonts/outfit'").size
    %w[Outfit_400Regular Outfit_500Medium Outfit_600SemiBold Outfit_700Bold Outfit_800ExtraBold].each { |name| assert_includes ts, "  #{name}," }
    assert_includes ts, "export const DisplayFont = 'Outfit_800ExtraBold';"
  end

  test "a separate heading font is its own package, at its heaviest weight" do
    mobile = branding({ display_font: "DM Serif Display", body_font: "Inter" })

    assert_equal %w[@expo-google-fonts/inter @expo-google-fonts/dm-serif-display], mobile.packages
    assert_equal "DMSerifDisplay_400Regular", mobile.display_family
    assert_equal({ "regular" => "Inter_400Regular", "medium" => "Inter_500Medium", "semibold" => "Inter_600SemiBold", "bold" => "Inter_700Bold" },
                 mobile.body_families)
  end

  test "carries the name, colors and corners" do
    ts = branding({ primary: "#0f766e", corners: "round" }, name: "Acme", short_name: "AC").to_ts

    assert_includes ts, "appName: 'Acme',"
    assert_includes ts, "markText: 'AC',"
    assert_includes ts, "light: { primary: '#0f766e', primaryHover: '#0d645e', onPrimary: '#ffffff'"
    assert_includes ts, "export const BrandRadii = { card: 24, control: 999, field: 16 } as const;"
    assert_includes ts, "  500: '#0f766e',"
  end

  test "quotes any name safely for TypeScript" do
    ts = branding({}, name: %(Bob's "Kitchen" \\ Co)).to_ts

    assert_includes ts, %(appName: 'Bob\\'s "Kitchen" \\\\ Co',)
  end
end
