module Persisty
  module Persistence
    module DocumentDefinitions
      describe FieldsReference do
        describe '#register name, type' do
          it 'registers field on map, with name referencing type hash' do
            subject.register :name, String

            expect(subject.fields).to include(name: { type: String })
          end
        end

        describe '#fields_list' do
          it 'returns array with all fields keys' do
            subject.register :name, String
            subject.register :age, Integer

            expect(subject.fields_list).to eql [:name, :age]
          end
        end
      end
    end
  end
end
