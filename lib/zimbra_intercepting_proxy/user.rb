module ZimbraInterceptingProxy
  
  class User
    attr_accessor :email, :zimbraId
    
    # user_identifier can be an email address, zimbraId UUID or just the
    # local part of an email address, like user in user@example.com
    def initialize(user_identifier)
      @zimbraId = set_zimbraId user_identifier
      @email = set_email user_identifier
      User.load_migrated_users
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

    def self.load_migrated_users
      YAML.load_file ZimbraInterceptingProxy::Config.migrated_users_file
    end
    
    def self.DB
      load_migrated_users
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
