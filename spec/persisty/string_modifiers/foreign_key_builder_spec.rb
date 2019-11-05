module Persisty
  module StringModifiers
    describe ForeignKeyBuilder do
      describe '#build_foreign_key_from word' do
        context 'when word is camelized' do
          it 'returns word with _id appended' do
            expect(subject.build_foreign_key_from('String')).to eql 'string_id'
            expect(subject.build_foreign_key_from(:String)).to eql 'string_id'
            expect(subject.build_foreign_key_from('Id')).to eql 'id_id'
            expect(subject.build_foreign_key_from(:Id)).to eql 'id_id'
            expect(subject.build_foreign_key_from(String)).to eql 'string_id'
            expect(subject.build_foreign_key_from(' Stringid')).to eql 'stringid_id'
            expect(subject.build_foreign_key_from(:Stringid)).to eql 'stringid_id'

            ::Stringid = Struct.new(:foo)
            expect(subject.build_foreign_key_from(::Stringid)).to eql 'stringid_id'
          end

          it "doesn't append _id when name already has it" do
            expect(subject.build_foreign_key_from('String_id')).to eql 'string_id'
            expect(subject.build_foreign_key_from(:String_id)).to eql 'string_id'
            expect(subject.build_foreign_key_from(:StringId)).to eql 'string_id'

            ::StringId = Struct.new(:foo)
            expect(subject.build_foreign_key_from(::StringId)).to eql 'string_id'
          end
        end

        context 'when word is downcased' do
          it 'returns word with _id appended' do
            expect(subject.build_foreign_key_from('string')).to eql 'string_id'
            expect(subject.build_foreign_key_from(:string)).to eql 'string_id'
            expect(subject.build_foreign_key_from('id')).to eql 'id_id'
            expect(subject.build_foreign_key_from(:id)).to eql 'id_id'
            expect(subject.build_foreign_key_from('stringid ')).to eql 'stringid_id'
            expect(subject.build_foreign_key_from(:stringid)).to eql 'stringid_id'
          end

          it "doesn't append _id when name already has it" do
            expect(subject.build_foreign_key_from('string_id')).to eql 'string_id'
            expect(subject.build_foreign_key_from(:string_id)).to eql 'string_id'
            expect(subject.build_foreign_key_from(:stringId)).to eql 'string_id'
          end
        end

        context 'when word is empty' do
          it 'returns word without any modification' do
            expect(subject.build_foreign_key_from('')).to eql ''
            expect(subject.build_foreign_key_from(:'')).to eql :''
            expect(subject.build_foreign_key_from('  ')).to eql '  '
            expect(subject.build_foreign_key_from(:' ')).to eql :' '
            expect(subject.build_foreign_key_from(nil)).to be_nil
          end
        end
      end

      describe '#name_from_foreign_key foreign_key' do
        it 'returns word without _id attached' do
          expect(subject.name_from_foreign_key('string_id')).to eql 'string'
          expect(subject.name_from_foreign_key(:string_id)).to eql 'string'
          expect(subject.name_from_foreign_key('string_id ')).to eql 'string'
          expect(subject.name_from_foreign_key(:'string_id ')).to eql 'string'
          expect(subject.name_from_foreign_key('String_id')).to eql 'String'
          expect(subject.name_from_foreign_key(:String_id)).to eql 'String'
          expect(subject.name_from_foreign_key(:String)).to eql :String
          expect(subject.name_from_foreign_key('String')).to eql 'String'
          expect(subject.name_from_foreign_key(String)).to eql String
        end

        it 'returns argument when it is empty' do
          expect(subject.name_from_foreign_key('')).to eql ''
          expect(subject.name_from_foreign_key(:'')).to eql :''
          expect(subject.name_from_foreign_key('  ')).to eql '  '
          expect(subject.name_from_foreign_key(:' ')).to eql :' '
          expect(subject.name_from_foreign_key(nil)).to be_nil
        end
      end
    end
  end
end
