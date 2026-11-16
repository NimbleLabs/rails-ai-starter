namespace :brand do
  desc "Draw public/favicon.svg, favicon.png and og-image.png from config/app.yml (needs libvips; commit them)"
  task images: :environment do
    BrandArtwork.new.write.each { |path| puts "Wrote #{Pathname(path).relative_path_from(Rails.root)}" }
    puts "Commit them. Rerun this after changing config/app.yml, or replace the files with designed ones."
  end
end
