require "persisty/version"

module Persisty
  require 'persisty/extensions/float'
  require 'persisty/extensions/array'
  require 'persisty/extensions/hash'
  require 'persisty/extensions/string'
  require 'persisty/extensions/symbol'
  require 'persisty/extensions/integer'
  require 'persisty/extensions/boolean'
  require 'persisty/extensions/false_class'
  require 'persisty/extensions/true_class'
  require 'persisty/extensions/nil_class'
  require 'persisty/extensions/date'
  require 'persisty/extensions/time'
  require 'persisty/extensions/big_decimal'
  require 'persisty/extensions/bson_object_id'

  require 'persisty/string_modifiers/pluralizer'
  require 'persisty/string_modifiers/singularizer'
  require 'persisty/string_modifiers/camelizer'
  require 'persisty/string_modifiers/underscorer'

  require 'persisty/databases/connection_properties_error'
  require 'persisty/databases/operation_error'
  require 'persisty/databases/connection_error'
  require 'persisty/databases/uri_parser'
  require 'persisty/databases/mongo_db/aggregation_wrapper'
  require 'persisty/databases/mongo_db/client'

  require 'persisty/persistence/unit_of_work'
  require 'persisty/persistence/entities/registry'
  require 'persisty/persistence/entities/dirty_tracking_registry'
  require 'persisty/persistence/entities/field'
  require 'persisty/persistence/document_definitions/node_assignments/check_object_type'
  require 'persisty/persistence/document_definitions/node_parser'
  require 'persisty/persistence/document_definitions/collection_node_parser'
  require 'persisty/persistence/document_definitions/document_collection_factory'
  require 'persisty/persistence/document_definitions/document_collection_builder'
  require 'persisty/persistence/document_definitions/fields_reference'
  require 'persisty/persistence/document_definitions/nodes_reference'
  require 'persisty/persistence/document_definitions/base'
  require 'persisty/persistence/document_definitions/errors/no_parent_node_error'

  require 'persisty/associations/document_collection'

  require 'persisty/repositories/operation_error'
  require 'persisty/repositories/insertion_error'
  require 'persisty/repositories/update_error'
  require 'persisty/repositories/delete_error'
  require 'persisty/repositories/registry'
  require 'persisty/repositories/entity_not_found_error'
  require 'persisty/repositories/invalid_entity_error'
  require 'persisty/repositories/base'

  require 'persisty/document_manager'

  require 'persisty/matchers/field_defined_matchers'
end
