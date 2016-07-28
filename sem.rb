module Sem
  extend self

  def build_model_s(model)
    model_s = ''

    model.each do |eq_key, eqs|
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

  def build_elems(s)
    mat_str = ''
    s.each_with_index do |row, i|
      (0..i).each do |key|
        mat_str += row[key].to_s + ' '
      end
    end
    mat_str.strip
  end
end