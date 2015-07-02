module HtmlSurgeon
  module Changes
    class ReplaceTagName < Change
      AUDIT_TYPE = :replace_tag_name

      attr_reader :new_tag_name

      def initialize(new_tag_name:, **other)
        @new_tag_name = new_tag_name

        super **other
      end

      def log
        "replace tag name with #{new_tag_name}"
      end

      private
      def apply_in(node)
        node.name = new_tag_name
      end

      def audit_data(node)
        basic_audit_data.merge type: AUDIT_TYPE,
                               old:  node.name,
                               new:  new_tag_name
      end

      def self.revert(node, change_definition)
        node.name = change_definition[:old]
      end

      module ChangeSetMethods
        def replace_tag_name(new_tag_name)
          chain_add_change Changes::ReplaceTagName.new(change_set: self, new_tag_name: new_tag_name)
        end
      end
    end
  end
end
