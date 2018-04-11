module Persisty
  module StringModifiers
    describe Underscorer do
      it_behaves_like 'a StringModifier object'

      describe '#underscore word' do
        context 'when the word is empty' do
          it 'returns empty string' do
            expect(subject.underscore('')).to eql ''
          end
        end

        context 'when the word is already underscored' do
          it 'returns string unchanged' do
            expect(subject.underscore('under_score')).to eql 'under_score'
          end
        end

        context 'when word is just capitalized' do
          it 'returns word downcased' do
            expect(subject.underscore('Word')).to eql 'word'
          end
        end

        context 'when word is camelcased' do
          it 'returns correct underscore string' do
            expect(subject.underscore('NewWorld')).to eql 'new_world'
            expect(subject.underscore('FooBarBazz')).to eql 'foo_bar_bazz'
          end
        end
      end
    end
  end
end
