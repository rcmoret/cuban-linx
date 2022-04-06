RSpec.describe CubanLinx::CallChain do
  let(:example_class) do
    class ExampleClass
      include CubanLinx::CallChain

      define_link :user_lookup do |*|
        :ok
      end

      execution_chain :user_lookup_and_more, functions: [:user_lookup]
    end

    ExampleClass
  end

  let(:instance) { example_class.new }

  describe ".define_link" do
    it "creates an instance method that returns a proc" do
      expect(instance.user_lookup).to be_a(Proc)
    end
  end

  describe ".function_chain" do
    it "creates an instance method" do
      expect(instance.user_lookup_and_more.call.first).to eq :ok
    end
  end
end
