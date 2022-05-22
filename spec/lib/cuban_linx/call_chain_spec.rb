require "faker"

RSpec.describe CubanLinx::CallChain do
  let(:example_class) do
    Class.new do
      user_class = Class.new do
        def self.find_by(id:)
          case id
          when 42
            new(id: 42)
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

      business_class = Class.new do
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

      include CubanLinx::CallChain

      define_link :lookup_user do |payload|
        user_id = payload.delete(:user_id)
        user_class.find_by(id: user_id).then do |potential_user|
          if potential_user.nil?
            [:error, { user_lookup: "Could not find user w/ id: #{user_id}" }]
          elsif !nice?
            [:error, { user_lookup: "user w/ id: #{user_id} was not nice" }]
          else
            [:ok, { user: potential_user }]
          end
        end
      end

      define_link :format_user do |payload|
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

      define_link :lookup_business do |payload|
        business_id = payload.delete(:business_id)
        business_class.find_by(id: business_id).then do |potential_business|
          if potential_business.nil?
            [:error, { lookup: "Did not find business w/ id: #{business_id}" }]
          else
            [:ok, { business: potential_business, warnings: "nothing to see" }]
          end
        end
      end

      define_link :format_business do |payload|
        return :ok if payload.warnings.none?

        business_hash = payload
                        .fetch(:business)
                        .attributes
                        .slice("id", "name", "industry")

        [
          :ok,
          {
            warnings: "dropped attributes",
            business: business_hash,
          },
        ]
      end

      def payload_inspect
        ->(payload) { puts payload.inspect }
      end

      execution_chain :user_lookup_chain, functions: %i[
        lookup_user
        format_user
        payload_inspect
      ]

      execution_chain :user_lookup_and_more, functions: [
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
  end

  let(:instance) { example_class.new }

  describe ".define_link" do
    it "creates an instance method that returns a proc" do
      expect(instance.lookup_user).to be_a(Proc)
    end
  end

  describe ".function_chain" do
    it "creates an instance method" do
      expect(instance.user_lookup_and_more).to be_a(CubanLinx::Chain)
    end

    it "calls through the chain" do
      instance.user_lookup_chain.call(user_id: 42).then do |result|
        expect(result).to match(
          [
            :ok,
            hash_including(
              messages: hash_including(user: hash_including("id" => 42)),
              errors: {},
            ),
          ]
        )
      end
    end
  end
end
