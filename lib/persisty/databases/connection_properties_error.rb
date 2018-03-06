module Persisty
  module Databases
    class ConnectionPropertiesError < StandardError
      def initialize
        super(
          "Error while loading db/properties.yml file. Make sure that all "\
          "key-value pairs are correctly set or file exists."
        )
      end
    end
  end
end
