module Sem
  class Result
    def initialize(parsed_r_out)
      @result = parsed_r_out
    end

    def add_all_vars_names(obs_names)
      @result['names'] = {}

      @result['names']['obs'] = obs_names
      @result['names']['lat'] = @result['latent_variables']&.keys&.sort
    end

    def add_total_effects
      total_effects = {}

      names = @result['names']['obs']
      names += @result['names']['lat'] unless @result['names']['lat'].empty?

      mat = SetableMatrix.zero(names.length)

      unless @result['latent_variables'].empty?
        @result['latent_variables'].each do |lat, vars|
          from = names.index(lat)
          vars.each do |v|
            to = names.index(v[:name])
            mat[to, from] = v['Estimate'].to_f if v['Estimate']
          end
        end
      end

      unless @result['regressions'].empty?
        @result['regressions'].each do |lat, vars|
          to = names.index(lat)
          vars.each do |v|
            from = names.index(v[:name])
            mat[to, from] = v['Estimate'].to_f if v['Estimate']
          end
        end
      end

      total_effects_a = ((Matrix.I(names.length) - mat).inv - Matrix.I(names.length)).to_a

      total_effects = {}
      names.each_with_index do |from, from_k|
        total_effects[from] = {}
        names.each_with_index do |to, to_k|
          total_effects[from][to] = total_effects_a[from_k][to_k]
        end
      end

      @result['total_effects'] = total_effects
    end

    def to_h
      @result
    end
  end
end