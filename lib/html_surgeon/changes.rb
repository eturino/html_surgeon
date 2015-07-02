module HtmlSurgeon
  module Changes
    def self.change_classes
      @change_classes ||= []
    end

    def self.add_change_class(klass)
      change_classes << klass
    end

    def self.change_class_by_type(type)
      type = type.to_s
      change_classes.find { |klass| klass::AUDIT_TYPE.to_s == type }
    end
  end
end