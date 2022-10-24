class NiceHttp
  ######################################################
  # To add specific stats
  # The stats will be added to NiceHttp.stats[:specific]
  #
  # @param name [Symbol] name to group your specific stats
  # @param state [Symbol] state of the name supplied to group your specific stats
  # @param started [Time] when the process you want the stats started
  # @param finished [Time] when the process you want the stats finished
  # @param item [Object] (Optional) The item to be added to :items key to store all items in an array
  #
  # @example
  #   started = Time.now
  #   @http.send_request Requests::Customer.add_customer
  #   30.times do
  #      resp = @http.get(Requests::Customer.get_customer)
  #      break if resp.code == 200
  #      sleep 0.5
  #   end
  #   NiceHttp.add_stats(:customer, :create, started, Time.now)
  ######################################################
  def self.add_stats(name, state, started, finished, item = nil)
    self.stats[:specific] ||= {}
    self.stats[:specific][name] ||= { num: 0, started: started, finished: started, real_time_elapsed: 0, time_elapsed: { total: 0, maximum: 0, minimum: 100000, average: 0 } }
    self.stats[:specific][name][:num] += 1

    if started < self.stats[:specific][name][:finished]
      self.stats[:specific][name][:real_time_elapsed] += (finished - self.stats[:specific][name][:finished])
    else
      self.stats[:specific][name][:real_time_elapsed] += (finished - started)
    end
    self.stats[:specific][name][:finished] = finished

    time_elapsed = self.stats[:specific][name][:time_elapsed]
    time_elapsed[:total] += finished - started
    if time_elapsed[:maximum] < (finished - started)
      time_elapsed[:maximum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_maximum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_maximum] = Thread.current.name
      end
    end
    if time_elapsed[:minimum] > (finished - started)
      time_elapsed[:minimum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_minimum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_minimum] = Thread.current.name
      end
    end
    time_elapsed[:average] = time_elapsed[:total] / self.stats[:specific][name][:num]

    self.stats[:specific][name][state] ||= { num: 0, started: started, finished: started, real_time_elapsed: 0, time_elapsed: { total: 0, maximum: 0, minimum: 1000, average: 0 }, items: [] }
    self.stats[:specific][name][state][:num] += 1
    if started < self.stats[:specific][name][state][:finished]
      self.stats[:specific][name][state][:real_time_elapsed] += (finished - self.stats[:specific][name][state][:finished])
    else
      self.stats[:specific][name][state][:real_time_elapsed] += (finished - started)
    end

    self.stats[:specific][name][state][:finished] = finished

    self.stats[:specific][name][state][:items] << item unless item.nil? or self.stats[:specific][name][state][:items].include?(item)
    time_elapsed = self.stats[:specific][name][state][:time_elapsed]
    time_elapsed[:total] += finished - started
    if time_elapsed[:maximum] < (finished - started)
      time_elapsed[:maximum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_maximum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_maximum] = Thread.current.name
      end
    end
    if time_elapsed[:minimum] > (finished - started)
      time_elapsed[:minimum] = (finished - started)
      if !item.nil?
        time_elapsed[:item_minimum] = item
      elsif Thread.current.name.to_s != ""
        time_elapsed[:item_minimum] = Thread.current.name
      end
    end
    time_elapsed[:average] = time_elapsed[:total] / self.stats[:specific][name][state][:num]
  end
end
