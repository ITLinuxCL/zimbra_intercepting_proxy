module ZimbraInterceptingProxy
  class Request
    require 'pp'
    
    attr_accessor :body, :headers, :parser
    
    def initialize(headers, body, parser)
      @body = body
      @headers = headers
      @parser = parser
    end
    
    def auth_request?
      @parser.http_method == "POST" && @parser.request_url == "/zimbra/" && @headers["Cookie"] = "ZM_TEST=true" && auth_request_params?
    end
    
    def auth_request_params?
      uri = Addressable::URI.parse("http://localhost/?#{@body}")
      uri.query_values["loginOp"] == "login"
    end
    
    def route_request?
      @parser.request_url == ZimbraInterceptingProxy::Config::ROUTE_URL
    end
    
    def user_token
      return auth_username if auth_request?
      return auth_zimbraId if route_request?
    end
    
    def auth_zimbraId
      headers["Auth-User"]
    end
    
    def auth_username
      uri = Addressable::URI.parse("http://localhost/?#{@body}")
      uri.query_values["username"]
    end
    
  end
end