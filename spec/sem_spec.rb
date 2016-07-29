require File.expand_path '../spec_helper.rb', __FILE__

describe Sem do
  describe 'build_model' do
    let(:model_s) { Sem.build_model_s(model) }
    context do
      let(:model) do
        {
          latent_variable: {
            f6: ['v0', 'v1', 'v2', 'v3'],
            f7: ['v4', 'v5']
          },
          regression: {
            f7: ['f6']
          }
        }
      end

      it do
        expect(model_s).to eq "f6 =~ v0 + v1 + v2 + v3\nf7 =~ v4 + v5\nf7 ~ f6\n"
      end
    end
  end
end