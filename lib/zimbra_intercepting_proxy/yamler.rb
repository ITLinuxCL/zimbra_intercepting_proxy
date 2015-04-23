module ZimbraInterceptingProxy
  
  module Yamler
    require 'pp'
    
    def self.db
      begin
        YAML.load_file ZimbraInterceptingProxy::Config.migrated_users_file  
      rescue Psych::SyntaxError => e
        puts "ERROR Yaml File: #{e}"
        return false
      end
      
    end
    
  end
  
end