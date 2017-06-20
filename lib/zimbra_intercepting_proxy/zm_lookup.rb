module ZimbraInterceptingProxy

  module ZmLookup
    require 'rest-client'

    def self.build_json_auth(username, password)
      auth_request = { Body: { AuthRequest: { } } }
      auth_request[:Body][:AuthRequest] = {
        'account': { 'by': 'name', '_content': username },
        'password': password
        }
      auth_request[:Body][:_jsns] = 'urn:zimbraAdmin'
      auth_request.to_json
    end

    def self.login(username: nil, password: nil)
      raise "username missing for ZmLookup" if username.nil?
      raise "password missing for ZmLookup" if password.nil?
      json_request = self.build_json_auth(username, password)
      soap_admin_url = ZimbraInterceptingProxy::Config.soap_admin_url
      begin
        response = RestClient.post(soap_admin_url, json_request)
        response_as_data = JSON.parse(response.body)
        authToken = response_as_data['Body']['AuthResponse']['authToken'].first['_content']
      rescue RestClient::ExceptionWithResponse => e
        response = e.response
        ZimbraInterceptingProxy::Debug.logger e.response.body
        authToken = nil
      end

      ZimbraInterceptingProxy::Config::zimbra_admin_authtoken = authToken
      return authToken
    end

    def self.soap_admin_url
      return ZimbraInterceptingProxy::Config.soap_admin_url
    end

  end
end
