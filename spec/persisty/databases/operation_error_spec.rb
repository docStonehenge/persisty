module Persisty
  module Databases
    describe OperationError do
      subject { described_class.new("Error from database") }

      it '#message' do
        expect(subject.message).to eql('Error from database')
      end
    end
  end
end
