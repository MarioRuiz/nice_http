class NiceHttp
  ######################################################
  # It will save the NiceHttp.stats on different files, each key of the hash in a different file.
  #
  # @param file_name [String] path and file name to be used to store the stats.
  #   In case no one supplied it will be used the value in NiceHttp.log and it will be saved on YAML format.
  #   In case extension is .yaml will be saved on YAML format.
  #   In case extension is .json will be saved on JSON format.
  #
  # @example
  #    NiceHttp.save_stats
  #    NiceHttp.save_stats('./stats/my_stats.yaml')
  #    NiceHttp.save_stats('./stats/my_stats.json')
  ######################################################
  def self.save_stats(file_name = "")
    if file_name == ""
      if self.log.is_a?(String)
        file_name = self.log
      else
        file_name = "./#{self.log_path}nice_http.log"
      end
    end
    require "fileutils"
    FileUtils.mkdir_p File.dirname(file_name)
    if file_name.match?(/\.json$/)
      require "json"
      self.stats.keys.each do |key|
        File.open("#{file_name.gsub(/.json$/, "_stats_")}#{key}.json", "w") { |file| file.write(self.stats[key].to_json) }
      end
    else
      require "yaml"
      self.stats.keys.each do |key|
        File.open("#{file_name.gsub(/.\w+$/, "_stats_")}#{key}.yaml", "w") { |file| file.write(self.stats[key].to_yaml) }
      end
    end
  end
end
