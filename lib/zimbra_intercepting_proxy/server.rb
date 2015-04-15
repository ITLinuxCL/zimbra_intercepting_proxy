module ZimbraInterceptingProxy
  
  module Server
    require 'pp'
    
    def run
      debug = ZimbraInterceptingProxy::Debug
      host = ZimbraInterceptingProxy::Config.bind_address
      port = ZimbraInterceptingProxy::Config.bind_port
      new_mbx_local_ip_regex = ZimbraInterceptingProxy::Config.new_mbx_local_ip_regex

      Proxy.start(:host => host, :port => port) do |conn|
        
        debug.logger "Starting server on #{host}:#{port} - V. #{ZimbraInterceptingProxy::VERSION}"
        
        @backend = {host: ZimbraInterceptingProxy::Config.old_backend, port: 80}
        connection = ZimbraInterceptingProxy::Connection.new

        @parser = Http::Parser.new
        @parser.on_message_begin = proc{ connection.started = true }
        @parser.on_headers_complete = proc { |e| connection.headers = e }
        @parser.on_body = proc { |chunk| connection.body << chunk }
        @parser.on_message_complete = proc do |p|
          
          request = ZimbraInterceptingProxy::Request.new(connection, @parser)
                  
          if request.auth_request? || request.route_request?
            user = User.new(request.user_token)
            @backend[:host] = user.backend if user.migrated?
            @backend[:port] = request.port
          end
          
          begin
            conn.server @backend[:host], :host => @backend[:host], :port => @backend[:port]
            conn.relay_to_servers connection.buffer
          rescue EventMachine::ConnectionError => e
            conn.server @backend[:host], :host => ZimbraInterceptingProxy::Config.old_backend, :port => @backend[:port]
            conn.relay_to_servers connection.buffer
          end

          
          connection.buffer.clear
          
        end
        
        conn.on_connect do |data,b|
          debug.logger [:on_connect, data, b]
        end

        conn.on_data do |data|
          debug.logger [:on_data, data]
          connection.buffer << data
          @parser << data

          data
        end

        conn.on_response do |backend, resp|
          if backend = ZimbraInterceptingProxy::Config.new_backend
            regex = Regexp.new "Auth-Server: #{new_mbx_local_ip_regex}*"
            new_resp = resp.gsub(regex, "Auth-Server: #{ZimbraInterceptingProxy::Config.new_backend}")
          end
          debug.logger [:on_response, backend, new_resp]
          new_resp
        end

        conn.on_finish do |backend, name|
          debug.logger [:on_finish, name].inspect
        end
        
      end
      
    end
    
    module_function :run
  end
end

