module Persisty
  module Repositories
    # Custom exception class that provides a wrapper around database operation errors
    # called within repositories.
    # Receives message on constructor and uses subclass-defined #operation_name,
    # which will be used as a +reason+ to determine which operation failed
    # in the exception message.
    class OperationError < StandardError
      def initialize(message)
        super("Error on #{operation_name} operation. Reason: '#{message}'")
      end

      # Template method that must be defined by subclasses to indicate which operation
      # has raised the error.
      def operation_name
        raise NotImplementedError
      end
    end
  end
end
