module GrubY
  class BaseObject
    class << self
      def fields(*names)
        @field_names ||= []
        @field_names.concat(names.map(&:to_sym))
        attr_reader(*names)
      end

      def field_names
        @field_names || []
      end
    end

    def initialize(data = {})
      @data = normalize_hash(data)
      self.class.field_names.each do |field|
        instance_variable_set("@#{field}", @data[field.to_s])
      end
    end

    def [](key)
      @data[key.to_s]
    end

    def dig(*keys)
      normalized = keys.map(&:to_s)
      @data.dig(*normalized)
    end

    def to_h
      @data.dup
    end

    def method_missing(name, *args, &block)
      return super unless args.empty? && block.nil?
      return @data[name.to_s] if @data.key?(name.to_s)

      super
    end

    def respond_to_missing?(name, include_private = false)
      @data.key?(name.to_s) || super
    end

    private

    def normalize_hash(data)
      return {} unless data.is_a?(Hash)

      data.each_with_object({}) do |(k, v), out|
        out[k.to_s] = v
      end
    end
  end
end
