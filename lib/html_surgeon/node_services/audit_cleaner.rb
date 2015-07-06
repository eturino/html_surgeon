module HtmlSurgeon
  module NodeServices
    class AuditCleaner
      attr_reader :node

      def initialize(node:)
        @node = node
      end

      def call
        write_empty_changes_list
        1 # always count as 1 change
      end

      private
      def write_empty_changes_list
        auditor.apply []
      end

      def auditor
        @auditor ||= Auditor.new node
      end
    end
  end
end