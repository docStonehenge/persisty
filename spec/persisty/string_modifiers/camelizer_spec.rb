module Persisty
  module StringModifiers
    describe Camelizer do
      it_behaves_like 'a StringModifier object'

      describe '#camelize word' do
        context 'when the word is empty' do
          it 'returns empty string' do
            expect(subject.camelize('')).to eql ''
          end
        end

        context 'when the word is already camelized' do
          it 'returns string unchanged' do
            expect(subject.camelize('CamelCase')).to eql 'CamelCase'
            expect(subject.camelize('Class')).to eql 'Class'
          end
        end

        context "when word doesn't have underscore" do
          it 'correctly camelizes word' do
            expect(subject.camelize('salary')).to eql 'Salary'
          end
        end

        context 'when word has underscore' do
          it 'correctly camelizes word with one underscore' do
            expect(subject.camelize('foo_bar')).to eql 'FooBar'
          end

          it 'correctly camelizes word with more than one underscore' do
            expect(subject.camelize('foo_bar_bazz')).to eql 'FooBarBazz'
            expect(subject.camelize('foo_bar_bazz_goo')).to eql 'FooBarBazzGoo'
            expect(subject.camelize('a_test_with_underscore_words')).to eql 'ATestWithUnderscoreWords'
          end
        end
      end
    end
  end
end
