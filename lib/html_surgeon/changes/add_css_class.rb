module HtmlSurgeon
  module Changes
    class AddCssClass < Change
      attr_reader :css_class
      CLASS_ATTRIBUTE = 'class'.freeze
      CLASS_SEPARATOR = ' '.freeze

      def initialize(css_class:, **other)
        @css_class = css_class

        super **other
      end

      def log
        "add css class #{css_class}"
      end

      private
      def apply_in(element)
        classes = element_classes element
        classes << css_class
        element.set_attribute(CLASS_ATTRIBUTE, classes.join(CLASS_SEPARATOR))
      end

      def audit_data(element)
        {
          type:           :add_css_class,
          existed_before: had_class?(element),
          class:          css_class
        }
      end

      def element_classes(element)
        element.get_attribute(CLASS_ATTRIBUTE).to_s.split(CLASS_SEPARATOR)
      end

      def had_class?(element)
        element_classes(element).include? css_class
      end
    end
  end
end
