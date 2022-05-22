require "set"

module CubanLinx
  class Payload
    InvalidStatusError = Class.new(StandardError)
    VALID_STATUSES = %i[ok no_op error].freeze

    def initialize(status, messages = {}, errors = {})
      @status = determine_and_validate(status)
      @messages = messages.merge({ warnings: Set.new }, &merge_block)
      @errors = errors
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
      messages.merge(new_messages, &merge_block)
    end

    def add_errors(error_messages)
      errors.merge(error_messages, &merge_block)
    end

    def add_warning(message)
      add(warnings: message)
    end

    def warnings
      messages.fetch(:warnings)
    end

    def delete(key)
      raise KeyError unless messages.key?(key)

      messages.delete(key)
    end

    def method_missing(method_name, *, &block)
      super unless respond_to_missing?(method_name)

      messages.fetch(method_name)
    end

    def respond_to_missing?(method_name, include_private = false)
      messages.key?(method_name) || super
    end

    attr_reader :status, :messages, :errors

    private

    def determine_and_validate(status)
      return status.to_sym if VALID_STATUSES.include?(status.to_sym)

      raise InvalidStatusError,
            "Received #{status.inspect}. "\
            "Should be one of: #{VALID_STATUSES.inspect}"
    end

    # rubocop:disable Metrics/MethodLength
    def merge_block
      lambda { |_key, val1, val2|
        case [val1, val2]
        in [Set => set1, Array => collection]
          set1 + collection
        in [Set => set1, Set => set2]
          set1 + set2
        in [Set => set1, val]
          set1 << val
        else
          val2
        end
      }
    end
    # rubocop:enable Metrics/MethodLength
  end
end
