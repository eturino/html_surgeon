module HtmlSurgeon

  class Change
    def self.inherited(klass)
      Changes.add_change_class(klass)
    end

    attr_reader :change_set
    delegate :audit?, to: :change_set
    delegate :uuid, :run_time, to: :change_set, prefix: true

    def initialize(change_set:)
      @change_set = change_set
    end

    def apply(node)
      auditor = auditor_class.new(node)

      auditor.add_change(audit_data(node))
      apply_in node
      auditor.apply

      self
    end

    def auditor_class
      audit? ? Auditor : Auditor::NullAuditor
    end

    def log
      raise AbstractMethodError, "a lazy developer has not implemented this method in #{self.class}"
    end

    private
    def basic_audit_data
      {
        change_set: change_set_uuid,
        changed_at: change_set_run_time
      }
    end

    def audit_data(node)
      raise AbstractMethodError, "a lazy developer has not implemented this method in #{self.class}"
    end

    def apply_in(_node)
      raise AbstractMethodError, "a lazy developer has not implemented this method in #{self.class}"
    end

  end
end
