module Persisty
  module Persistence
    module DocumentDefinitions
      module Errors
        describe NoParentNodeError do
          it '#message' do
            expect(
              subject.message
            ).to eql "Class must have a parent correctly set up. "\
                     "Use parent definition method on child class to set correct parent_node relation."
          end
        end
      end
    end
  end
end
