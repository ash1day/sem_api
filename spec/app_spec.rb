require File.expand_path '../spec_helper.rb', __FILE__

describe 'App' do
  describe '/へのアクセス' do
    let(:params) do
      {
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
    end

    before { post '/sem', params }
    it '正常なレスポンスが返ること' do
      expect(last_response).to be_ok
    end
  end
end

