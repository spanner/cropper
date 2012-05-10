# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/rails'
require "paperclip/matchers"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

require 'cropper'

RSpec.configure do |config|
  config.include Paperclip::Shoulda::Matchers
  config.use_transactional_fixtures = true
end
