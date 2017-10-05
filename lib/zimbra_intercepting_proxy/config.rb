module ZimbraInterceptingProxy
  module Config

    ROUTE_URL = "/service/extension/nginx-lookup"
    ROUTE_REQUEST_PORT = 7072
    AUTH_REQUEST_PORT = 80

    def self.admin_user=(admin_user)
      @admin_user = admin_user
    end

    def self.admin_password=(admin_password)
      @admin_password = admin_password
    end

    def self.bind_address=(bind_address)
      @bind_address = bind_address || '0.0.0.0'
    end

    def self.bind_port=(bind_port)
      @bind_port = bind_port || '9090'
    end

    def self.debug=(debug)
      @debug = debug
    end

    def self.default_mailbox_ip=(mailbox_ip)
      @default_mailbox_ip = mailbox_ip
    end

    def self.default_domain=(domain)
      @default_domain = domain
    end

    def self.prefix_path=(prefix_path)
      @prefix_path = prefix_path
    end

    def self.mailboxes_mapping=(mailboxes_maps = '')
      @mailboxes_mapping = {}
      mailboxes_maps.to_s.split(';').each do |mbx_map|
        mbx_ip, mbx_port, pop3_port, imap_port, remove_prexif = mbx_map.split(':')
        remove_prexif = remove_prexif.nil? ? false : true
        @mailboxes_mapping[mbx_ip] = {
          port: mbx_port,
          imap_port: imap_port || '143',
          pop3_port: pop3_port || '110',
          ip: mbx_ip,
          remove_prexif: remove_prexif
        }
      end

    end

    def self.domain=(domain)
      @domain = domain
    end

    def self.mail_host_attribute=(mail_host_attribute)
      @mail_host_attribute = mail_host_attribute || 'zimbraMailTransport'
    end

    def self.mailboxes_webmail_port
      @mailboxes_webmail_port
    end

    def self.name_servers=(name_servers = [])
      @name_servers = name_servers
    end

    def self.soap_admin_url=(url)
      @soap_admin_url = url
    end

    def self.zimbra_admin_authtoken=(token)
      @zimbra_admin_authtoken = token
    end

    def self.admin_user
      @admin_user
    end

    def self.admin_password
      @admin_password
    end

    def self.default_mailbox_ip
      @default_mailbox_ip
    end

    def self.default_domain
      @default_domain
    end

    def self.domain
      @domain
    end

    def self.bind_port
      @bind_port
    end

    def self.bind_address
      @bind_address
    end

    def self.debug
      @debug
    end

    def self.mail_host_attribute
      @mail_host_attribute
    end

    def self.mailboxes_mapping
      @mailboxes_mapping
    end

    def self.name_servers
      @name_servers || []
    end

    def self.prefix_path
      @prefix_path
    end

    def self.soap_admin_url
      @soap_admin_url
    end

    def self.zimbra_admin_authtoken
      @zimbra_admin_authtoken
    end
  end
end
