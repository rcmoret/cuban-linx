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
    end.tap do |bool|
      require "pry"; binding.pry if bool == false
    end
  end
end
