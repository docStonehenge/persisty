module Persisty
  describe Boolean do
    describe '.try_convert value' do
      context 'when value is equal to true' do
        it 'returns true value' do
          expect(described_class.try_convert(true)).to be true
        end
      end

      context 'when value is equal to false' do
        it 'returns false value' do
          expect(described_class.try_convert(false)).to be false
        end
      end

      context 'when value is of any other type' do
        it 'returns nil' do
          expect(described_class.try_convert(1)).to be_nil
          expect(described_class.try_convert('')).to be_nil
          expect(described_class.try_convert('false')).to be_nil
          expect(described_class.try_convert('true')).to be_nil
          expect(described_class.try_convert(nil)).to be_nil
          expect(described_class.try_convert({})).to be_nil
        end
      end
    end
  end
end
