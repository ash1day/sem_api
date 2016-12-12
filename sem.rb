require 'daru'
require_relative 'util'

module Sem
  extend self

  @@cached_obs_names = {}
  @@cached_lat_names = {}

  def summary(model_h, obs_names, nobs, cov, data)
    data = Hash[data.map { |k,v| [k, v.map(&:to_i)] }] # valuesがstringで来た時対策
    cache_names(data) # dataのkeyが書き換わる副作用あり

    model_s = Sem.build_model_s(model_h)
    required_obs_names = get_required_obs_names(model_s)
    return if required_obs_names.empty?
    data = extract_required_columns(data, required_obs_names)

    cov = calc_cov(data, required_obs_names)
    nobs = data.first.length

    File.open('./tmp/model.lav', 'w') { |f| f.write model_s }
    File.open('./tmp/elems.lav', 'w') do |f|
      f.puts cov.flatten.join(' ')
      f.puts required_obs_names.join(' ')
    end

    r_out_str = `Rscript sem.r #{nobs}`
    puts r_out_str
    return if r_out_str.nil?

    parsed = parse_r_out(r_out_str)
    parsed = add_all_vars_names(parsed, required_obs_names)
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

  # TODO: 切片?
  # Rからの結果の文字列をパース
  def parse_r_out(r_out_str)
    parsed_h = {}
    r_out_a = r_out_str.split("\n")

    parsed_h['latent_variables'] = parse(r_out_a, :parse_vars,      'Latent',      1)
    parsed_h['regressions']      = parse(r_out_a, :parse_vars,      'Regressions', 1)
    parsed_h['covariances']      = parse(r_out_a, :parse_vars,      'Covariances', 1)
    parsed_h['variances']        = parse(r_out_a, :parse_variances, 'Variances',   1)
    parsed_h['goodness_of_fit']  = parse(r_out_a, :parse_fits,      'npar')
    parsed_h
  end

  # TODO: 切片
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
        model_str += "#{to_tmp_name(left_var)} #{op} "
        vars.each_with_index do |var, key|
          model_str += ' + ' if key >= 1
          model_str += "#{to_tmp_name(var)}"
        end
        model_str += "\n"
      end
    end

    model_str
  end

  # model_sに含まれた観測変数名を配列で返す
  def get_required_obs_names(model_s)
    model_s.scan(/obs[0-9]+/).uniq.sort { |a, b| a[3..-1].to_i <=> b[3..-1].to_i }
  end

  def extract_required_columns(data, required_obs_names)
    result = {}
    required_obs_names.each do |obs_name|
      result[obs_name.to_sym] = data[obs_name.to_sym]
    end
    result
  end

  def add_all_vars_names(parsed, obs_names)
    parsed['names'] = {}

    # javascript側のsortと挙動が違う場合があるので注意
    parsed['names']['obs'] = obs_names.map { |n| to_original_name(n.to_s) }.sort
    parsed['names']['lat'] = parsed['latent_variables']&.keys&.sort
    parsed
  end

  def add_total_effects(parsed)
    total_effects = {}

    names = parsed['names']['obs']
    names += parsed['names']['lat'] unless parsed['names']['lat'].empty?

    mat = SetableMatrix.zero(names.length)

    unless parsed['latent_variables'].empty?
      parsed['latent_variables'].each do |lat, vars|
        from = names.index(lat)
        vars.each do |v|
          to = names.index(v[:name])
          mat[to, from] = v['Estimate'].to_f if v['Estimate']
        end
      end
    end

    unless parsed['regressions'].empty?
      parsed['regressions'].each do |lat, vars|
        to = names.index(lat)
        vars.each do |v|
          from = names.index(v[:name])
          mat[to, from] = v['Estimate'].to_f if v['Estimate']
        end
      end
    end

    total_effects['order'] = names
    total_effects['values'] = ((Matrix.I(names.length) - mat).inv - Matrix.I(names.length)).to_a
    parsed['total_effects'] = total_effects
    parsed
  end

  ## cache_names

  def cache_names(data)
    @@cached_obs_names = {}
    @@cached_lat_names = {}

    data.each do |original_name, v|
      @@cached_obs_names[original_name.to_sym] = "obs#{@@cached_obs_names.length}"
    end

    @@cached_obs_names.each do |original_name, tmp_name|
      data[tmp_name.to_sym] = data.delete(original_name)
    end
  end

  def to_tmp_name(original_name)
    if @@cached_obs_names[original_name.to_sym]
      @@cached_obs_names[original_name.to_sym]
    elsif @@cached_lat_names[original_name.to_sym]
      @@cached_lat_names[original_name.to_sym]
    else
      @@cached_lat_names[original_name.to_sym] = "lat#{@@cached_lat_names.length}"
    end
  end

  def to_original_name(cached_name)
    cached_name.slice!('.')
    if @@cached_obs_names.key(cached_name)
      @@cached_obs_names.key(cached_name)
    else
      @@cached_lat_names.key(cached_name)
    end
  end

  ## Parsers

  def parse(r_out_a, parser_name, title, offset = 0)
    range = r_out_a.index_range(title, offset)
    return {} unless range
    send(parser_name, r_out_a[range])
  end

  def parse_vars(r_out_a)
    parsed_h = {}
    _r_out_a = r_out_a.map { |row| row.split(' ').map(&:strip) }
    headers = _r_out_a.shift
    var_name = ''

    _r_out_a.each do |row|
      unless float_string?(row[1])
        # 左辺
        # 例 lat0 =~

        var_name = to_original_name(row.first.split(' ').first.strip)
        parsed_h[var_name] = []
      else
        # 右辺
        # 例 obs1    0.384  0.206  1.868  0.062

        row_h = {name: to_original_name(row.first)}
        row[1..-1].each_with_index do |str, i|
          row_h[headers[i]] = str
        end
        parsed_h[var_name].push(row_h)
      end
    end
    parsed_h
  end

  def parse_variances(r_out_a)
    parsed_h = {}
    _r_out_a = r_out_a.map { |row| row.split(' ').map(&:strip) }
    headers = _r_out_a.shift

    _r_out_a.each do |row|
      original_name = to_original_name(row.shift)
      parsed_h[original_name] = {}
      row.each_with_index do |str, i|
        parsed_h[original_name][headers[i]] = str
      end
    end
    parsed_h
  end

  # 適合度をパース
  def parse_fits(r_out_a)
    fit_vars_a = r_out_a.map { |row| row.split }
    fit_vars_h = {}
    fit_vars_a.each_with_index do |row, row_key|
      next if row_key.even?
      row.each_with_index { |v, v_key| fit_vars_h[fit_vars_a[row_key - 1][v_key]] = v }
    end
    fit_vars_h
  end
end