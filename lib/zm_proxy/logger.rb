module ZmProxy
  class Loger
    require 'logger'

    attr_accessor :logger

    def self.initialize(log_output = STDOUT)
      @logger = Logger.new(STDOUT)
    end

    def info(data)
      logger.info { data }
    end

    def debug(data)
      logger.debug { data }
    end
  end
end
