# index検索が面倒くさいのでArrayクラス拡張
class Array
  # ある文字列を含む行から始まる段落の行のレンジを返す
  def index_range(str, buffer = 0)
    start_index = search_index(str) + buffer
    start_index..before_next_empty_line_index(start_index)
  end

  # ある文字列を含む行のインデックスを返す
  def search_index(str)
    index { |row| row.index(str) }
  end

  # indexの次に現れる空行の前の行のインデックスを返す
  def before_next_empty_line_index(index)
    empty_line_index = self[index..-1].index { |row| row.strip == '' }
    (empty_line_index.nil?) ? -1 : empty_line_index + index - 1
  end
end

module Sem
  extend self

  def summary(nobs, model, s)
    File.open('./tmp/model.lav', 'w') { |f| f.write Sem.build_model_s(model) }
    File.open('./tmp/elems.lav', 'w') { |f| f.write s.join(' '); f.puts } # 空行を入れる必要有

    r_out_str = exec(nobs)
    return if r_out_str.nil?

    parse(r_out_str)
  end

  # R実行結果を返す
  def exec(nobs)
    `Rscript sem.r #{nobs}`
  end

  # Rからの結果の文字列をパース
  def parse(r_out_str)
    parsed_h = {}
    r_out_a = r_out_str.split("\n")

    lantent_range     = r_out_a.index_range('Latent', 1)
    regressions_range = r_out_a.index_range('Regressions', 1)
    variances_range   = r_out_a.index_range('Variances', 1)
    fits_range        = r_out_a.index_range('npar')

    parsed_h['latent_variables'] = parse_vars(r_out_a[lantent_range])
    parsed_h['regressions']      = parse_vars(r_out_a[regressions_range])
    parsed_h['variances']        = parse_variances(r_out_a[variances_range])
    parsed_h['goodness_of_fit']  = parse_fits(r_out_a[fits_range])
    parsed_h
  end

  def parse_vars(r_out_a)
    parsed_h = {}
    _r_out_a = r_out_a.map { |row| row.scan(/.{1,9}/).map(&:strip) }
    columns = _r_out_a.shift[2..-1]
    var_name = ''
    _r_out_a.each do |row|
      if row[1..-1].all? { |str| str == '' }
        var_name = row.first.split(' ').first.strip
        parsed_h[var_name] = []
      else
        row_h = {name: row.first}
        row[2..-1].each_with_index do |str, i|
          row_h[columns[i]] = str
        end
        parsed_h[var_name].push(row_h)
      end
    end
    parsed_h
  end

  def parse_variances(r_out_a)
    parsed_a = []
    _r_out_a = r_out_a.map { |row| row.scan(/.{1,9}/).map(&:strip) }
    columns = _r_out_a.shift[2..-1]
    _r_out_a.each do |row|
      row_h = {name: row.first}
      row[2..-1].each_with_index do |str, i|
        row_h[columns[i]] = str
      end
      parsed_a.push(row_h)
    end
    parsed_a
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

  # Rで読み込むテキストファイル用にhash to str変換
  def build_model_s(model)
    model_str = ''

    Hash[model.map{ |k, v| [k.to_sym, v] }].each do |eq_key, eqs|
      op =
        case eq_key
        when :latent_variable then :=~
        when :regression      then :~
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
end