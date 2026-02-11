# Feature Workflow Tasks
# Pull features from production nimblelabs.com API and manage development workflow

require "net/http"
require "json"
require "uri"

namespace :feature do
  def api_token
    ENV["STARTER_API_TOKEN"] || raise("Missing STARTER_API_TOKEN environment variable")
  end

  def api_url
    ENV["STARTER_API_URL"] || "https://yourdomainhere.com"
  end

  def api_request(method, path, body = nil)
    uri = URI.parse("#{api_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = case method
    when :get
      Net::HTTP::Get.new(uri.request_uri)
    when :patch
      Net::HTTP::Patch.new(uri.request_uri)
    else
      raise "Unsupported method: #{method}"
    end

    request["x-api-token"] = api_token
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    if body
      request.body = body.to_json
    end

    response = http.request(request)

    case response.code.to_i
    when 200..299
      JSON.parse(response.body) rescue {}
    when 401
      raise "Unauthorized: Invalid API token"
    when 404
      raise "Not found: #{path}"
    else
      raise "API error (#{response.code}): #{response.body}"
    end
  end

  def current_branch
    `git rev-parse --abbrev-ref HEAD`.strip
  end

  def feature_slug_from_branch
    branch = current_branch
    if branch.start_with?("feature/")
      branch.sub("feature/", "")
    else
      nil
    end
  end

  def format_feature(feature)
    puts "\n#{"=" * 60}"
    puts "Feature: #{feature["title"]}"
    puts "Slug:    #{feature["slug"]}"
    puts "Status:  #{feature["status"]}"
    puts "Priority: #{feature["priority"]}"
    puts "Area:    #{feature["area"]}" if feature["area"].present?
    puts "#{"=" * 60}"

    if feature["description"].present?
      puts "\nDescription:"
      puts feature["description"]
    end

    if feature["acceptance_criteria"].present?
      puts "\nAcceptance Criteria:"
      puts feature["acceptance_criteria"]
    end

    if feature["plan"].present?
      puts "\nPlan:"
      puts feature["plan"]
    end

    if feature["started_at"].present?
      puts "\nStarted: #{feature["started_at"]}"
    end

    if feature["completed_at"].present?
      puts "Completed: #{feature["completed_at"]}"
    end

    puts ""
  end

  desc "List planned features from production"
  task list: :environment do
    puts "Fetching features from #{api_url}..."
    features = api_request(:get, "/features.json")

    planned = features.select { |f| f["status"] == "planned" }

    if planned.empty?
      puts "No planned features found."
    else
      puts "\nPlanned Features:"
      puts "-" * 60
      planned.each do |feature|
        priority_icon = case feature["priority"]
        when "critical" then "[!]"
        when "high" then "[H]"
        when "medium" then "[M]"
        when "low" then "[L]"
        else "[ ]"
        end
        puts "#{priority_icon} #{feature["slug"].ljust(40)} #{feature["title"]}"
      end
      puts "-" * 60
      puts "Total: #{planned.count} planned features"
      puts "\nUse `rake feature:show[slug]` to see details"
      puts "Use `rake feature:start[slug]` to start working on a feature"
    end
  end

  desc "Show details for a specific feature"
  task :show, [ :slug ] => :environment do |t, args|
    slug = args[:slug]
    raise "Usage: rake feature:show[slug]" unless slug.present?

    puts "Fetching feature '#{slug}' from #{api_url}..."
    feature = api_request(:get, "/features/#{slug}.json")
    format_feature(feature)
  end

  desc "Start working on a feature"
  task :start, [ :slug ] => :environment do |t, args|
    slug = args[:slug]
    raise "Usage: rake feature:start[slug]" unless slug.present?

    # Check for uncommitted changes
    unless `git status --porcelain`.strip.empty?
      puts "Warning: You have uncommitted changes. Please commit or stash them first."
      print "Continue anyway? (y/N): "
      response = $stdin.gets.chomp.downcase
      unless response == "y"
        puts "Aborted."
        next
      end
    end

    puts "Fetching feature '#{slug}' from #{api_url}..."
    feature = api_request(:get, "/features/#{slug}.json")

    if feature["status"] == "in_progress"
      puts "Feature is already in progress!"
      format_feature(feature)
      next
    end

    if feature["status"] == "completed"
      puts "Feature is already completed!"
      format_feature(feature)
      next
    end

    # Create feature branch
    branch_name = "feature/#{slug}"
    puts "\nCreating branch: #{branch_name}"

    # Check if branch already exists
    existing_branches = `git branch --list #{branch_name}`.strip
    if existing_branches.present?
      puts "Branch #{branch_name} already exists. Checking out..."
      system("git checkout #{branch_name}")
    else
      system("git checkout -b #{branch_name}")
    end

    # Update feature status to in_progress
    puts "\nUpdating feature status to 'in_progress'..."
    updated = api_request(:patch, "/features/#{slug}.json", {
      feature: {
        status: "in_progress",
        started_at: Time.current.iso8601
      }
    })

    puts "Feature status updated!"
    format_feature(updated)

    puts "Ready to work on: #{feature["title"]}"
    puts "Branch: #{branch_name}"
  end

  desc "Complete current feature"
  task complete: :environment do
    slug = feature_slug_from_branch

    unless slug
      puts "Error: Not on a feature branch."
      puts "Current branch: #{current_branch}"
      puts "Feature branches should be named: feature/<slug>"
      next
    end

    puts "Fetching feature '#{slug}' from #{api_url}..."
    feature = api_request(:get, "/features/#{slug}.json")

    if feature["status"] == "completed"
      puts "Feature is already completed!"
      format_feature(feature)
      next
    end

    # Update feature status to completed
    puts "\nUpdating feature status to 'completed'..."
    updated = api_request(:patch, "/features/#{slug}.json", {
      feature: {
        status: "completed",
        completed_at: Time.current.iso8601
      }
    })

    puts "Feature completed!"
    format_feature(updated)

    # Prompt for PR creation
    print "\nCreate a pull request? (y/N): "
    response = $stdin.gets.chomp.downcase
    if response == "y"
      puts "\nPushing branch to remote..."
      system("git push -u origin #{current_branch}")

      puts "\nOpening PR creation..."
      system("gh pr create --web")
    end
  end

  desc "Show current feature being worked on"
  task current: :environment do
    slug = feature_slug_from_branch

    unless slug
      puts "Not on a feature branch."
      puts "Current branch: #{current_branch}"
      puts "\nUse `rake feature:list` to see available features"
      next
    end

    puts "Fetching feature '#{slug}' from #{api_url}..."
    feature = api_request(:get, "/features/#{slug}.json")
    format_feature(feature)
  end
end
