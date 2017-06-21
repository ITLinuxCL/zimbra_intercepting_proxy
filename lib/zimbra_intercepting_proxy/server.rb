module ZimbraInterceptingProxy

  module Server
    require 'pp'

    def run
      debug = ZimbraInterceptingProxy::Debug
      host = ZimbraInterceptingProxy::Config.bind_address
      port = ZimbraInterceptingProxy::Config.bind_port

      Proxy.start(:host => host, :port => port) do |conn|
        debug.logger "Starting server on #{host}:#{port} - V. #{ZimbraInterceptingProxy::VERSION}"
        default_backend_ip = ZimbraInterceptingProxy::Config.default_mailbox_ip
        default_backend_port = ZimbraInterceptingProxy::Config.mailboxes_webmail_port[default_backend_ip]

        @backend = {
          host: default_backend_ip,
          port: default_backend_port
        }

        connection = ZimbraInterceptingProxy::Connection.new

        @parser = Http::Parser.new
        @parser.on_message_begin = proc{ connection.started = true }
        @parser.on_headers_complete = proc { |e| connection.headers = e }
        @parser.on_body = proc { |chunk| connection.body << chunk }
        @parser.on_message_complete = proc do |p|
          request = ZimbraInterceptingProxy::Request.new(connection, @parser)
          if request.auth_request? || request.route_request? || request.logged_user_request?
            user = User.find(request.user_token)
          end

          if user
            debug.logger "Found user: #{user.email} - #{user.mail_host}"
            @backend[:host] = ZimbraInterceptingProxy::Backend.for_user(user)
            @backend[:port] = ZimbraInterceptingProxy::Config.mailboxes_webmail_port[@backend[:host]]
          end

          begin
            conn.server @backend[:host], :host => @backend[:host], :port => @backend[:port]
            user_log = !user.nil? ? "from #{user.email}" : ''
            debug.logger "Routing request #{user_log} to #{@backend[:host]}:#{@backend[:port]}"
            conn.relay_to_servers connection.buffer
            connection.buffer.clear
          rescue EventMachine::ConnectionError => e
            debug.logger "Error Routing Request: #{e.message}"
          end

          connection.buffer.clear
        end

        conn.on_connect do |data,b|
          # debug.logger [:on_connect, data, b]
        end

        conn.on_data do |data|
          # debug.logger [:on_data, data]
          connection.buffer << data
          @parser << data

          data
        end

        conn.on_response do |backend, resp|
          #debug.logger [:on_response, backend, resp]
          resp
        end

        conn.on_finish do |backend, name|
          # debug.logger [:on_finish, name].inspect
        end

      end

    end

    module_function :run
  end
end
