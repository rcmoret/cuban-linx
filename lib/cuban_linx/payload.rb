require "set"

module CubanLinx
  class Payload
    def initialize(status, messages = {}, errors = {})
      @status = status
      @messages = MessageHash.new(messages, initial_keys: :warnings)
      @errors = hash_with_sets.merge(errors)
    end

    def fetch(*args, &block)
      if block_given?
        messages.fetch(*args, &block)
      else
        messages.fetch(*args)
      end
    end

    def tuple
      [status, messages, errors]
    end

    def as_result
      [status, { messages: messages, errors: errors }]
    end

    def add(new_messages)
      messages.merge(new_messages)
    end

    def add_errors(error_messages)
      errors.merge(error_messages)
    end

    def warnings
      messages.fetch(:warnings)
    end

    def delete(key)
      raise KeyError unless messages.key?(key)

      messages.delete(key)
    end

    attr_reader :status, :messages, :errors

    private

    def hash_with_sets
      Hash.new { |hash, key| hash[key] = Set.new }
    end

    class MessageHash < Hash
      def initialize(messages, initial_keys: [])
        super() { |hash, key| hash[key] = Set.new }
          .merge!(messages)
          .tap { |hash| Array(initial_keys).each { |key| hash[key] } }
      end

      def merge(other_hash)
        super(other_hash) do |_key, val1, val2|
          case [val1, val2]
          in [Set => set1, Array => collection]
            set1 + collection
          in [Set => set1, val]
            set1 << val
          else
            val2
          end
        end
      end
    end
    private_constant :MessageHash
  end
end
