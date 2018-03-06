module Persisty
  module Repositories
    # Concrete class for update operation errors on repositories.
    class UpdateError < OperationError
      # Returns operation name which this error class is responsible for: +update+.
      def operation_name
        :update
      end
    end
  end
end
