module Sem
  class NameConverter
    def initialize(data)
      @tmp_obs_names = {}
      @tmp_lat_names = {}

      data.keys.each do |name|
        @tmp_obs_names[name.to_sym] = "obs#{@tmp_obs_names.length}"
      end
    end

    def to_tmp_names(data)
      @tmp_obs_names.each do |orig, tmp_name|
        data[tmp_name.to_sym] = data.delete(orig)
      end

      data
    end

    def to_tmp_name(orig)
      if @tmp_obs_names[orig.to_sym]
        @tmp_obs_names[orig.to_sym]
      elsif @tmp_lat_names[orig.to_sym]
        @tmp_lat_names[orig.to_sym]
      else
        @tmp_lat_names[orig.to_sym] = "lat#{@tmp_lat_names.length}"
      end
    end

    def to_orig_name(tmp_name)
      tmp_name.slice!('.') # 環境によって、Rが変数名に.を入れることがある
      if @tmp_obs_names.key(tmp_name)
        @tmp_obs_names.key(tmp_name)
      else
        @tmp_lat_names.key(tmp_name)
      end
    end
  end
end