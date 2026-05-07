# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample projects
Project.find_or_create_by!(name: "Zero Downtime") do |project|
  project.description = "AI-Powered DevOps Automation Platform - Monitors production errors, creates tickets, generates code fixes, and submits PRs automatically."
end

puts "Seeded #{Project.count} project(s)"
