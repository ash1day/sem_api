module Sem
  class Parser
    def initialize(name_converter)
      @name_converter = name_converter
    end

    # TODO: 切片?
    def parse(r_out_s)
      parsed = {}
      r_out_a = r_out_s.split("\n")

      parsed['latent_variables'] = _parse(r_out_a, :parse_vars,      'Latent',      1)
      parsed['regressions']      = _parse(r_out_a, :parse_vars,      'Regressions', 1)
      parsed['covariances']      = _parse(r_out_a, :parse_vars,      'Covariances', 1)
      parsed['variances']        = _parse(r_out_a, :parse_variances, 'Variances',   1)
      parsed['goodness_of_fit']  = _parse(r_out_a, :parse_fits,      'npar')

      parsed
    end

    # === private ===

    def _parse(r_out_a, parser_method_name, title, offset = 0)
      range = r_out_a.index_range(title, offset)
      return {} unless range
      send(parser_method_name, r_out_a[range])
    end

    #                    Estimate  Std.Err  Z-value  P(>|z|)   Std.lv  Std.all
    #   lat0 =~
    #     obs4              1.000                               1.414    0.786
    #     obs5              1.208    0.989    1.222    0.222    1.708    0.786
    #     obs6              1.209    0.952    1.270    0.204    1.710    0.810
    #     obs7              1.340    1.022    1.311    0.190    1.896    0.830
    def parse_vars(r_out_a)
      parsed_h = {}

      splited_r_out_a = split_into_columns(r_out_a)
      headers = splited_r_out_a.shift
      headers.shift

      var_name = ''

      splited_r_out_a.each do |row|
        if row.first.split(' ').length == 2
          # 左辺
          # 例 lat0 =~

          var_name = @name_converter.to_orig_name(row.first.split(' ').first.strip)
          parsed_h[var_name] = []
        else
          # 右辺
          # 例 obs1    0.384  0.206  1.868  0.062

          row_h = {name: @name_converter.to_orig_name(row.first)}

          row[1..-1].each_with_index { |str, i| row_h[headers[i]] = str }
          parsed_h[var_name].push(row_h)
        end
      end
      parsed_h
    end

    # 分散をパース
    #                    Estimate  Std.Err  Z-value  P(>|z|)   Std.lv  Std.all
    #     obs4              1.237    1.394    0.888    0.375    1.237    0.382
    #     obs5              1.808    2.037    0.888    0.375    1.808    0.383
    #     obs6              1.536    1.774    0.866    0.387    1.536    0.344
    #     obs7              1.625    1.930    0.842    0.400    1.625    0.311
    def parse_variances(r_out_a)
      parsed_h = {}
      splited_r_out_a = split_into_columns(r_out_a)
      headers = splited_r_out_a.shift
      headers.shift

      splited_r_out_a.each do |row|
        original_name = @name_converter.to_orig_name(row.shift)
        parsed_h[original_name] = {}
        row.each_with_index do |str, i|
          parsed_h[original_name][headers[i]] = str
        end
      end
      parsed_h
    end

    # 適合度をパース
    #               npar                fmin               chisq                  df
    #             26.000               0.461               1.842              40.000
    #             pvalue      baseline.chisq         baseline.df     baseline.pvalue
    #              1.000              17.622              55.000               1.000
    def parse_fits(r_out_a)
      fit_vars_a = r_out_a.map { |row| row.split }
      fit_vars_h = {}
      fit_vars_a.each_with_index do |row, row_key|
        next if row_key.even?
        row.each_with_index { |v, v_key| fit_vars_h[fit_vars_a[row_key - 1][v_key]] = v }
      end
      fit_vars_h
    end

    # column_names_sは以下のような文字列
    #                    Estimate  Std.Err  Z-value  P(>|z|)   Std.lv  Std.all
    # 例えば '  Std.Err' の文字数をそのカラムの長さとする
    def calc_column_length(column_names_s)
      column_length_a = []

      # 最初のカラムだけは空白の数を数える
      buffer = 2 # 最初のEstimateは前何文字からそのカラムなのか分からないので決めうち
      second_columns_head_index = column_names_s.index(/[^\s]/) - buffer
      column_length_a.push(second_columns_head_index)
      columns = column_names_s[second_columns_head_index..-1]

      loop do
        # 頭の空白の数をカウント
        head_non_space_index = columns.index(/[^\s]/)
        break if head_non_space_index.nil?
        columns.strip!

        # 最初に現れる空白でない文字列のカウント
        next_columns_head_index = columns.index(/\s/)
        next_columns_head_index ||= columns.length # 最後のカラム

        # 頭の空白と文字列を足してカラムの長さとする
        column_length_a.push(head_non_space_index + next_columns_head_index)
        break if next_columns_head_index == columns.length # 最後のカラム
        columns = columns[next_columns_head_index..-1]
      end

      column_length_a
    end

    # 全ての行をカラム長で分割する
    def split_into_columns(r_out_a)
      column_length_a = calc_column_length(r_out_a.first)

      r_out_a.map do |row|
        splited_row = []
        column_length_a.each do |columns_length|
          splited_row.push(row[0..(columns_length - 1)].strip)
          row = row[columns_length..-1]
        end
        splited_row
      end
    end
  end
end