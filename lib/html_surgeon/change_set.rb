module HtmlSurgeon

  class ChangeSet
    attr_reader :node_set, :base, :change_list, :run_time, :refinement_callbacks, :changed_nodes

    def self.create(node_set, base)
      new_class.new node_set, base
    end

    def self.new_class
      Class.new(ChangeSet) do
        Changes.change_classes.each do |klass|
          include klass::ChangeSetMethods
        end
      end
    end

    def initialize(node_set, base)
      @node_set             = node_set
      @changed_nodes        = []
      @base                 = base
      @change_list          = []
      @id                   = SecureRandom.uuid
      @run_time             = nil
      @refinement_callbacks = []
    end

    delegate :audit?, :html, to: :base

    delegate :size, to: :changed_nodes, prefix: true

    # TODO: #preview, like run but in another doc, does not change it yet.

    # chainable fluid ID setter
    def id(custom_id = nil)
      if custom_id
        @id = custom_id
        self
      else
        @id
      end
    end

    def run
      @run_time = Time.now.utc

      node_set.each do |node|
        apply_on_node(node)
      end

      self
    end

    def changes
      change_list.map &:log
    end

    def select(&block)
      refinement_callbacks << [:select, block]
      self
    end

    def reject(&block)
      refinement_callbacks << [:reject, block]
      self
    end

    # CHANGES

    private

    def chain_add_change(change)
      change_list << change
      self
    end

    def apply_on_node(node)
      refinement_callbacks.each do |(type, refinement)|
        case type
        when :select
          return false unless refinement.call(node)
        when :reject
          return false if refinement.call(node)
        end
      end

      do_apply_on_node(node)
      changed_nodes << node
    end

    def do_apply_on_node(node)
      change_list.each do |change|
        change.apply(node)
      end
    end
  end
end
