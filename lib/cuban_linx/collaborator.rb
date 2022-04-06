module CubanLinx
  class Collaborator
    def initialize(context, function)
      @context = context
      @function = function
    end

    attr_reader :function, :context

    def call(payload)
      case payload.status
      in :ok
        context.instance_exec(payload, &function).then do |result|
          Payload.new(*handle(payload, result))
        end
      in :no_op | :error
        payload
      end
    end

    private

    def handle(payload, result)
      case result
      in :ok | nil
        payload.tuple
      in [:ok, messages]
        [:ok, payload.add(messages), payload.errors]
      in [:ok, messages, errors]
        [:ok, payload.add(messages), payload.add_errors(errors)]
      in [:no_op, messages]
        [:no_op, payload.add(messages)]
      in [:no_op, messages, errors]
        [:no_op, payload.add(messages), payload.add_errors(errors)]
      in [:error, messages, errors]
        [:error, payload.add(messages), payload.add_errors(errors)]
      in [:error, errors]
        [:error, payload.messages, payload.add_errors(errors)]
      end
    end
  end
end
