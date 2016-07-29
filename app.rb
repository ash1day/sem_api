require 'sinatra/base'
require 'json'

require File.expand_path '../sem.rb', __FILE__

class App < Sinatra::Base
  include Sem

  post '/sem' do
    json = JSON.parse(request.body.read, symbolize_keys: true)
    return unless json[:nobs] && json[:model] && json[:S]

    File.open('./tmp/model.lav', 'w') { |file| file.write Sem.build_model_s(json[:model]) }
    File.open('./tmp/elems.lav', 'w') { |file| file.write Sem.build_elems(json[:S]) }

    result = `Rscript sem.r #{json[:nobs]}`

    result.to_json
  end
end
