$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bundler/setup'
Bundler.setup

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'pry'
require 'html_surgeon'

RSpec.configure do |config|
  # some (optional) config here
end
