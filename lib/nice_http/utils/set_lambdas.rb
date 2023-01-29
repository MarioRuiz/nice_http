module NiceHttpUtils
  ##################################################
  # It will set all lambdas in data hash
  # @param data [Hash]
  # @param data_orig [Hash]
  # @return [Hash] the data hash with all lambdas set
  ####################################################
  def self.set_lambdas(data, data_orig)
    data = data.dup
    data_orig = data_orig.dup unless data_orig.nil?
    
    data.each do |k, v|
      if v.is_a?(Proc)
        data_kv = v.call
        if data_kv.nil?
          data.delete(k) unless data_orig.is_a?(Hash) and data_orig.key?(k)
        else
          data[k] = data_kv
        end
      elsif v.is_a?(Hash)
        data[k] = set_lambdas(v, data_orig[k])
      elsif v.is_a?(Array)
        v.each.with_index do |v2, i|
            if data_orig.key?(k) and data_orig[k].is_a?(Array) and data_orig[k].size > i
                data[k][i] = set_lambdas(v2, data_orig[k][i])
            else
                data[k][i] = set_lambdas(v2, nil)
            end
        end
      else
        data[k] = v
      end
    end
    data = data_orig.nice_merge(data) unless data_orig.nil?
    return data
  end
end
