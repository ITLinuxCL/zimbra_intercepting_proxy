module ZimbraInterceptingProxy
  class Connection

    attr_accessor :headers, :body, :started, :done, :buffer

    def initialize
      @headers = nil
      @body = ""
      @started = false
      @done = false
      @buffer = ''
    end

  end
end