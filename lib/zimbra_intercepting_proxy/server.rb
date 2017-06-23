module ZimbraInterceptingProxy

  module Server
    require 'pp'

    def run
      @@ip_hash = {}
      debug = ZimbraInterceptingProxy::Debug
      host = ZimbraInterceptingProxy::Config.bind_address
      port = ZimbraInterceptingProxy::Config.bind_port
      debug.logger "Starting server on #{host}:#{port} - V. #{ZimbraInterceptingProxy::VERSION}"


      Proxy.start(:host => host, :port => port) do |conn|
        debug.logger "\n\n----------- #{conn.peer.inspect} --------------------\n"
        @id = Time.now.to_f
        @user = nil
        @client_ip = conn.peer[0]
        connection = ZimbraInterceptingProxy::Connection.new

        @parser = Http::Parser.new
        @parser.on_message_begin = proc { |e| connection.started = true }
        @parser.on_headers_complete = proc do |e|
           connection.headers = e
         end
        @parser.on_body = proc { |chunk| connection.body << chunk }

        @parser.on_message_complete = proc do |e|
          previous_backend = @@ip_hash[@client_ip]
          debug.logger [:previous_backend, previous_backend]
          @backend = ZimbraInterceptingProxy::Backend.default(previous_backend)
          request = ZimbraInterceptingProxy::Request.new(connection, @parser)

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

        conn.on_connect do |name|
          debug.logger [:on_connect, name]
        end

        conn.on_data do |data|
          connection.buffer << data
          @parser << data
          :async
        end

        conn.on_response do |backend, resp|
          # debug.logger [:on_response, resp]
          resp
        end
      end
    end
    module_function :run
  end
end
