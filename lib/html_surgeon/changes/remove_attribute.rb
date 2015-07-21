module HtmlSurgeon
  module Changes
    class RemoveAttribute < Change
      AUDIT_TYPE = :remove_attribute

      attr_reader :attribute

      def initialize(attribute:, **other)
        @attribute = attribute

        super **other
      end

      def log
        "remove attribute #{attribute}"
      end

      private
      def applicable?(node)
        self.class.has_attribute?(node, attribute)
      end

      def apply_in(node)
        self.class.remove_attribute node, attribute
      end

      def audit_data(node)
        basic_audit_data.merge type:      AUDIT_TYPE,
                               attribute: attribute,
                               value:     self.class.attribute_in_node(node, attribute)
      end

      def self.remove_attribute(node, attribute)
        node.xpath(".//@#{attribute}").remove
      end

      def self.set_attribute_in_node(node, attribute, value)
        node.set_attribute(attribute, value)
      end

      def self.has_attribute?(node, attribute)
        node.has_attribute?(attribute) && attribute_in_node(node, attribute).present?
      end

      def self.attribute_in_node(node, attribute)
        node.get_attribute(attribute).to_s
      end

      def self.revert(node, change_definition)
        set_attribute_in_node(node, change_definition[:attribute], change_definition[:value])
      end

      module ChangeSetMethods
        def remove_attribute(attribute)
          chain_add_change Changes::RemoveAttribute.new(change_set: self, attribute: attribute)
        end
      end
    end
  end
end
