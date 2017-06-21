module ZimbraInterceptingProxy
  class Connection

    attr_accessor :headers, :body, :started, :done, :buffer

    def initialize
      @headers = nil
      @body = ""
      @started = false
      @done = false
      @buffer = ''
      @url = ''
    end

    def set_backend_request(data, backend)
      parsed_data = data.split(/\r\n/)
      request = parsed_data[0]
      begin
        _method, request_path, _http_version = request.split(/\s+/)
        return data unless request_path =~ /^\//
        request_path = "backend[:path]#{request_path}"
        request = [_method, request_path, _http_version].join(' ')
        parsed_data[0] = request
        data = parsed_data.join('\r\n')
      rescue Exception => e
        ZimbraInterceptingProxy::Debug.logger "connection.set_backend_request: #{e}"
      end

      return data
    end
  end
end
