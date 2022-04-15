require "set"

DEFAULT_MESSAGES = { warnings: Set.new }.freeze

RSpec::Matchers.define :match_payload do |status, messages = {}, errors = {}|
  match do |payload|
    return false if payload.status != status
    return true if messages.empty? && errors.empty?

    if errors.empty?
      payload.messages == DEFAULT_MESSAGES.merge(messages) && payload.errors.empty?
    else
      payload.messages == DEFAULT_MESSAGES.merge(messages) && payload.errors == errors
    end
  end
end

RSpec::Matchers.define :match_tuple do |status, messages = {}, errors = {}|
  match do |tuple|
    return false if tuple.first != status
    return true if messages.empty? && errors.empty?

    if errors.empty?
      tuple.last[:messages] == DEFAULT_MESSAGES.merge(messages) && tuple.last[:errors].empty?
    else
      tuple.last[:messages] == DEFAULT_MESSAGES.merge(messages) && tuple.last[:errors] == errors
    end
  end
end
