require 'daru'

require_relative 'name_converter'
require_relative 'parser'
require_relative 'result'
require_relative 'util'

module Sem
  extend self

  def summary(model_h, data)
    data = Hash[data.map { |k,v| [k, v.map(&:to_i)] }] # valuesがstringで来た時対策

    @name_converter = NameConverter.new(data)
    data = @name_converter.to_tmp_names(data)

    model_s = build_model_s(model_h)
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

    parser = Parser.new(@name_converter)

    persed = parser.parse(r_out_str)
    result = Result.new(persed)

    required_orig_obs_names = required_obs_names.map { |n| @name_converter.to_orig_name(n.to_s) }.sort
    result.add_all_vars_names(required_orig_obs_names)
    result.add_total_effects()

    result.to_h
  end

  # === private ===

  # 共分散行列を計算
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
        # when :intercept       then '~1'
        end

      eqs.each do |left_var, vars|
        model_str += "#{@name_converter.to_tmp_name(left_var)} #{op} "
        vars.each_with_index do |var, key|
          model_str += ' + ' if key >= 1
          model_str += "#{@name_converter.to_tmp_name(var)}"
        end
        model_str += "\n"
      end
    end

    model_str
  end

  # モデルに含まれた観測変数名群をArrayで返す
  def get_required_obs_names(model_s)
    model_s.scan(/obs[0-9]+/).uniq.sort { |a, b| a[3..-1].to_i <=> b[3..-1].to_i }
  end

  # 計算に必要なデータだけをデータから抜き出しHashで返す
  def extract_required_columns(data, required_obs_names)
    result = {}
    required_obs_names.each do |obs_name|
      result[obs_name.to_sym] = data[obs_name.to_sym]
    end
    result
  end
end