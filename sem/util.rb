require 'matrix'

# index検索が面倒くさいのでArrayクラス拡張
class Array
  # ある文字列を含む行から始まる段落の行のレンジを返す
  def index_range(str, offset = 0)
    i = search_index(str)
    return false if i.nil?
    start_index = i + offset
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

class SetableMatrix < Matrix
  public :'[]=', :set_element, :set_component
end

def float_string?(str)
  Float(str)
  true
rescue ArgumentError
  false
end