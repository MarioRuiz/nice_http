module NiceHttpManageResponse
  private

  def set_stats(hash)
    unless hash.key?(:num_requests)
      # to add to the end the previous keys so num_requests and time_elapsed come first
      keys = hash.keys
      hash.keys.each do |k|
        hash.delete(k)
      end

      hash[:num_requests] = 0
      hash[:started] = @start_time
      hash[:finished] = @start_time
      hash[:real_time_elapsed] = 0
      hash[:time_elapsed] = {
        total: 0,
        maximum: 0,
        minimum: 100000,
        average: 0,
      }

      # to add to the end the previous keys so num_requests and time_elapsed come first
      keys.each do |k|
        hash[k] = {}
      end
    end
    hash[:num_requests] += 1
    hash[:started] = hash[:finished] = @start_time if hash[:started].nil?

    if @start_time < hash[:finished]
      hash[:real_time_elapsed] += (@finish_time - hash[:finished])
    else
      hash[:real_time_elapsed] += (@finish_time - @start_time)
    end
    hash[:finished] = @finish_time

    hash[:time_elapsed][:total] += @response[:time_elapsed]
    hash[:time_elapsed][:maximum] = @response[:time_elapsed] if @response[:time_elapsed] > hash[:time_elapsed][:maximum]
    hash[:time_elapsed][:minimum] = @response[:time_elapsed] if @response[:time_elapsed] < hash[:time_elapsed][:minimum]
    hash[:time_elapsed][:average] = hash[:time_elapsed][:total] / hash[:num_requests]
  end
end
