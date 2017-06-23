module ZmProxy
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

    def initialize(connection, http_parser)
      @body = connection.body
      @cookies = cookies_to_hash connection.headers['Cookie']
      @headers = connection.headers
      @query_params = set_query_params connection.body
      @url = http_parser.request_url
      @http_method = http_parser.http_method
      @parser = http_parser
    end

    # Return the type of request
    # :route => Lookup for Pop3 and IMAP
    # :soap => Connections from ZCO
    # :web => Webmail access and ActiveSync
    def type
      return :route if route_request?
      return :soap if soap_request?
      return :web
    end

    def route_request?
      url == ZmProxy::Config::ROUTE_URL
    end

    def soap_request?
      url =~ /\/service\/soap\// ? true : false
    end

    def user_id
      return web_user if type == :web
      return soap_user if type == :soap
      return route_user if type == :route
    end

    def web_user
      return query_params['username'] if auth_web?
      return user_from_zmtoken if logged_user?
    end

    def is_auth?(type)
      auth_types = {
        web: (http_method == 'POST' && query_params['loginOp'] == 'login'),
        soap: (http_method == 'POST' && url == '/service/soap/AuthRequest')
      }
      auth_types[type]
    end


    def logged_user?
      !cookies.nil? && !cookies['ZM_AUTH_TOKEN'].nil?
    end

    def soap_user
      return unless auth_soap?
      # Hold on, we have to dig deeper
      xml = XmlSimple.xml_in body
      xml['Body'].first['AuthRequest'].first['account'].first['content']
    end


    def route_user
      headers['Auth-User']
    end

    def logout_request?
      url =~ /loginOp=logout/
    end

    def auth_request?
      (web_auth_request? && !logout_request?) || soap_auth_request?
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
        port_number = ZmProxy::Config.mailboxes_mapping[host_ip][proto]
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





    def remove_prexif(connection)
      buffer_as_array = connection.buffer.to_s.split(/\r\n/)
      request_data = buffer_as_array[0].split(/\s+/)
      request_data[1] = @parser.request_url.gsub('/zimbra/', '/')
      buffer_as_array[0] = request_data.join(' ')
      buffer = buffer_as_array.join("\r\n") + "\r\n" + "\r\n"
      ZmProxy::Debug.logger [:remove_prexif, buffer]
      return buffer
    end


    # Takes the ZM_AUTH_TOKEN and extract the routing info encoded there
    # ZM_AUTH_TOKEN has the following format XX_YYYYY_DATA, the last part is what
    # we care. The steps are
    # 1. # extract the last '_xxxxxxxxx' from the cookie
    # 2. decode the last part from HEX to Text
    # Ex: '....231373933353732303b747970653d363...' es
    # "id=36:5e618e78-7b70-41b2-a9f1-76d2842b516d;exp=13:1498217935720;type=6:zimbra;"
    #
    # 3. Extract the id of the account
    # from "id=36:5e618e78-7b70-41b2-a9f1-76d2842b516d"
    # To "5e618e78-7b70-41b2-a9f1-76d2842b516d"
    def user_from_zmtoken
      _x, _y, hex_auth_data = @cookies['ZM_AUTH_TOKEN'].split('_')
      zimbra_id, _exp, _type = [hex_auth_data].pack('H*').split(';')
      zimbra_id = zimbra_id.to_s.split('=')[1].split(':')[1]
      zimbra_id.to_s
    end
  end

  private
  def cookies_to_hash(cookie_header)
    return cookie_header if cookie_header.nil?
    cookies = {}
    cookie_header.split('; ').each do |cookie|
      name, value = cookie.split('=')
      cookies[name] = value
    end
    return cookies
  end

  def set_query_params(body)
    uri = Addressable::URI.parse("http://localhost/?#{connection.body}")
    uri.query_values
  end
end
