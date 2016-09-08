module Parser
  class << self
    def parse(r_out_a, parser_name, title, offset = 0)
      range = r_out_a.index_range(title, offset)
      return unless range
      send(parser_name, r_out_a[range])
    end

    def parse_vars(r_out_a)
      parsed_h = {}

      _r_out_a = r_out_a.map do |row|
        r = row.scan(/.{1,9}/).map(&:strip)
        r[0] = r[0] + r[1]
        r[1] = ''
        r
      end

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
      parsed_h = {}
      _r_out_a = r_out_a.map { |row| row.scan(/.{1,9}/).map(&:strip) }
      columns = _r_out_a.shift[2..-1]
      _r_out_a.each do |row|
        parsed_h[row.first] = {}
        row[2..-1].each_with_index do |str, i|
          parsed_h[row.first][columns[i]] = str
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
end