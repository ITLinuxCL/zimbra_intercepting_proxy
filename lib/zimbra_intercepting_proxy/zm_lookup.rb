module ZimbraInterceptingProxy

  module ZmLookup
    require 'rest-client'

    def self.build_json_auth(username, password)
      request = { Body: { AuthRequest: { } } }
      request[:Body][:AuthRequest] = {
        'account': { 'by': 'name', '_content': username },
        'password': password
        }
      request[:Body][:_jsns] = 'urn:zimbraAdmin'
      request.to_json
    end

    def self.build_json_get_account(account_email, authToken, mail_host_attribute)
      request = { }
      request[:Header] = { context: { } }
      request[:Header][:context][:_jsns] = "urn:zimbra"
      request[:Header][:context][:authToken] = {
        _content: authToken
      }
      request[:Body] = { GetAccountRequest: { } }
      request[:Body][:GetAccountRequest][:attrs] = mail_host_attribute
      request[:Body][:GetAccountRequest][:account] = {
        by: 'name',  '_content': account_email
      }

      request[:Body][:GetAccountRequest][:_jsns] = 'urn:zimbraAdmin'
      request.to_json
    end

    def self.get_zimbra_account(account: nil, auth_token: nil)
      raise "account missing for ZmLookup" if account.nil?
      raise "auth_token missing for ZmLookup" if auth_token.nil?
      mail_host_attribute = ZimbraInterceptingProxy::Config.mail_host_attribute

      json_request = self.build_json_get_account(account, auth_token, mail_host_attribute)
      soap_admin_url = ZimbraInterceptingProxy::Config.soap_admin_url


      begin
        response = RestClient.post(soap_admin_url, json_request)
        response_as_data = JSON.parse(response.body)
        data = response_as_data["Body"]["GetAccountResponse"]["account"].first
        account = {
          "name" => data["name"],
          "id" => data["id"],
          "#{mail_host_attribute}" => data["a"].first["_content"],
        }
      rescue RestClient::ExceptionWithResponse => e
        response = e.response
        ZimbraInterceptingProxy::Debug.logger e.response.body
        account = nil
      end

      return account
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
