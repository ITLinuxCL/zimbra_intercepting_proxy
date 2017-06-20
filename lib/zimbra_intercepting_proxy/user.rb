module ZimbraInterceptingProxy

  class User
    attr_accessor :email, :zimbra_id, :mail_host

    @@db = {}

    # user_identifier can be an email address, zimbraId UUID or just the
    # local part of an email address, like user in user@example.com
    def initialize(zimbra_id: nil, email: nil, mail_host: nil)
      @zimbra_id = zimbra_id
      @email = email
      @mail_host = mail_host
    end

    # If user has email (unless email.nil?)
    def migrated?
      !find_in_db.nil?
    end

    def backend
      return ZimbraInterceptingProxy::Config.new_backend if migrated?
      ZimbraInterceptingProxy::Config.old_backend
    end

    def find_in_db
      return User.DB[email] if has_email?
      return User.DB.invert[zimbraId] if has_zimbraId?
    end

    def has_email?
      !email.nil?
    end

    def has_zimbraId?
      !zimbraId.nil?
    end

    # Return the old DB if the YAML file has error
    def self.load_migrated_users
      data = ZimbraInterceptingProxy::Yamler.db
      return @@db unless data
      @@db = data
    end

    def self.DB
      load_migrated_users
      @@db
    end

    private
    def set_zimbraId user_identifier
      return user_identifier if UUID.validate user_identifier
      nil
    end

    def set_email user_identifier
      return nil if user_identifier.nil?
      return user_identifier if user_identifier.match(/@/)
      return "#{user_identifier}@#{ZimbraInterceptingProxy::Config.domain}" unless UUID.validate user_identifier
      nil
    end


  end

end
