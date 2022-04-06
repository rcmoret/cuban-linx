module CubanLinx
  class Chain
    def initialize(functions, context:)
      @function_chain = functions.map { |function| chainable_method(context, function) }
    end

    def call(**initial_args, &block)
      function_chain.reduce(Payload.new(:ok, initial_args), &reducer).as_result.then do |result|
        block_given? ?  block.call(result) : result
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
