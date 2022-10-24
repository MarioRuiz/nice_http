module NiceHttpUtils
  ##################################################
  # returns the seed for Basic authentication
  # @param user [String]
  # @param password [String]
  # @param strict [Boolean] (default: false) use strict_encode64 if true, if not encode64
  # @return [String] seed string to be used on Authorization key header on a get request
  ####################################################
  def self.basic_authentication(user:, password:, strict: false)
    require "base64"
    if strict
      seed = "Basic " + Base64.strict_encode64(user + ":" + password)
    else
      seed = "Basic " + Base64.encode64(user + ":" + password)
    end
    return seed
  end
end
