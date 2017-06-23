module ZmProxy
  module Server
    require 'pp'

    def http_parser_factory(connection)
      http_parser = Http::Parser.new
      http_parser.on_message_begin = proc { |e| connection.started = true }
      http_parser.on_headers_complete = proc { |e| connection.headers = e }
      http_parser.on_body = proc { |chunk| connection.body << chunk }
      http_parser
    end

    def run
      ZmProxy.Log.info [:start, "listen #{host}:#{port} - V. #{ZmProxy::VERSION}"]
      proxy_cfg = { host: ZmProxy.cfg.bind_address, port: ZmProxy.cfg.bind_port }

      Proxy.start(proxy_cfg) do |conn|
        @connection = ZmProxy::Connection.new(conn.peer)
        http_parser = ZmProxy::Server.http_parser_factory(@connection)

        conn.on_connect { |name| ZmProxy.Log.info [:on_connect, name] }
        conn.on_response { |backend, resp| resp }

        conn.on_data do |data|
          @connection.buffer << data
          http_parser << data
          :async
        end

        http_parser.on_message_complete = proc do |e|
          request = ZmProxy::Request.new(@connection, http_parser)
          user = ZmProxy::User.new(request)
          backend = ZmProxy::Backend.lookup(@connection, request, user)

          backend.send!

          debug.logger [:previous_backend, previous_backend]
          @backend = ZmProxy::Backend.default(previous_backend)
          request = ZmProxy::Request.new(connection, @parser)

          if request.has_user_data?
            @user = User.find(request.user_token)
            @backend = @user.backend if @user
          end

          if request.web_auth_request?
            connection.buffer = request.remove_prexif(connection)
          end

          user = @user.nil? ? '-' : @user.email
          debug.logger [:request, "id: #{@id}", user, @parser.http_method, @parser.request_url]
          @@ip_hash[@client_ip] = "#{@backend[:host]}:#{@backend[:port]}"

          unless request.route_request?
            request.set_host_header!(@backend[:host_name], @backend[:port])
            user_log = !@user.nil? ? "#{@user.email} - " : ' '
            user_log << "#{@backend[:host]}:#{@backend[:port]}"
            begin
              conn.server @backend[:host], host: @backend[:host], port: @backend[:port]
              # buffer, fixed_path = request.remove_prexif(@backend[:host], connection, @id)
              debug.logger [:route, "id: #{@id}", user_log, @parser.request_url]
              conn.relay_to_servers connection.buffer
            rescue EventMachine::ConnectionError => e
              debug.logger [@id, "Error Routing Request: #{e.message}"]
            end
          else
            data = request.build_response(@user, connection.headers)
            debug.logger [:route_request, "id: #{@id}", data]
            conn.relay_from_backend @backend[:host_name], data
            connection.buffer.clear
            conn.unbind_backend(@backend[:host_name])
          end
        end


      end
    end
    module_function :run
  end
end
