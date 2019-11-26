shared_context 'StubEntity' do
  class ::StubEntity
    include Persisty::Persistence::DocumentDefinitions::Base

    define_field :first_name, type: String
    define_field :age,        type: Integer
    define_field :wage,       type: BigDecimal

    def self.repository
      StubRepository
    end
  end

  class ::ParentEntity
    include Persisty::Persistence::DocumentDefinitions::Base

    define_field :first_name, type: String
    define_field :age,        type: Integer
    define_field :wage,       type: BigDecimal

    def self.repository
      ParentEntitiesRepository
    end
  end

  class ::StubEntityForCollection
    include Persisty::Persistence::DocumentDefinitions::Base

    define_field :first_name, type: String
    define_field :age,        type: Integer
    define_field :wage,       type: BigDecimal
  end

  let(:entity) { ::StubEntity.new }
  let(:entity_for_collection) { ::StubEntityForCollection.new }
end
