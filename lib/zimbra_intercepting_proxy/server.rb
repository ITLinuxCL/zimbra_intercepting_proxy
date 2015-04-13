module ZimbraInterceptingProxy
  
  module Server
    require 'pp'
    
    def run(host='0.0.0.0', port=9999, backend_port=80)
      
      Proxy.start(:host => host, :port => port) do |conn|
        
        @buffer = ''
        
        @parser = Http::Parser.new
        @headers = nil
        @body = ""
        @started = false
        @done = false

        @parser.on_message_begin = proc{ @started = true }
        @parser.on_headers_complete = proc { |e| @headers = e }
        @parser.on_body = proc { |chunk| @body << chunk }
        @parser.on_message_complete = proc do |p|

          host, port = @headers['Host'].split(':')          
          @backend = {host: host, port: (port || 80)}

          request = ZimbraInterceptingProxy::Request.new(@headers, @body, @parser)
                  
          if request.auth_request? || request.route_request?
            user = User.new(request.user_token)
            @backend[:host] = user.backend if user.migrated?
          end
          
          conn.server @backend[:host], :host => @backend[:host], :port => @backend[:port]
          conn.relay_to_servers @buffer
          
          @buffer.clear
          
        end
        
        conn.on_connect do |data,b|
          #puts [:on_connect, data, b].inspect
        end

        conn.on_data do |data|
          @buffer << data
          @parser << data

          data
        end

        conn.on_response do |backend, resp|
          puts [:on_response, backend, resp].inspect
          resp
        end

        conn.on_finish do |backend, name|
          #puts [:on_finish, name].inspect
        end
        
      end
      
    end
    
    module_function :run
  end
end

