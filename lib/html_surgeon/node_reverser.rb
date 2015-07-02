module HtmlSurgeon
  class NodeReverser
    attr_reader :node, :change_set, :changed_at, :changed_from

    def initialize(node:, change_set: nil, changed_at: nil, changed_from: nil)
      @node         = node
      @change_set   = change_set
      @changed_at   = changed_at
      @changed_from = changed_from
    end

    def call
      changes_to_revert.each do |change_definition|
        revert_change change_definition
      end

      write_remaining_changes
    end

    private

    def revert_change(change_definition)
      klass = Changes.change_class_by_type change_definition[:type]
      klass.revert(node, change_definition)
    end

    def write_remaining_changes
      auditor.apply remaining_changes
    end

    def changes
      auditor.changes
    end

    def remaining_changes
      changes - changes_to_revert
    end

    def changes_to_revert
      @changes_to_revert ||= load_changes_to_revert
    end

    def auditor
      @auditor ||= Auditor.new node
    end

    def load_changes_to_revert
      changes.dup.tap do |rev_changes|
        remove_by_change_set(rev_changes)
        remove_by_changed_at(rev_changes)
        remove_by_changed_from(rev_changes)
      end
    end

    def remove_by_changed_from(rev_changes)
      return unless changed_from.present?

      changed_from_time = changed_from.to_time.utc
      rev_changes.reject! do |change|
        change[:changed_at].to_time.utc < changed_from_time
      end
    end

    def remove_by_changed_at(rev_changes)
      return unless changed_at.present?

      changed_at_time = changed_at.to_time.utc
      rev_changes.reject! do |change|
        change[:changed_at].to_time.utc != changed_at_time
      end
    end

    def remove_by_change_set(rev_changes)
      return unless change_set.present?

      rev_changes.reject! { |change| change[:change_set] != change_set }
    end
  end
end