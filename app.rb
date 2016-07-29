require 'sinatra/base'
require 'json'

require File.expand_path '../sem.rb', __FILE__

class App < Sinatra::Base
  post '/sem' do
    content_type :json

    return unless params['nobs'] && params['model'] && params['S']

    sum = Sem.summary(params['nobs'], params['model'], params['S'])

    sum.to_json
  end
end
