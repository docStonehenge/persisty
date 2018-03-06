module Persisty
  module Repositories
    # Concrete class for insertion operation errors on repositories.
    class InsertionError < OperationError
      # Returns operation name which this error class is responsible for: +insertion+.
      def operation_name
        :insertion
      end
    end
  end
end
