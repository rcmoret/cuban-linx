RSpec.describe CubanLinx::Chain do
  let(:context_class) do
    class ContextClass
      def minus_fn
        ->(payload) { payload.total - rand(100) }
      end
    end

    ContextClass
  end

  describe ".new" do
    context "when passing a proc directly" do
      it "creates a collaborator" do
        add_function = ->(payload) { payload.total + rand(1000) }
        context_instance = context_class.new
        expect(CubanLinx::Collaborator).to receive(:new).with(context_instance, add_function)

        described_class.new([add_function], context: context_instance)
      end
    end

    context "when passing a symbol that corresponds to an instance method" do
      it "creates a collaborator" do
        context_instance = context_class.new
        expect(CubanLinx::Collaborator)
          .to receive(:new)
          .with(context_instance, ->(payload) { rand(10) })

        described_class.new([:minus_fn], context: context_instance)
      end
    end
  end

  describe "#call" do
    it "instantiates a payload with :ok and the key/word arguments" do
      allow(CubanLinx::Payload).to receive(:new).and_call_original
      messages = { keys: "24 a brick" }
      context_instance = context_class.new
      ok_fn = -> (*) { :ok }
      expect(CubanLinx::Payload)
        .to receive(:new)
        .with(:ok, messages)
      described_class.new([ok_fn], context: context_instance).call(**messages)
    end

    it "returns the result of the last function" do
      context_instance = context_class.new
      ok_fn = -> (payload) { [:ok, string: payload.delete(:String)] }
      string_fn = ->(payload) { [:ok, string: payload.fetch(:string).upcase] }
      sample_copy = "we're not supposed to trust anyone in our profession"
      subject = described_class.new([ok_fn, string_fn], context: context_instance).call(String: sample_copy)
      expect(subject).to match [:ok, { messages: hash_including(string: sample_copy.upcase), errors: {} }]
    end

    it "yields the result of the last function if a block is given" do
      context_instance = context_class.new
      ok_fn = -> (payload) { [:ok, string: payload.delete(:String)] }
      string_fn = ->(payload) { [:ok, string: payload.fetch(:string).upcase] }
      sample_copy = "we're not supposed to trust anyone in our profession"
      subject = described_class.new([ok_fn, string_fn], context: context_instance)
      expect { |block| subject.call(String: sample_copy, &block) }.to yield_control
    end
  end
end
