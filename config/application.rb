require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsStub
  class Application < Rails::Application
    config.load_defaults 6.0

    # yarnのエラーメッセージ対処
    config.webpacker.check_yarn_integrity = false
  end
end
