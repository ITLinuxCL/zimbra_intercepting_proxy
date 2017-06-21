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
        default_backend_hostname = default_backend_ip
        default_backend_port = ZimbraInterceptingProxy::Config.mailboxes_mapping[default_backend_ip][:port]
        default_backend_path = ZimbraInterceptingProxy::Config.mailboxes_mapping[default_backend_ip][:path]

        @backend = {
          host: default_backend_ip,
          host_name: default_backend_hostname,
          port: default_backend_port,
          path: default_backend_path
        }

        connection = ZimbraInterceptingProxy::Connection.new

        @parser = Http::Parser.new
        @parser.on_message_begin = proc { |e| connection.started = true }
        @parser.on_headers_complete = proc { |e| connection.headers = e }
        @parser.on_body = proc { |chunk| connection.body << chunk }
        @parser.on_message_complete = proc do |p|
          request = ZimbraInterceptingProxy::Request.new(connection, @parser)
          if request.auth_request? || request.route_request? || request.logged_user_request?
            user = User.find(request.user_token)
          end

          if user
            debug.logger "Found user: #{user.email} - #{user.mail_host}"
            mailbox_ip = ZimbraInterceptingProxy::Backend.for_user(user)
            mailbox_hostname = user.mail_host
            mailbox_mapping = ZimbraInterceptingProxy::Config.mailboxes_mapping[mailbox_ip]
            @backend[:host] = mailbox_ip
            @backend[:host_name] = mailbox_hostname
            @backend[:port] = mailbox_mapping[:port]
            @backend[:path] = mailbox_mapping[:path]
          end

          begin
            # request.set_zimbra_url_path!(@backend[:path])
            # request.set_host_header!(@backend[:host_name], @backend[:port])
            conn.server @backend[:host], :host => @backend[:host], :port => @backend[:port]
            user_log = !user.nil? ? "from #{user.email}" : ''
            debug.logger "Routing request #{user_log} to #{@backend[:host]}:#{@backend[:port]}"
            conn.relay_to_servers connection.buffer
          rescue EventMachine::ConnectionError => e
            debug.logger "Error Routing Request: #{e.message}"
          end

          connection.buffer.clear
        end

        conn.on_connect do |data,b|
          # debug.logger [:on_connect, data, b].inspect
        end

        conn.on_data do |data|
          @parser << data
          # parsed_data = data.split(/\r\n/)
          # request = parsed_data[0]
          # begin
          #   _method, request_path, _http_version = request.split(/\s+/)
          #   if request_path =~ /^\//
          #     request_path = "#{@backend[:path]}#{request_path}"
          #     request = [_method, request_path, _http_version].join(' ')
          #     parsed_data[0] = request
          #     data = parsed_data.join('\r\n')
          #   end
          # rescue Exception => e
          #   ZimbraInterceptingProxy::Debug.logger "connection.set_backend_request: #{e}"
          # end

          # debug.logger [:on_data, data]
          connection.buffer << data

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
