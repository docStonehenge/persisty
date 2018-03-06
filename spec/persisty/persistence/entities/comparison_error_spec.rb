module Persisty
  module Persistence
    module Entities
      describe ComparisonError do
        it '#message' do
          expect(
            subject.message
          ).to eql "Cannot compare with an entity that isn't persisted."
        end
      end
    end
  end
end
