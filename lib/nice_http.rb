class NiceHttp
  class << self
    attr_accessor :port
  end

  def self.reset!
    @port = 80
  end
  reset!

  def self.inherited(subclass)
    subclass.reset!
  end

  attr_reader :port

  def self.defaults=(par = {})
    @port = par[:port] if par.key?(:port)
  end

  def initialize(args = {})
    @port = self.class.port

    if args.is_a?(String)
      uri = URI.parse(args)
      @port = uri.port unless uri.port.nil?
    elsif args.is_a?(Hash) && !args.keys.empty?
      @port = args[:port] if args.keys.include?(:port)
    end

    # if @host.nil? or @host.to_s=="" or @port.nil? or @port.to_s==""
    #   message = "It was not possible to create the http connection!!!\n"
    #   message += "Wrong host or port, remember to supply http:// or https:// in case you specify an url to create the http connection, for example:\n"
    #   message += "http = NiceHttp.new('http://example.com')"
    #   raise message
    # end
  end
end

