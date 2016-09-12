require_relative 'util'
require_relative 'parser'

module Sem
  extend self

  def summary(obs_names, nobs, model, s)
    File.open('./tmp/model.lav', 'w') { |f| f.write Sem.build_model_s(model) }
    File.open('./tmp/elems.lav', 'w') do |f|
      f.puts s.flatten.join(' ')
      f.puts obs_names.join(' ')
    end

    r_out_str = `Rscript sem.r #{nobs}`
    puts r_out_str
    return if r_out_str.nil?

    parsed = parse_r_out(r_out_str)
    parsed = add_all_vars_names(parsed, obs_names)
    parsed = add_total_effects(parsed)
  end

  # Rからの結果の文字列をパース
  def parse_r_out(r_out_str)
    parsed_h = {}
    r_out_a = r_out_str.split("\n")

    parsed_h['latent_variables'] = Parser.parse(r_out_a, :parse_vars,      'Latent',      1)
    parsed_h['regressions']      = Parser.parse(r_out_a, :parse_vars,      'Regressions', 1)
    parsed_h['covariances']      = Parser.parse(r_out_a, :parse_vars,      'Covariances', 1)
    parsed_h['variances']        = Parser.parse(r_out_a, :parse_variances, 'Variances',   1)
    parsed_h['goodness_of_fit']  = Parser.parse(r_out_a, :parse_fits,      'npar')
    parsed_h
  end

  # Rで読み込むテキストファイル用にhash to str変換
  def build_model_s(model)
    model_str = ''

    Hash[model.map{ |k, v| [k.to_sym, v] }].each do |eq_key, eqs|
      op =
        case eq_key
        when :latent_variable then '=~'
        when :regression      then '~'
        when :covariance      then '~~'
        end

      eqs.each do |left_var, vars|
        model_str += "#{left_var} #{op} "
        vars.each_with_index do |var, key|
          model_str += ' + ' if key >= 1
          model_str += var
        end
        model_str += "\n"
      end
    end

    model_str
  end

  def add_all_vars_names(parsed, obs_names)
    parsed['names'] = obs_names + parsed['latent_variables'].keys
    parsed
  end

  def add_total_effects(parsed)
    names = parsed['names']
    mat = SetableMatrix.zero(names.length)

    parsed['latent_variables'].each do |lat, vars|
      y_to = names.index(lat)
      vars.each do |v|
        x_from = names.index(v[:name])
        mat[x_from, y_to] = v['Estimate'].to_f if v['Estimate']
      end
    end

    parsed['regressions'].each do |lat, vars|
      x_from = names.index(lat)
      vars.each do |v|
        y_to = names.index(v[:name])
        mat[x_from, y_to] = v['Estimate'].to_f if v['Estimate']
      end
    end

    parsed['total_effects'] = (Matrix.I(names.length) - mat).inv.to_a
    parsed
  end
end