module Persisty
  module Databases
    class ConnectionError < StandardError
      def initialize(message)
        super(
          "Error while connecting to database. Details: #{message}"
        )
      end
    end
  end
end
