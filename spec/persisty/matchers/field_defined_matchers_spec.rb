module Persisty
  module Matchers
    describe FieldDefinedMatchers do
      include_context 'StubEntity'

      subject { Object.new.extend(described_class) }

      describe '#have_field_defined field_name, field_type' do
        let(:matcher) { subject.have_field_defined(:first_name, String) }

        before do
          expect(matcher).to be_an_instance_of(RSpec::Matchers::DSL::Matcher)
        end

        it 'has description for field defined expectation' do
          expect(matcher.description).to eql 'have a defined field called first_name, of type String'
        end

        context 'when entity has field defined' do
          it 'matches correctly for any field defined without returning failure' do
            expect(matcher.matches?(entity)).to be true
          end
        end

        context "when entity doesn't have field defined" do
          let(:matcher) { subject.have_field_defined(:fooza, Array) }

          it "doesn't match entity and sets failure message" do
            expect(matcher.matches?(entity)).to be false
            expect(matcher.failure_message).to eql "expected that #{entity} would have a field called fooza, of type Array"
          end
        end

        context "when entity isn't a Persisty entity" do
          it "doesn't match entity and and sets failure message" do
            entity = Object.new

            expect(matcher.matches?(entity)).to be false

            expect(matcher.failure_message).to eql "expected that #{entity} would have Persisty entity structure."\
                                                   " Maybe you forgot to include Persistence::DocumentDefinitions::Base module to the entity class?"
          end
        end
      end

      describe '#have_id_defined' do
        let(:matcher) { subject.have_id_defined }

        before do
          expect(matcher).to be_an_instance_of(RSpec::Matchers::DSL::Matcher)
        end

        it 'has description for id defined expectation' do
          expect(matcher.description).to eql "have a defined 'id' field, of type BSON::ObjectId"
        end

        context 'when entity has id field defined' do
          it 'matches correctly' do
            expect(matcher.matches?(entity)).to be true
          end
        end

        context "when entity doesn't have id field defined" do
          it "doesn't match entity and sets failure message" do
            entity = Object.new

            expect(matcher.matches?(entity)).to be false

            expect(matcher.failure_message).to eql "expected that #{entity} would have an "\
                                                   "'id' field defined, of type BSON::ObjectId. "\
                                                   "Is the entity really a Persisty entity?"
          end
        end
      end
    end
  end
end
