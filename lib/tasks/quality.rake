desc "Run every test with coverage, plus RuboCop and Brakeman, and write quality/report.json"
task quality: :environment do
  report = QualityReport::Run.new.call

  puts
  report["checks"].each do |check|
    puts "#{check['status'] == 'pass' ? '✓' : '✗'} #{check['label']}: #{check['detail']}"
  end
  puts
  puts "Line-by-line coverage: coverage/index.html"
  puts "Wrote #{QualityReport::PATH}. Commit it with the change it tested."

  unless report["status"] == "passing"
    puts "\nQuality checks failed. Fix them before you commit."
    exit 1
  end
end
