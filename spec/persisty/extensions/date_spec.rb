describe 'Date class extension' do
  describe '.try_convert value' do
    context 'when value is a valid date' do
      it 'returns Date object' do
        expect(Date.try_convert("2017/01/01")).to be_an_instance_of Date
        expect(Date.try_convert(Date.today)).to be_an_instance_of Date
      end

      it 'returns DateTime object' do
        expect(DateTime.try_convert("2017/01/01")).to be_an_instance_of DateTime
        expect(DateTime.try_convert(DateTime.now)).to be_an_instance_of DateTime

        expect(
          DateTime.try_convert("2017/01/01 12:00:00")
        ).to be_an_instance_of DateTime
      end
    end

    context 'when value argument is invalid' do
      it 'returns nil' do
        expect(Date.try_convert("2017")).to be_nil
        expect(Date.try_convert("")).to be_nil
        expect(DateTime.try_convert("2017")).to be_nil
        expect(DateTime.try_convert("")).to be_nil
      end
    end

    context 'when argument type is not conversible' do
      it 'returns nil' do
        expect(Date.try_convert(nil)).to be_nil
        expect(Date.try_convert(1)).to be_nil
        expect(DateTime.try_convert({})).to be_nil
        expect(DateTime.try_convert(:datetime)).to be_nil
      end
    end
  end

  describe '#to_mongo_value' do
    it 'returns itself' do
      date_value = Date.today
      expect(date_value.to_mongo_value).to eql date_value

      datetime_value = DateTime.new
      expect(datetime_value.to_mongo_value).to eql datetime_value
    end
  end

  it '#present?' do
    expect(Date.today).to be_present
    expect(DateTime.new).to be_present
  end
end
