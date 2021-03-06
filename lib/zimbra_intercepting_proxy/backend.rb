module ZimbraInterceptingProxy
  module Backend
    require 'ipaddress'
    require 'date'

    HOSTS_TTL_SECS = 3600
    @@hosts = {}

    def self.default(previous_backend = '')
      host_ip, host_port = previous_backend.to_s.split(':')
      zip_config = ZimbraInterceptingProxy::Config
      default_backend_ip = host_ip || zip_config.default_mailbox_ip
      default_backend_hostname = host_ip || zip_config.default_mailbox_ip
      default_backend_port = host_port || zip_config.mailboxes_mapping[default_backend_ip][:port]
      default_backend_path = zip_config.mailboxes_mapping[default_backend_ip][:zimbra_url_path]

      return {
        host: default_backend_ip,
        host_name: default_backend_hostname,
        port: default_backend_port,
        path: default_backend_path,
        logout: false
      }
    end

    def self.for_user(user)
      backend_ip = self.find_ipaddress(user)
      return backend_ip
    end

    def self.find_ipaddress(user)
      mail_host = user.mail_host || ZimbraInterceptingProxy::Config.default_mailbox_ip
      return mail_host if IPAddress.valid? mail_host
      record = @@hosts[mail_host]
      time_now = DateTime.now.to_time.to_i
      return record[:ipaddress] if (record && (time_now - record[:ttl]) < HOSTS_TTL_SECS )

      begin
        lookup = self.dns_client.getaddress(mail_host)
        backend_ip = lookup.to_s
        ZimbraInterceptingProxy::Debug.logger [:dns, "Found IP #{backend_ip} for #{user.mail_host}"]
      rescue Resolv::ResolvError => _e
        ZimbraInterceptingProxy::Debug.logger [:DNS_ERROR, "NO IP for #{mail_host}"]
        backend_ip = self.default()[:host]
      end
      @@hosts[mail_host] = { ipaddress: backend_ip, ttl: time_now }
      backend_ip
    end

    def self.dns_client
      name_servers = ZimbraInterceptingProxy::Config.name_servers
      name_servers = name_servers.kind_of?(Array) ? name_servers : name_servers.to_s.split(',')

      ZimbraInterceptingProxy::Debug.logger [:dns, "using nameservers: #{name_servers.join(', ')}"]

      domain = ZimbraInterceptingProxy::Config.domain

      if !name_servers.empty? && domain
        return Resolv::DNS.new(nameserver: name_servers, search: [domain], ndots: 1)
      else
        return Resolv::DNS.new()
      end
    end

  end
end
