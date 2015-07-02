module HtmlSurgeon
  module Changes
    class ReplaceTagName < Change
      attr_reader :new_tag_name

      def initialize(new_tag_name:, **other)
        @new_tag_name = new_tag_name

        super **other
      end

      def log
        "replace tag name with #{new_tag_name}"
      end

      private
      def apply_in(element)
        element.name = new_tag_name
      end

      def audit_data(element)
        {
          type: :replace_tag_name,
          old:  element.name,
          new:  new_tag_name
        }
      end
    end
  end
end
