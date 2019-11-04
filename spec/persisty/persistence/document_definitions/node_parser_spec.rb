module Persisty
  module Persistence
    module DocumentDefinitions
      describe NodeParser do
        it '.modifiers' do
          expect(described_class.modifiers).to eql(
                                                 underscorer: StringModifiers::Underscorer,
                                                 camelizer: StringModifiers::Camelizer
                                               )
        end

        it '.new' do
          result = described_class.new

          expect(result).to be_an_instance_of(described_class)

          expect(
            result.instance_variable_get(:@underscorer)
          ).to be_an_instance_of(StringModifiers::Underscorer)

          expect(
            result.instance_variable_get(:@camelizer)
          ).to be_an_instance_of(StringModifiers::Camelizer)
        end

        describe '#parse_node_identification name, class_name' do
          context 'when class name is present' do
            it 'sets node_name and node_class constant based on class_name string' do
              subject.parse_node_identification(:string, 'String')

              expect(subject.node_name).to eql 'string'
              expect(subject.node_class).to eql String
            end

            it 'sets node_name and node_class constant based on class_name constant' do
              subject.parse_node_identification(:string, String)

              expect(subject.node_name).to eql 'string'
              expect(subject.node_class).to eql String
            end

            it 'raises NameError when class_name is an invalid class' do
              expect {
                subject.parse_node_identification('string', InvalidClass)
              }.to raise_error(NameError)
            end

            it 'underscores node_name before setting result' do
              subject.parse_node_identification('NameError', 'NameError')

              expect(subject.node_name).to eql 'name_error'
              expect(subject.node_class).to eql NameError
            end
          end

          context "when class name isn't present" do
            it 'sets node_name and node_class after camelizing node_name' do
              subject.parse_node_identification(:string, nil)

              expect(subject.node_name).to eql 'string'
              expect(subject.node_class).to eql String
            end

            it 'raises NameError node name is an invalid class' do
              expect {
                subject.parse_node_identification('invalid_class', nil)
              }.to raise_error(NameError)
            end
          end
        end
      end
    end
  end
end
