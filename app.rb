require 'sinatra'
require 'sinatra/cross_origin'
require 'json'

require_relative 'sem/sem'

class App < Sinatra::Base
  register Sinatra::CrossOrigin

  before do
    cross_origin
  end

  post '/sem' do
    cross_origin
    json = JSON.parse(request.body.read, symbolize_names: true)
    return unless valid_json?(json)

    sum = Sem.summary(json[:model], json[:data])
    sum.to_json
  end

  options '*' do
    response.headers['Allow'] = 'POST,OPTIONS'

    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'

    200
  end

  private

  def valid_json?(json)
    return json[:model] && json[:data]
  end
end
