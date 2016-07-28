require 'sinatra/base'
require 'json'
require 'sem'

class App < Sinatra::Base
  include Sem

  post '/sem' do
    obj = JSON.parse(request.body.read, symbolize_keys: true)
    nobs  = obj[:nobs]
    model = obj[:model]
    s     = obj[:S]

    # alphaからmodel.lavを作成する
    model_s = Sem.build_model_s(alpha)
    File.open('./tmp/model.lav', 'w') { |file| file.write model_s }

    # Sからelemsを作成する
    elems = Sem.build_elems(s)
    File.open('./tmp/elems.lav', 'w') { |file| file.write elems }

    opts = nobs

    result = `Rscript sem.r #{opts}`

    {}.to_json
  end

  # post '/cov' do
  #   obj = JSON.parse(request.body.read, symbolize_keys: true)

  #   {
  #     # data: [[v for v in row] for row in numpy.cov(obj['data'])],
  #   }.to_json
  # end
end
