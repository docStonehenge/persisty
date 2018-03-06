module Persisty
  module Repositories
    describe EntityNotFoundError do
      subject { described_class.new(id: '123', entity_name: 'Foo') }

      it 'is initialized with default message from super with ID used on query' do
        expect(subject.message).to eql("Unable to find Foo with ID #123")
      end
    end
  end
end
