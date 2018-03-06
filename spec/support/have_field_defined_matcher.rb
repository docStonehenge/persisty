require 'rspec/expectations'

RSpec::Matchers.define :have_field_defined do |field_name, field_type|
  name = field_name.to_sym

  match do |actual|
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
    "expected that #{actual} would have a field called #{name}, of type #{field_type}"
  end
end

RSpec::Matchers.define :have_id_defined do
  match do |actual|
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
    "expected that #{actual} would have a 'id' field, of type BSON::ObjectId"
  end
end
