class NiceHttp
  ######################################################
  # If inheriting from NiceHttp class
  ######################################################
  def self.inherited(subclass)
    subclass.reset!
  end
end
