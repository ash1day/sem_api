require 'sinatra/base'
require 'json'

require File.expand_path '../sem.rb', __FILE__

class App < Sinatra::Base
  post '/sem' do
    payload = JSON.parse(request.body.read, symbolize_names: true)

    return unless payload[:nobs] && payload[:model] && payload[:S]
    sum = Sem.summary(payload[:nobs], payload[:model], payload[:S])

    sum.to_json
  end
end
