module ZmProxy
  class Connection
    require 'ostruct'

    attr_accessor :id, :peer, :headers, :body, :started, :done, :buffer

    def initialize(peer)
      @id = Time.now.to_f.to_s
      @peer = OpenStruct.new(ip: peer[0].to_i, port: peer[1].to_i)
      @buffer = ''
      @headers = nil
      @body = ""
      @started = false
      @done = false
      @buffer = ''
      @url = ''
    end
  end
end
