require 'sinatra'
require 'sinatra/cross_origin'
require 'json'

require File.expand_path '../sem.rb', __FILE__

class App < Sinatra::Base
  register Sinatra::CrossOrigin

  before do
    cross_origin
  end

  post '/sem' do
    cross_origin
    payload = JSON.parse(request.body.read, symbolize_names: true)

    return unless payload[:nobs] && payload[:model] && payload[:S]
    sum = Sem.summary(payload[:nobs], payload[:model], payload[:S])

    sum.to_json
  end

  options '*' do
    response.headers['Allow'] = 'POST,OPTIONS'

    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'

    200
  end
end
