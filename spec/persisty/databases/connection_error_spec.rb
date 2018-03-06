module Persisty
  module Databases
    describe ConnectionError do
      subject { described_class.new('Error') }

      it '#message' do
        expect(subject.message).to eql 'Error while connecting to database. Details: Error'
      end
    end
  end
end
