module ZimbraInterceptingProxy
  class Request
    require 'pp'

    attr_accessor :body, :headers, :parser
    PROTO_PORTS = {
      "http" => :port,
      "https" => :port,
      "pop3" => :pop3_port,
      "pop3s" => :pop3_port,
      "imap" => :imap_port,
      "imaps" => :imap_port
    }

    def initialize(connection, parser = nil)
      @body = connection.body
      @headers = connection.headers
      if @headers["X-Forwarded-For"]
        @headers["X-Forwarded-For"] = @headers["X-Forwarded-For"].split(',').first
      end
      @cookies = cookies_to_hash @headers['Cookie']
      @parser = parser
    end

    def logout_request?
      @parser.request_url =~ /loginOp=logout/
    end

    def auth_request?
      (web_auth_request? && !logout_request?) || soap_auth_request?
    end

    def logged_user_request?
      !@cookies.nil? && !@cookies['ZM_AUTH_TOKEN'].nil?
    end

    # This is the post Auth request sent by Webmail, ActiveSync and POP and IMAP
    def web_auth_request?
      begin
        @parser.http_method == "POST"  && @headers["Cookie"] !~ /ZM_AUTH_TOKEN/ && @parser.request_url =~ /^(\/zimbra\/|\/)$/  
      rescue Exception => _
        false
      end
      
    end

    def set_host_header!(mailbox_hostname, mailbox_port)
      @headers['Host'] = "#{mailbox_hostname}:#{mailbox_port}"
    end

    def extract_request_from_buffer(buffer = '')
      buffer_as_array = buffer.to_s.split(/\r\n/)
      method, request_path, http_version = buffer_as_array.first.split(/\s+/)
      request_path = request_path.to_s =~ /^\// ? request_path : nil
      return {
        method: method,
        path: request_path,
        http_version: http_version
      }
    end

    def logout_redirect
      data = []
      data << "HTTP/1.0 302 Found"
      data << "Date: #{Time.now.to_s}"
      data << "Location: http://#{@headers['Host']}/"
      data << "Content-Length: 0"
      data << "\r\n"
      return data.join("\r\n")
    end

    def build_response(user, headers)
      data = []
      data << "HTTP/1.1 200"
      data << "Date: #{Time.now.to_s}"
      if user
        host_ip = user.backend[:host]
        proto = PROTO_PORTS[headers['Auth-Protocol']]
        port_number = ZimbraInterceptingProxy::Config.mailboxes_mapping[host_ip][proto]
        data << "Auth-Status: OK"
        data << "Auth-Server: #{host_ip}"
        data << "Auth-Port: #{port_number}"
        data << "Auth-Cache-Alias: FALSE"
        data << "Auth-User: #{headers['Auth-User']}"
      else
        data << "Auth-Status: user not found:#{headers['Auth-User']}"
        data << "Auth-Wait: 10"
      end
      data << "Content-Length: 0"
      data << ""
      data << ""
      data.join("\r\n")
    end

    def route_request?
      @parser.request_url == ZimbraInterceptingProxy::Config::ROUTE_URL
    end

    def has_user_data?
      auth_request? || route_request? || logged_user_request?
    end

    def remove_prexif(connection)
      buffer_as_array = connection.buffer.to_s.split(/\r\n/)
      request_data = buffer_as_array[0].split(/\s+/)
      request_data[1] = @parser.request_url.gsub('/zimbra/', '/')
      buffer_as_array[0] = request_data.join(' ')
      buffer = buffer_as_array.join("\r\n") + "\r\n" + "\r\n"
      return buffer
    end

    def soap_auth_request?
      auth_method = 'POST'
      auth_url = '/service/soap/AuthRequest'
      @parser.http_method == auth_method && @parser.request_url == auth_url
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

    def user_token
      return auth_username if web_auth_request?
      return auth_zimbraId if route_request?
      return auth_soap_username if soap_auth_request?
      return auth_zm_auth_tokken if logged_user_request?
    end

    def auth_zimbraId
      headers["Auth-User"]
    end

    def auth_soap_username
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
