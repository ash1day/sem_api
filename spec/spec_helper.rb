# spec/spec_helper.rb
require 'rack/test'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() App.new end
end

RSpec.configure { |c| c.include RSpecMixin }