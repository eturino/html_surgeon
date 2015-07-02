module HtmlSurgeon
  class Auditor
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def add_change(change_definition)
      changes << change_definition
    end

    def apply(change_list = nil)
      change_list ||= changes
      if change_list.empty?
        node.xpath(".//@#{DATA_CHANGE_AUDIT_ATTRIBUTE}").remove
      else
        node[DATA_CHANGE_AUDIT_ATTRIBUTE] = Oj.dump change_list
      end
    end

    def changes
      @changes ||= load_changes_from_node
    end

    private

    def load_changes_from_node
      current = node[DATA_CHANGE_AUDIT_ATTRIBUTE].presence
      return [] unless current

      Oj.load current, symbol_keys: true
    end

    NullAuditor = Naught.build do
      def initialize(*)
        super
      end

      def add_change(change_definition)
        false
      end

      def apply
        false
      end
    end
  end
end