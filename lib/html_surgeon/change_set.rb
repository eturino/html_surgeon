module HtmlSurgeon

  class ChangeSet
    attr_reader :node_set, :base, :change_list, :uuid, :run_time

    def initialize(node_set, base)
      @node_set    = node_set
      @base        = base
      @change_list = []
      @uuid     = SecureRandom.uuid
      @run_time = nil
    end

    delegate :audit?, :html, to: :base

    # TODO: #preview, like run but in another doc, does not change it yet.

    def run
      @run_time = Time.now.utc

      node_set.each do |element|
        apply_on_element(element)
      end

      self
    end

    def changes
      change_list.map &:log
    end

    # CHANGES

    def replace_tag_name(new_tag_name)
      change_list << Changes::ReplaceTagName.new(change_set: self, new_tag_name: new_tag_name)
      self
    end

    def add_css_class(css_class)
      change_list << Changes::AddCssClass.new(change_set: self, css_class: css_class)
      self
    end

    private

    def apply_on_element(element)
      change_list.each do |change|
        change.apply(element)
      end
    end
  end
end
