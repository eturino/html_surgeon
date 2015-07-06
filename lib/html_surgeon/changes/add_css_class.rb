module HtmlSurgeon
  module Changes
    class AddCssClass < Change
      AUDIT_TYPE = :add_css_class

      CLASS_ATTRIBUTE = 'class'.freeze
      CLASS_SEPARATOR = ' '.freeze
      CLASS_XPATH     = './/@class'

      attr_reader :css_class

      def initialize(css_class:, **other)
        @css_class = css_class

        super **other
      end

      def log
        "add css class #{css_class}"
      end

      private
      def apply_in(node)
        self.class.add_class_to_node css_class, node
      end

      def audit_data(node)
        basic_audit_data.merge type:           AUDIT_TYPE,
                               existed_before: self.class.has_class?(node, css_class),
                               class:          css_class
      end

      def self.add_class_to_node(css_class, node)
        classes = node_classes node
        classes << css_class unless classes.include? css_class
        set_classes_in_node(classes, node)
      end

      def self.remove_class_to_node(css_class, node)
        classes = node_classes node
        classes.delete css_class
        if classes.empty?
          node.xpath(CLASS_XPATH).remove
        else
          set_classes_in_node(classes, node)
        end
      end

      def self.set_classes_in_node(classes, node)
        node.set_attribute(CLASS_ATTRIBUTE, classes.join(CLASS_SEPARATOR))
      end

      def self.node_classes(node)
        node.get_attribute(CLASS_ATTRIBUTE).to_s.split(CLASS_SEPARATOR)
      end

      def self.has_class?(node, css_class)
        node_classes(node).include? css_class
      end

      def self.revert(node, change_definition)
        return if change_definition[:existed_before]
        remove_class_to_node(change_definition[:class], node)
      end

      module ChangeSetMethods
        def add_css_class(css_class)
          chain_add_change Changes::AddCssClass.new(change_set: self, css_class: css_class)
        end
      end
    end
  end
end
