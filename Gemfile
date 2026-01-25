source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for development/test
gem "sqlite3", ">= 2.1", group: [:development, :test]
# Use PostgreSQL for production
gem "pg", "~> 1.5", group: :production
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# CSS: Bootstrap 5.3 via CDN (see app/views/layouts/application.html.erb)
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Authentication
gem "devise", "~> 4.9"
# Authorization
gem "pundit", "~> 2.3"
# State machines for workflow
gem "state_machines-activerecord", "~> 0.9"
# PII encryption at field level
gem "attr_encrypted", "~> 4.0"
# Service layer result types
gem "dry-monads", "~> 1.6"
gem "dry-initializer", "~> 3.1"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deployment: AWS Elastic Beanstalk (see .ebextensions/)
# Kamal and Thruster gems removed - not needed for EB deployment

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
# AWS S3 for file storage in production
gem "aws-sdk-s3", require: false

# PDF generation for reports
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2"

# CSV generation (not included in Ruby 3.4+ by default)
gem "csv"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Test factories
  gem "factory_bot_rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Pin minitest to 5.x for Rails 8 compatibility
  gem "minitest", "~> 5.25"
end
