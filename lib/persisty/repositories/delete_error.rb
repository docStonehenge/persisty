module Persisty
  module Repositories
    # Concrete class for delete operation errors on repositories.
    class DeleteError < OperationError
      # Returns operation name which this error class is responsible for: +delete+.
      def operation_name
        :delete
      end
    end
  end
end
