require File.expand_path '../spec_helper.rb', __FILE__

describe 'App' do
  describe 'Post /sem' do
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
      }.to_json
    end

    before { post '/sem', params, { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
    it '正常なレスポンスが返ること' do
      expect(last_response).to be_ok
      expect(last_response.body).to eq "{\"latent_variables\":{\"f6\":[{\"name\":\"v0\",\"Estimate\":\"1.000\",\"Std.Err\":\"\",\"Z-value\":\"\",\"P(>|z|)\":\"\",\"Std.lv\":\"0.894\",\"Std.all\":\"0.904\"},{\"name\":\"v1\",\"Estimate\":\"0.983\",\"Std.Err\":\"0.108\",\"Z-value\":\"9.122\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.879\",\"Std.all\":\"0.889\"},{\"name\":\"v2\",\"Estimate\":\"0.797\",\"Std.Err\":\"0.131\",\"Z-value\":\"6.109\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.713\",\"Std.all\":\"0.721\"},{\"name\":\"v3\",\"Estimate\":\"0.686\",\"Std.Err\":\"0.141\",\"Z-value\":\"4.873\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.613\",\"Std.all\":\"0.620\"}],\"f7\":[{\"name\":\"v4\",\"Estimate\":\"1.000\",\"Std.Err\":\"\",\"Z-value\":\"\",\"P(>|z|)\":\"\",\"Std.lv\":\"0.886\",\"Std.all\":\"0.896\"},{\"name\":\"v5\",\"Estimate\":\"0.937\",\"Std.Err\":\"0.119\",\"Z-value\":\"7.863\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.831\",\"Std.all\":\"0.840\"}]},\"regressions\":{\"f7\":[{\"name\":\"f6\",\"Estimate\":\"0.972\",\"Std.Err\":\"0.111\",\"Z-value\":\"8.790\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.981\",\"Std.all\":\"0.981\"}]},\"variances\":[{\"name\":\"v0\",\"Estimate\":\"0.180\",\"Std.Err\":\"0.054\",\"Z-value\":\"3.298\",\"P(>|z|)\":\"0.001\",\"Std.lv\":\"0.180\",\"Std.all\":\"0.184\"},{\"name\":\"v1\",\"Estimate\":\"0.206\",\"Std.Err\":\"0.058\",\"Z-value\":\"3.549\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.206\",\"Std.all\":\"0.210\"},{\"name\":\"v2\",\"Estimate\":\"0.471\",\"Std.Err\":\"0.105\",\"Z-value\":\"4.490\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.471\",\"Std.all\":\"0.481\"},{\"name\":\"v3\",\"Estimate\":\"0.603\",\"Std.Err\":\"0.130\",\"Z-value\":\"4.642\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.603\",\"Std.all\":\"0.616\"},{\"name\":\"v4\",\"Estimate\":\"0.193\",\"Std.Err\":\"0.065\",\"Z-value\":\"2.980\",\"P(>|z|)\":\"0.003\",\"Std.lv\":\"0.193\",\"Std.all\":\"0.197\"},{\"name\":\"v5\",\"Estimate\":\"0.288\",\"Std.Err\":\"0.075\",\"Z-value\":\"3.869\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"0.288\",\"Std.all\":\"0.295\"},{\"name\":\"f6\",\"Estimate\":\"0.799\",\"Std.Err\":\"0.202\",\"Z-value\":\"3.947\",\"P(>|z|)\":\"0.000\",\"Std.lv\":\"1.000\",\"Std.all\":\"1.000\"},{\"name\":\"f7\",\"Estimate\":\"0.030\",\"Std.Err\":\"0.057\",\"Z-value\":\"0.535\",\"P(>|z|)\":\"0.593\",\"Std.lv\":\"0.039\",\"Std.all\":\"0.039\"}],\"goodness_of_fit\":{\"npar\":\"13.000\",\"fmin\":\"0.510\",\"chisq\":\"47.937\",\"df\":\"8.000\",\"pvalue\":\"0.000\",\"baseline.chisq\":\"251.360\",\"baseline.df\":\"15.000\",\"baseline.pvalue\":\"0.000\",\"cfi\":\"0.831\",\"tli\":\"0.683\",\"nnfi\":\"0.683\",\"rfi\":\"0.642\",\"nfi\":\"0.809\",\"pnfi\":\"0.432\",\"ifi\":\"0.836\",\"rni\":\"0.831\",\"logl\":\"-295.397\",\"unrestricted.logl\":\"-271.428\",\"aic\":\"616.794\",\"bic\":\"640.846\",\"ntotal\":\"47.000\",\"bic2\":\"600.073\",\"rmsea\":\"0.326\",\"rmsea.ci.lower\":\"0.241\",\"rmsea.ci.upper\":\"0.418\",\"rmsea.pvalue\":\"0.000\",\"rmr\":\"0.073\",\"rmr_nomean\":\"0.073\",\"srmr\":\"0.075\",\"srmr_bentler\":\"0.075\",\"srmr_bentler_nomean\":\"0.075\",\"srmr_bollen\":\"0.075\",\"srmr_bollen_nomean\":\"0.075\",\"srmr_mplus\":\"0.075\",\"srmr_mplus_nomean\":\"0.075\",\"cn_05\":\"16.204\",\"cn_01\":\"20.697\",\"gfi\":\"0.766\",\"agfi\":\"0.385\",\"pgfi\":\"0.292\",\"mfi\":\"0.654\",\"ecvi\":\"1.573\"}}"
    end
  end
end

