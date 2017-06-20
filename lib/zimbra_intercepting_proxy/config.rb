module ZimbraInterceptingProxy
  module Config
    attr_accessor :new_backend, :old_backend

    ROUTE_URL = "/service/extension/nginx-lookup"
    ROUTE_REQUEST_PORT = 7072
    AUTH_REQUEST_PORT = 80

    def self.domain=(domain)
      @domain = domain
    end

    def self.domain
      @domain
    end

    def self.migrated_users_file=(file)
      @migrated_users_file = file
    end

    def self.migrated_users_file
      @migrated_users_file
    end

    def self.backend_port=(port)
      @backend_port
    end

    def self.backend_port
      @backend_port
    end

    def self.old_backend=(old_backend)
      @old_backend = old_backend
    end

    def self.new_backend=(new_backend)
      @new_backend = new_backend
    end

    def self.old_backend
      @old_backend
    end

    def self.new_backend
      @new_backend
    end

    def self.bind_port=(bind_port)
      @bind_port = bind_port
    end

    def self.bind_port
      @bind_port
    end

    def self.bind_address=(bind_address)
      @bind_address = bind_address
    end

    def self.bind_address
      @bind_address
    end

    def self.debug=(debug)
      @debug = debug
    end

    def self.debug
      @debug
    end

    def self.new_mbx_local_ip_regex=(ip)
      @new_mbx_local_ip_regex = ip
    end

    def self.new_mbx_local_ip_regex
      @new_mbx_local_ip_regex
    end

    def self.soap_admin_url=(url)
      @soap_admin_url = url
    end

    def self.soap_admin_url
      @soap_admin_url
    end

    def self.zimbra_admin_authtoken=(token)
      @zimbra_admin_authtoken = token
    end

    def self.zimbra_admin_authtoken
      @zimbra_admin_authtoken
    end

    def self.mail_host_attribute=(mail_host)
      @mail_host_attribute = mail_host
    end

    def self.mail_host_attribute
      @mail_host_attribute
    end
  end
end
