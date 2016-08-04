require 'net/https'
require 'json'

uri = URI.parse('https://sharp-kare-3927.arukascloud.io/sem')
http = Net::HTTP.new(uri.host, uri.port)

http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

data = {
  nobs: 47,
  S: [1.0, 0.7731109, 1.0, 0.715525, 0.7227997, 1.0, 0.6341241, 0.4515933, 0.2321334, 1.0, 0.7394903, 0.8526245, 0.5787253, 0.5881328, 1.0, 0.8100869, 0.6718607, 0.478518, 0.6095649, 0.7523879, 1.0],
  model: {
    latent_variable: {
      f6: ['v0', 'v1', 'v2', 'v3'],
      f7: ['v4', 'v5']
    },
    regression: {
      f7: ['f6']
    }
  }
}

req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
req.body = data.to_json

res = http.request(req)

p res