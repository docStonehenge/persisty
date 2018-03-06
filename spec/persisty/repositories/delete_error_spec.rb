module Persisty
  module Repositories
    describe DeleteError do
      subject { described_class.new('Error from database') }

      context 'as a subclass of OperationError' do
        it { is_expected.to respond_to :operation_name }
        it { is_expected.to respond_to :message }
      end

      it '#operation_name' do
        expect(subject.operation_name).to eql :delete
      end

      it '#message' do
        expect(subject.message).to eql "Error on delete operation. "\
                                       "Reason: 'Error from database'"
      end
    end
  end
end
