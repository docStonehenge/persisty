require 'rspec/expectations'

module Persisty
  module Matchers
    module FieldDefinedMatchers
      extend RSpec::Matchers::DSL

      matcher :have_field_defined do |field_name, field_type|
        name = field_name.to_sym

        match do |actual|
          return false unless actual.is_a? Persistence::DocumentDefinitions::Base

          actual.class.fields_list.include? name
          actual.class.fields.key? name

          (actual.class.fields.dig(name, :type) == field_type)

          actual.respond_to? name
          actual.respond_to? :"#{name}="
        end

        description do
          "have a defined field called #{name}, of type #{field_type}"
        end

        failure_message do |actual|
          if actual.is_a? Persistence::DocumentDefinitions::Base
            "expected that #{actual} would have a field called #{name}, of type #{field_type}"
          else
            "expected that #{actual} would have Persisty entity structure. "\
            "Maybe you forgot to include Persistence::DocumentDefinitions::Base module to the entity class?"
          end
        end
      end

      matcher :have_id_defined do
        match do |actual|
          return false unless actual.is_a? Persistence::DocumentDefinitions::Base

          actual.class.fields_list.include? :id
          actual.class.fields.key? :id

          (actual.class.fields.dig(:id, :type) == BSON::ObjectId)

          actual.respond_to? :id
          actual.respond_to? :_id
          actual.respond_to? :id=
                             actual.respond_to? :_id=
        end

        description do
          "have a defined 'id' field, of type BSON::ObjectId"
        end

        failure_message do |actual|
          "expected that #{actual} would have an 'id' field defined, of type BSON::ObjectId. "\
          "Is the entity really a Persisty entity?"
        end
      end
    end
  end
end
