module ZimbraInterceptingProxy

  module Server
    require 'pp'

    def run
      debug = ZimbraInterceptingProxy::Debug
      host = ZimbraInterceptingProxy::Config.bind_address
      port = ZimbraInterceptingProxy::Config.bind_port
      debug.logger "Starting server on #{host}:#{port} - V. #{ZimbraInterceptingProxy::VERSION}"

      Proxy.start(:host => host, :port => port) do |conn|
        @next_backend = nil
        @user = nil
        default_backend_ip = ZimbraInterceptingProxy::Config.default_mailbox_ip
        default_backend_hostname = default_backend_ip
        default_backend_port = ZimbraInterceptingProxy::Config.mailboxes_mapping[default_backend_ip][:port]
        default_backend_path = ZimbraInterceptingProxy::Config.mailboxes_mapping[default_backend_ip][:zimbra_url_path]

        default_backend = {
          host: default_backend_ip,
          host_name: default_backend_hostname,
          port: default_backend_port,
          path: default_backend_path,
          logout: false
        }

        @backend = @next_backend || default_backend
        connection = ZimbraInterceptingProxy::Connection.new

        @parser = Http::Parser.new
        @parser.on_message_begin = proc { |e| connection.started = true }
        @parser.on_headers_complete = proc { |e| connection.headers = e }
        @parser.on_body = proc { |chunk| connection.body << chunk }

        @parser.on_message_complete = proc do |e|
          request = ZimbraInterceptingProxy::Request.new(connection, @parser)
          if request.has_user_data?
            @user = User.find(request.user_token)
            @backend = @user.backend if @user
          end
          if request.web_auth_request?
            request.fix_path!(connection, @backend[:path])
          end

          if request.route_request?
            data = request.build_response(@user, connection.headers)
            debug.logger [:route_request, data]
            conn.relay_from_backend @backend[:host_name], data
            connection.buffer.clear
            conn.unbind_backend(@backend[:host_name])
          else
            @next_backend = @backend
            request.set_host_header!(@backend[:host_name], @backend[:port])
            user_log = !@user.nil? ? "#{@user.email} - " : ' '
            user_log << "#{@backend[:host]}:#{@backend[:port]}"

            begin
              conn.server @backend[:host], host: @backend[:host], port: @backend[:port]
              conn.relay_to_servers connection.buffer
              debug.logger [:route, user_log, @parser.request_url]
            rescue EventMachine::ConnectionError => e
              debug.logger "Error Routing Request: #{e.message}"
            end
            connection.buffer.clear
          end
        end

        conn.on_data do |data|
          connection.buffer << data
          @parser << data
          user = @user.nil? ? '-' : @user.email
          debug.logger [:request, user, @parser.http_method, @parser.request_url]
          data
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
