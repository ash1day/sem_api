module Sem
  extend self

  def exec(nobs)
    out = `Rscript sem.r #{nobs}`
    out_a = out.split("\n")[41..-1].map { |row| row.split }

    vars = {}
    out_a.each_with_index do |row, row_key|
      next if row_key.even?
      row.each_with_index { |v, v_key| vars[out_a[row_key - 1][v_key]] = v }
    end
    vars
  end

  def summary(nobs, model, s)
    File.open('./tmp/model.lav', 'w') { |f| f.write Sem.build_model_s(model) }
    File.open('./tmp/elems.lav', 'w') { |f| f.write s.join(' '); f.puts } # 空行を入れる必要有

    exec(nobs)
  end

  def build_model_s(model)
    model_s = ''

    Hash[model.map{ |k, v| [k.to_sym, v] }].each do |eq_key, eqs|
      op =
        case eq_key
        when :latent_variable then :=~
        when :regression      then :~
        end

      eqs.each do |left_var, vars|
        model_s += "#{left_var} #{op} "
        vars.each_with_index do |var, key|
          model_s += ' + ' if key >= 1
          model_s += var
        end
        model_s += "\n"
      end
    end

    model_s
  end
end