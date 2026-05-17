#!/usr/bin/env ruby
# Usage: rails runner scripts/create_fix_pr.rb <incident_id>
#
# This script helps create a PR to fix an incident from Datadog
# It uses the trace information stored in the incident record

incident_id = ARGV[0]

unless incident_id
  puts "Usage: rails runner scripts/create_fix_pr.rb <incident_id>"
  puts ""
  puts "Available incidents:"
  Incident.open.order(severity: :desc, created_at: :desc).limit(10).each do |inc|
    puts "  #{inc.id}. [#{inc.severity.upcase}] #{inc.source} - #{inc.http_method} #{inc.http_path}"
  end
  exit 1
end

incident = Incident.find(incident_id)

puts "=" * 80
puts "Creating PR for Incident ##{incident.id}"
puts "=" * 80
puts ""

# Display incident info
puts "📊 Incident Details:"
puts "   Title: #{incident.title}"
puts "   Severity: #{incident.severity.upcase}"
puts "   Endpoint: #{incident.http_method} #{incident.http_path}"
puts "   Status Code: #{incident.http_status}"
puts "   Duration: #{incident.duration_ms&.round(2)}ms"
puts "   Controller: #{incident.source}"
puts ""

# Suggested branch name
branch_name = incident.suggested_branch_name
puts "🌿 Suggested Branch: #{branch_name}"
puts ""

# Ask for confirmation
print "Create branch '#{branch_name}'? (y/n): "
response = STDIN.gets.chomp.downcase

if response == 'y'
  # Create branch
  system("git checkout -b #{branch_name}")
  puts "✓ Branch created"
  puts ""

  # Generate PR description
  pr_title = incident.suggested_pr_title
  pr_body = incident.pr_description

  # Save to file
  pr_file = "/tmp/pr_#{incident.id}.md"
  File.write(pr_file, pr_body)

  puts "📝 PR Details:"
  puts "   Title: #{pr_title}"
  puts "   Body saved to: #{pr_file}"
  puts ""

  puts "PR Description Preview:"
  puts "-" * 80
  puts pr_body
  puts "-" * 80
  puts ""

  puts "Next steps:"
  puts "  1. Make your code changes to fix the issue"
  puts "  2. Commit your changes: git commit -am 'Fix #{incident.http_status} error in #{incident.source}'"
  puts "  3. Push branch: git push origin #{branch_name}"
  puts "  4. Create PR: gh pr create --title \"#{pr_title}\" --body-file #{pr_file}"
  puts ""
  puts "Or run this now to create PR:"
  puts "  gh pr create --title \"#{pr_title}\" --body-file #{pr_file}"

else
  puts "❌ Cancelled"
  exit 0
end
