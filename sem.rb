require 'daru'
require_relative 'util'
require_relative 'parser'

module Sem
  extend self

  def summary(model, obs_names, nobs, cov, data)
    if data
      obs_names = data.keys
      cov = calc_cov(data, obs_names)
      nobs = data.first.length
    end

    File.open('./tmp/model.lav', 'w') { |f| f.write Sem.build_model_s(model) }
    File.open('./tmp/elems.lav', 'w') do |f|
      f.puts cov.flatten.join(' ')
      f.puts obs_names.join(' ')
    end

    r_out_str = `Rscript sem.r #{nobs}`
    puts r_out_str
    return if r_out_str.nil?

    parsed = parse_r_out(r_out_str)
    parsed = add_all_vars_names(parsed, obs_names)
    parsed = add_total_effects(parsed)
  end

  def calc_cov(data, obs_names)
    df = Daru::DataFrame.new(data, order: obs_names.map(&:to_sym))
    cov = Array.new(obs_names.length) { [] }

    # 行列の下三角だけを配列に
    c1 = 0
    df.cov.each_row do |row|
      c2 = 0
      row.to_a.each do |n|
        break if c2 > c1

        cov[c1].push(n)
        c2 += 1
      end
      c1 += 1
    end

    cov
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
    # javascript側のsortと挙動が違う場合があるので注意
    parsed['names'] = (obs_names.map(&:to_s) + parsed['latent_variables'].keys).sort
    parsed
  end

  def add_total_effects(parsed)
    names = parsed['names']
    mat = SetableMatrix.zero(names.length)

    parsed['latent_variables'].each do |lat, vars|
      from = names.index(lat)
      vars.each do |v|
        to = names.index(v[:name])
        mat[to, from] = v['Estimate'].to_f if v['Estimate']
      end
    end

    parsed['regressions'].each do |lat, vars|
      to = names.index(lat)
      vars.each do |v|
        from = names.index(v[:name])
        mat[to, from] = v['Estimate'].to_f if v['Estimate']
      end
    end

    parsed['total_effects'] = ((Matrix.I(names.length) - mat).inv - Matrix.I(names.length)).to_a
    parsed
  end
end