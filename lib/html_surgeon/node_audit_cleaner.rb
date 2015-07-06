module HtmlSurgeon
  class NodeAuditCleaner
    attr_reader :node

    def initialize(node:)
      @node = node
    end

    def call
      write_empty_changes_list
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