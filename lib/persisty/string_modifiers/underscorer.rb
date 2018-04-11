require 'persisty/string_modifiers/base'

module Persisty
  module StringModifiers
    class Underscorer < Base
      alias underscore modify

      private

      def define_modification_rules
        { default: { /\A([A-Z])[a-z]*$/ => '\\0', /(.)([A-Z])/ => '\1_\2' } }
      end

      def change_word_based_on(rules, rule_key, new_word)
        new_word.gsub!(rule_key, rules.fetch(rule_key)).downcase!
      end
    end
  end
end
