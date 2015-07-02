module HtmlSurgeon

  class Change
    DATA_CHANGE_AUDIT_ATTRIBUTE = 'data-surgeon-audit'.freeze

    attr_reader :change_set

    def initialize(change_set:)
      @change_set = change_set
    end

    delegate :audit?, to: :change_set
    delegate :uuid, :run_time, to: :change_set, prefix: true

    def apply(element)
      prepare_audit_change(element) if audit?

      apply_in element

      apply_audit_change(element) if audit?

      self
    end

    def log
      raise AbstractMethodError, "a lazy developer has not implemented this method in #{self.class}"
    end

    private

    def prepare_audit_change(element)
      @audit_data = audit_data(element)
    end

    def apply_audit_change(element)
      current = current_audit_data(element)
      current << @audit_data
      element[DATA_CHANGE_AUDIT_ATTRIBUTE] = Oj.dump current
    end

    def current_audit_data(element)
      current = element[DATA_CHANGE_AUDIT_ATTRIBUTE].presence
      return [] unless current

      Oj.load current
    end

    def basic_audit_data
      {
        change_set: change_set_uuid,
        changed_at: change_set_run_time
      }
    end

    def audit_data(element)
      raise AbstractMethodError, "a lazy developer has not implemented this method in #{self.class}"
    end

    def apply_in(_element)
      raise AbstractMethodError, "a lazy developer has not implemented this method in #{self.class}"
    end

  end
end
