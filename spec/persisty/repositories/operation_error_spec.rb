module Persisty
  module Repositories
    describe OperationError do
      it 'is initialized with abstract method #operation_name and raises error' do
        expect {
          described_class.new("Error from database")
        }.to raise_error NotImplementedError
      end
    end
  end
end
