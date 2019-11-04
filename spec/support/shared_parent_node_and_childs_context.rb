shared_context 'parent node and childs environment' do
  include_context 'parent node'

  class ::ChildOne
    include Persisty::Persistence::DocumentDefinitions::Base

    parent_node :parent

    def self.repository
      ::ChildOneRepository
    end
  end

  class ::ChildOneRepository
    include Persisty::Repositories::Base

    private

    def entity_klass
      ::ChildOne
    end

    def collection_name
      :child_ones
    end
  end

  class ::ChildTwo
    include Persisty::Persistence::DocumentDefinitions::Base

    parent_node :dad, class_name: 'Parent'

    def self.repository
      ::ChildTwoRepository
    end
  end

  class ::ChildTwoRepository
    include Persisty::Repositories::Base

    private

    def entity_klass
      ::ChildTwo
    end

    def collection_name
      :child_twos
    end
  end

  class ::Parent
    child_node :first_child, class_name: 'ChildOne', foreign_key: :parent_id, cascade: true
    child_node :child_two, foreign_key: :dad_id, cascade: true
  end

  let(:child_one) { ::ChildOne.new }
  let(:child_two) { ::ChildTwo.new }
end
