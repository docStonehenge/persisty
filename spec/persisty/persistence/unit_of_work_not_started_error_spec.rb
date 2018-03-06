module Persisty
  module Persistence
    describe UnitOfWorkNotStartedError do
      it '#message' do
        expect(
          subject.message
        ).to eql "There is no UnitOfWork started on running Thread. "\
                 "To proper persist entities to the database, a new instance "\
                 "is necessary. A call to UnitOfWork.new_current is needed."
      end
    end
  end
end
