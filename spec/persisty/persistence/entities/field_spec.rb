module Persisty
  module Persistence
    module Entities
      describe Field do
        describe '.call type:, value:' do
          it 'returns result of coercing value from an instance of Field' do
            expect(
              described_class.(type: BigDecimal, value: "100")
            ).to be_an_instance_of BigDecimal
          end
        end

        describe '#coerce' do
          context 'for DateTime values' do
            it 'returns a DateTime value' do
              expect(
                described_class.new(type: DateTime, value: "2017/01/01 12:00").coerce
              ).to be_an_instance_of DateTime
            end

            it 'returns nil when value is empty' do
              expect(
                described_class.new(type: DateTime, value: "").coerce
              ).to be_nil
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: DateTime, value: "foo").coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: DateTime, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for Date values' do
            it 'returns a Date value' do
              expect(
                described_class.new(type: Date, value: "2017/01/01").coerce
              ).to be_an_instance_of Date
            end

            it 'returns nil when value is empty' do
              expect(
                described_class.new(type: Date, value: "").coerce
              ).to be_nil
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: Date, value: "foo").coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: Date, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for Time values' do
            it 'returns a Time value' do
              expect(
                described_class.new(type: Time, value: "2017/01/01 12:00").coerce
              ).to be_an_instance_of Time
            end

            it 'returns nil when value is empty' do
              expect(
                described_class.new(type: Time, value: "").coerce
              ).to be_nil
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: Time, value: "foo").coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: Time, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for String values' do
            it 'returns a String value' do
              expect(
                described_class.new(type: String, value: "string").coerce
              ).to be_an_instance_of String

              expect(
                described_class.new(type: String, value: "").coerce
              ).to be_an_instance_of String
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: String, value: {}).coerce
              ).to be_nil

              expect(
                described_class.new(type: String, value: 1).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: String, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for Array values' do
            it 'returns a Array value' do
              expect(
                described_class.new(type: Array, value: [123]).coerce
              ).to be_an_instance_of Array

              expect(
                described_class.new(type: Array, value: [nil]).coerce
              ).to be_an_instance_of Array

              expect(
                described_class.new(type: Array, value: [12, [435], [["foo"]]]).coerce
              ).to be_an_instance_of Array
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: Array, value: 1).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: Array, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for Hash values' do
            it 'returns a Hash value' do
              expect(
                described_class.new(type: Hash, value: {}).coerce
              ).to be_an_instance_of Hash

              expect(
                described_class.new(type: Hash, value: {foo: nil}).coerce
              ).to be_an_instance_of Hash

              expect(
                described_class.new(type: Hash, value: {foo: {bar: 'bazz'}}).coerce
              ).to be_an_instance_of Hash
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: Hash, value: 1).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: Hash, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for BigDecimal values' do
            it 'returns a BigDecimal value' do
              expect(
                described_class.new(type: BigDecimal, value: 100).coerce
              ).to be_an_instance_of BigDecimal

              expect(
                described_class.new(type: BigDecimal, value: "100").coerce
              ).to be_an_instance_of BigDecimal

              expect(
                described_class.new(type: BigDecimal, value: "1200.98").coerce
              ).to be_an_instance_of BigDecimal
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: BigDecimal, value: {}).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: BigDecimal, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for Float values' do
            it 'returns a Float value' do
              expect(
                described_class.new(type: Float, value: 100).coerce
              ).to be_an_instance_of Float

              expect(
                described_class.new(type: Float, value: "100").coerce
              ).to be_an_instance_of Float
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: Float, value: '').coerce
              ).to be_nil

              expect(
                described_class.new(type: Float, value: {}).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: Float, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for Integer values' do
            it 'returns an Integer value' do
              expect(
                described_class.new(type: Integer, value: 100).coerce
              ).to be_a(Integer)

              expect(
                described_class.new(type: Integer, value: "100").coerce
              ).to be_a(Integer)
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: Integer, value: '').coerce
              ).to be_nil

              expect(
                described_class.new(type: Integer, value: {}).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: Integer, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for Boolean values' do
            it 'returns a true value' do
              expect(
                described_class.new(type: Persisty::Boolean, value: true).coerce
              ).to be true
            end

            it 'returns a false value' do
              expect(
                described_class.new(type: Persisty::Boolean, value: false).coerce
              ).to be false
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: Persisty::Boolean, value: '').coerce
              ).to be_nil

              expect(
                described_class.new(type: Persisty::Boolean, value: {}).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: Persisty::Boolean, value: nil).coerce
              ).to be_nil
            end
          end

          context 'for BSON::ObjectId values' do
            it 'returns a BSON::ObjectId value' do
              expect(
                described_class.new(type: BSON::ObjectId, value: BSON::ObjectId.new).coerce
              ).to be_an_instance_of BSON::ObjectId

              expect(
                described_class.new(type: BSON::ObjectId, value: BSON::ObjectId.new.to_s).coerce
              ).to be_an_instance_of BSON::ObjectId
            end

            it 'returns nil when value is not parseable' do
              expect(
                described_class.new(type: BSON::ObjectId, value: '').coerce
              ).to be_nil

              expect(
                described_class.new(type: BSON::ObjectId, value: '123').coerce
              ).to be_nil

              expect(
                described_class.new(type: BSON::ObjectId, value: {}).coerce
              ).to be_nil
            end

            it 'returns nil when value is nil' do
              expect(
                described_class.new(type: BSON::ObjectId, value: nil).coerce
              ).to be_nil
            end
          end

          context "when type isn't a class or isn't added on map" do
            it 'raises ArgumentError for class not added' do
              class TestType; end

              expect {
                described_class.new(type: TestType, value: 'value').coerce
              }.to raise_error(
                     ArgumentError,
                     "Expected 'type' can be only DateTime, Date, Time, String, "\
                     "Array, Hash, BigDecimal, Float, Integer, BSON::ObjectId, "\
                     "Persisty::Boolean."
                   )
            end

            it 'raises ArgumentError for a type that is not a class' do
              expect {
                described_class.new(type: :type, value: 'value').coerce
              }.to raise_error(
                     ArgumentError,
                     "Expected 'type' can be only DateTime, Date, Time, String, "\
                     "Array, Hash, BigDecimal, Float, Integer, BSON::ObjectId, "\
                     "Persisty::Boolean."
                   )
            end
          end
        end
      end
    end
  end
end
