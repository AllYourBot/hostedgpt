# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 7.1.3"
gem "sprockets-rails" # The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails" # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "turbo-rails", "~> 2.0.5"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 2.6.0"
gem "rack-cors"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem "redcarpet", "~> 3.6.0"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
gem "amatch", "~> 0.4.1" # enables fuzzy comparison of strings, a tool uses this
gem "rails_heroicon", "~> 2.2.0"
gem "ruby-openai", "~> 7.0.1"
gem "anthropic", "~> 0.1.0"
gem "tiktoken_ruby", "~> 0.0.6"
gem "solid_queue", "~> 0.2.1"
gem "name_of_person"
gem "actioncable-enhanced-postgresql-adapter" # longer paylaods w/ postgresql actioncable

gem "omniauth", "~> 2.1"
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-rails_csrf_protection", "~> 1.0.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
  gem "timecop"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "pry-rails"
  gem "standard"
  gem "ruby-lsp"
  gem "rubocop-rails"
  gem "rubocop-capybara"
  gem "rubocop-minitest"
  gem "dockerfile-rails", ">= 1.6"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "minitest-stub_any_instance"
end