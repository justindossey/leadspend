module Leadspend
  module Parser
    class YajlParser
      def self.encode(object)
        Yajl::Encoder.encode(object)
      end
      def self.decode(string)
        Yajl::Parser.parse(string)
      end
    end
  end
end

