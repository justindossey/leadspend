require 'active_support'
module Leadspend
  module Parser
    class RailsParser
      def self.encode(object)
        ActiveSupport::JSON.encode(object)
      end
      def self.decode(string)
        ActiveSupport::JSON.decode(string)
      end
    end
  end
end


