require "faker"

class User
  def self.find_by(id:)
    case id
    when 42
      new(id: 42)
    else
      nil
    end
  end

  def initialize(id:)
    @id = id
  end

  attr_reader :id

  def attributes
    @attributes ||= {
      "id" => id,
      "business_id" => business_id,
      "last_name" => Faker::Name.last_name,
    }
  end

  def business_id
    @business_id ||= rand(100)
  end
end

class Business
  def self.find_by(id:)
    new(id: id)
  end

  def initialize(id:)
    @id = id
  end

  attr_reader :id

  def attributes
    @attributes ||= {
      "id" => id,
      "name" => Faker::Company.name,
      "industry" => Faker::Company.industry,
    }
  end
end

class FunnyBusiness
  include CubanLinx::CallChain

  define_function :lookup_user do |payload|
    user_id = payload.delete(:user_id)
    User.find_by(id: user_id).then do |potential_user|
      if potential_user.nil?
        [:error, { user_lookup: "Could not find user w/ id: #{user_id}" }]
      elsif !nice?
        [:error, { user_lookup: "user w/ id: #{user_id} was not nice" }]
      else
        [:ok, { user: potential_user }]
      end
    end
  end

  define_function :format_user do |payload|
    payload.fetch(:user).then do |user|
      [
        :ok,
        {
          warnings: "dropped attributes",
          user: user.attributes.slice("id", "last_name"),
          business_id: user.business_id,
        },
      ]
    end
  end

  define_function :lookup_business do |payload|
    business_id = payload.delete(:business_id)
    Business.find_by(id: business_id).then do |potential_business|
      if potential_business.nil?
        [:error, { business_lookup: "Could not find business w/ id: #{business_id}" }]
      else
        [:ok, { business: potential_business, warnings: "nothing to see here" }]
      end
    end
  end

  define_function :format_business do |payload|
    if payload.warnings.none?
      :ok
    else
      payload.fetch(:business).then do |business|
        [
          :ok,
          {
            warnings: "dropped attributes",
            business: business.attributes.slice("id", "name", "industry"),
          },
        ]
      end
    end
  end

  def payload_inspect
    ->(payload) { puts payload.inspect }
  end

  function_chain :user_and_biz_lookup_chain, functions: [
    :lookup_user,
    :format_user,
    :lookup_business,
    :format_business,
    ->(*) { :ok },
    lambda { |_payload|
      [:ok, *misc_tuples].sample
    },
    :payload_inspect,
  ]

  def call(user_id)
    user_and_biz_lookup_chain.call(user_id: user_id)
  end

  private

  def nice?
    true
    # [true, false].sample
  end

  def misc_tuples
    [
      [:error, {}, { sorry: "about your luck" }],
      [:no_op, { greetings: "try again" }],
    ]
  end
end
