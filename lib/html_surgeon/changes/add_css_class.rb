module HtmlSurgeon
  module Changes
    class AddCssClass < Change
      AUDIT_TYPE = :add_css_class

      CLASS_ATTRIBUTE = 'class'.freeze
      CLASS_SEPARATOR = ' '.freeze
      CLASS_XPATH     = './/@class'.freeze

      attr_reader :css_class

      def initialize(css_class:, **other)
        @css_class = css_class

        super **other
      end

      def log
        "add css class #{css_class}"
      end

      private
      def applicable?(node)
        !self.class.has_class? node, css_class
      end

      def apply_in(node)
        self.class.add_class_to_node node, css_class
      end

      def audit_data(_node)
        basic_audit_data.merge type:  AUDIT_TYPE,
                               class: css_class
      end

      def self.add_class_to_node(node, css_class)
        classes = node_classes node
        classes << css_class unless classes.include? css_class
        set_classes_in_node(node, classes)
      end

      def self.remove_class_to_node(node, css_class)
        classes = node_classes node
        classes.delete css_class
        if classes.empty?
          node.xpath(CLASS_XPATH).remove
        else
          set_classes_in_node(node, classes)
        end
      end

      def self.set_classes_in_node(node, classes)
        node.set_attribute(CLASS_ATTRIBUTE, classes.join(CLASS_SEPARATOR))
      end

      def self.node_classes(node)
        node.get_attribute(CLASS_ATTRIBUTE).to_s.split(CLASS_SEPARATOR)
      end

      def self.has_class?(node, css_class)
        node_classes(node).include? css_class
      end

      def self.revert(node, change_definition)
        remove_class_to_node(node, change_definition[:class])
      end

      module ChangeSetMethods
        def add_css_class(css_class)
          chain_add_change Changes::AddCssClass.new(change_set: self, css_class: css_class)
        end
      end
    end
  end
end
