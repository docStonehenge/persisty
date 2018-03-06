module Persisty
  module Repositories
    describe InvalidEntityError do
      subject { described_class.new 'Error' }

      it { is_expected.to be_a ArgumentError }

      it '#message' do
        expect(subject.message).to eql 'Error'
      end
    end
  end
end
