module ZimbraInterceptingProxy
  class Request
    require 'pp'

    attr_accessor :body, :headers, :parser
    attr_reader :zimbra_url_path

    def initialize(connection, parser = nil)
      @body = connection.body
      @headers = connection.headers
      if @headers["X-Forwarded-For"]
        @headers["X-Forwarded-For"] = @headers["X-Forwarded-For"].split(',').first
      end
      @cookies = cookies_to_hash @headers['Cookie']
      @parser = parser
    end

    def auth_request?
      default_auth_request? || zco_auth_request?
    end

    def logged_user_request?
      !@cookies.nil? && !@cookies['ZM_AUTH_TOKEN'].nil?
    end

    # This is the post Auth request sent by Webmail, ActiveSync and POP and IMAP
    def default_auth_request?
      @parser.http_method == "POST"  && @headers["Cookie"] =~ /ZM_TEST=true/ && auth_request_params?
    end

    def set_host_header!(mailbox_hostname, mailbox_port)
      @headers['Host'] = "#{mailbox_hostname}:#{mailbox_port}"
    end

    def set_zimbra_url_path!(path = '')
      @zimbra_url_path = "#{path}#{@parser.request_url}"
      @parser.request_url = @zimbra_url_path
    end

    def zco_auth_request?
      @parser.http_method == "POST" && @parser.request_url == "/service/soap/AuthRequest" && @headers["User-Agent"].match(/Zimbra-ZCO/)
    end


    def auth_request_params?
      uri = Addressable::URI.parse("http://localhost/?#{@body}")
      uri.query_values["loginOp"] == "login"
    end

    def cookies_to_hash(cookie_header)
      return cookie_header if cookie_header.nil?
      cookies = {}
      cookie_header.split('; ').each do |cookie|
        name, value = cookie.split('=')
        cookies[name] = value
      end
      return cookies
    end

    def route_request?
      @parser.request_url == ZimbraInterceptingProxy::Config::ROUTE_URL
    end

    def port
      return ZimbraInterceptingProxy::Config::ROUTE_REQUEST_PORT if route_request?
      return ZimbraInterceptingProxy::Config::AUTH_REQUEST_PORT if auth_request?
    end

    def user_token
      return auth_username if default_auth_request?
      return auth_zimbraId if route_request?
      return auth_zco_username if zco_auth_request?
      return auth_zm_auth_tokken if logged_user_request?
    end

    def auth_zimbraId
      headers["Auth-User"]
    end

    def auth_zco_username
      # Hold on, we have to dig deeper
      xml = XmlSimple.xml_in @body
      xml["Body"].first["AuthRequest"].first["account"].first["content"]
    end

    # Takes the ZM_AUTH_TOKEN and extract the routing info encoded there
    # ZM_AUTH_TOKEN has the following format XX_YYYYY_DATA, the last part is what
    # we care
    def auth_zm_auth_tokken
      # extract the last '_xxxxxxxxx' from the cookie
      _x, _y, hex_auth_data = @cookies['ZM_AUTH_TOKEN'].split('_')

      # decode the last part from HEX to Text
      # Ex: '....231373933353732303b747970653d363...' es
      # "id=36:5e618e78-7b70-41b2-a9f1-76d2842b516d;exp=13:1498217935720;type=6:zimbra;"
      zimbra_id, _exp, _type = [hex_auth_data].pack('H*').split(';')

      # Extract the id of the account
      # from "id=36:5e618e78-7b70-41b2-a9f1-76d2842b516d"
      # To "5e618e78-7b70-41b2-a9f1-76d2842b516d"
      zimbra_id = zimbra_id.split('=')[1].split(':')[1]

      zimbra_id
    end

    def auth_username
      uri = Addressable::URI.parse("http://localhost/?#{@body}")
      uri.query_values["username"]
    end

  end
end
