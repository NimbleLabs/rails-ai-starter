require "open3"

# Drawing the share card's PNG in a test needs care on a Mac.
#
# Parallel test workers are forked from a process that is already running threads, and macOS kills a forked
# child that starts its font system, which libvips uses to draw text. The worker dies mid-test and the run
# hangs waiting for it. So tests run BrandArtwork.rasterize, unchanged, in a fresh Ruby process (spawned, not
# forked), where it starts normally; and nothing here loads libvips into the test process itself. Production
# servers are Linux and never hit this.
module BrandArtworkRasterizing
  SCRIPT = "STDOUT.binmode; STDOUT.write(BrandArtwork.rasterize(STDIN.read))".freeze
  PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b.freeze

  def rasterize_in_fresh_process(svg)
    png, error, status = Open3.capture3(
      RbConfig.ruby, "-rbundler/setup", "-r", Rails.root.join("app/services/brand_artwork.rb").to_s, "-e", SCRIPT,
      stdin_data: svg, binmode: true, chdir: Rails.root.to_s
    )
    raise "BrandArtwork.rasterize failed: #{error}" unless status.success?

    png
  end

  # Runs the block with BrandArtwork.rasterize going through a fresh process.
  def with_fresh_process_rasterizer(&block)
    BrandArtwork.stub(:rasterize, ->(svg) { rasterize_in_fresh_process(svg) }, &block)
  end

  # Width and height from the PNG's header, so the test process never needs an image library.
  def png_size(png)
    assert_equal PNG_SIGNATURE, png.b.byteslice(0, 8), "expected a PNG"
    png.b.byteslice(16, 8).unpack("NN")
  end
end
