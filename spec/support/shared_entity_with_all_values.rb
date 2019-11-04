shared_context 'EntityWithAllValues' do
  class ::EntityWithAllValues
    include Persisty::Persistence::DocumentDefinitions::Base

    define_field :field1, type: String
    define_field :field2, type: Integer
    define_field :field3, type: Float
    define_field :field4, type: BigDecimal
    define_field :field5, type: Persisty::Boolean
    define_field :field6, type: Array
    define_field :field7, type: Hash
    define_field :field8, type: BSON::ObjectId
    define_field :field9, type: Date
    define_field :field10, type: DateTime
    define_field :field11, type: Time
  end
end
