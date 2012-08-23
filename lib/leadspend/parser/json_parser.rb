module Leadspend
  module Parser
    class JSONParser
      def self.encode(object)
        JSON.generate(object)
      end
      def self.decode(string)
        JSON.parse(string)
      end
    end
  end
end
