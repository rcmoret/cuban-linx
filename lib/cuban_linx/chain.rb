module CubanLinx
  class Chain
    def initialize(functions, context:)
      @function_chain = functions.map do |function|
        chainable_method(context, function)
      end
    end

    def call(initial_status = :ok, initial_args, &block)
      Payload.new(initial_status, initial_args).then do |payload|
        function_chain.reduce(payload, &reducer).as_result.then do |result|
          block_given? ? block.call(result) : result
        end
      end
    end

    private

    def reducer
      ->(memo, function) { function.call(memo) }
    end

    def chainable_method(context, function)
      case function
      in Symbol => method_name
        Collaborator.new(context, context.public_send(method_name))
      in Proc => callable
        Collaborator.new(context, callable)
      end
    end

    attr_reader :function_chain
  end
end
