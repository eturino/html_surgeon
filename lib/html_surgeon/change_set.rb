module HtmlSurgeon

  class ChangeSet
    attr_reader :node_set, :base, :change_list, :run_time

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
      @node_set    = node_set
      @base        = base
      @change_list = []
      @id          = SecureRandom.uuid
      @run_time    = nil
    end

    delegate :audit?, :html, to: :base

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

    # CHANGES

    private

    def chain_add_change(change)
      change_list << change
      self
    end

    def apply_on_node(node)
      change_list.each do |change|
        change.apply(node)
      end
    end
  end
end
