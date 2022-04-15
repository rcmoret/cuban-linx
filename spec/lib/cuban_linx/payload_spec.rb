RSpec.describe CubanLinx::Payload do
  describe "#fetch" do
    context "when the payload has messages" do
      context "when calling fetch with a key that is in the messages hash" do
        it "returns the correct value" do
          value = rand(100)
          subject = described_class.new(:ok, id: value)

          expect(subject.fetch(:id)).to eq value
        end
      end

      context "when calling fetch w/ a key that is not in the messages hash" do
        context "when passing a fallback value" do
          it "returns the fallback value" do
            name = Faker::Name.last_name
            subject = described_class.new(:ok, id: rand(100))

            expect(subject.fetch(:name, name)).to eq name
          end
        end

        context "when passing a fallback block" do
          it "returns the fallback value" do
            name = Faker::Name.last_name
            subject = described_class.new(:ok, id: rand(100))

            expect(subject.fetch(:name) { name }).to eq name
          end
        end

        context "when no fallbacks provided" do
          it "raises a key error" do
            subject = described_class.new(:ok, id: rand(100))

            expect { subject.fetch(:name) }.to raise_error(KeyError)
          end
        end
      end
    end

    context "when the payload messages is empty" do
      it "will still have a set of warnings" do
        subject = described_class.new(:ok)

        expect { subject.fetch(:warnings) }.to_not raise_error
      end
    end
  end

  describe "status validation" do
    context "when the status is :ok" do
      it "does not raise a status error" do
        expect { described_class.new(:ok) }.to_not raise_error
      end
    end

    context "when the status is :no_op" do
      it "does not raise a status error" do
        expect { described_class.new(:no_op) }.to_not raise_error
      end
    end

    context "when the status is :error" do
      it "does not raise a status error" do
        expect { described_class.new(:error) }.to_not raise_error
      end
    end

    context "when the status is ::not_bad" do
      it "does raises a status error" do
        expect { described_class.new(:not_bad) }
          .to raise_error(described_class::InvalidStatusError)
      end
    end
  end

  describe "#tuple" do
    it "returns an array with status, messages and errors" do
      name = Faker::Name.last_name
      messages = { name: name }
      errors = { user: :invalid }
      subject = described_class.new(:ok, messages, errors).tuple

      expect(subject)
        .to eq [:ok, messages.merge(warnings: Set.new), errors]
    end
  end

  describe "#as_result" do
    it "returns an array w/ status & named hashses for messages and errors" do
      name = Faker::Name.last_name
      messages = { name: name }
      errors = { user: :invalid }
      subject = described_class.new(:ok, messages, errors).as_result

      expect(subject).to eq [
        :ok,
        {
          messages: messages.merge(warnings: Set.new),
          errors: errors,
        },
      ]
    end
  end

  describe "#add"
  describe "#add_errors"

  describe "#add_warning" do
    it "adds a message to the set of warnings" do
      subject = described_class.new(:ok, id: rand(10))
      warning_copy = "you don't trust me huh?"

      expect { subject.add_warning(warning_copy) }
        .to change { subject.warnings }
        .from(Set.new)
        .to(Set.new([warning_copy]))
    end

    context "when called multiple times" do
      it "adds multiple message to the set of warnings" do
        instance = described_class.new(:ok, id: rand(10))
        warning_copy = "you don't trust me huh?"
        rebuttal_copy = "you know why"

        subject = lambda {
          instance.add_warning(warning_copy)
          instance.add_warning(rebuttal_copy)
        }

        expect(&subject)
          .to change { instance.warnings }
          .from(Set.new)
          .to(Set.new([warning_copy, rebuttal_copy]))
      end
    end
  end

  describe "#warnings"

  describe "#delete" do
    context "when calling with a key that is not in messages" do
      it "raises a key error" do
        name = Faker::Name.last_name
        subject = described_class.new(:ok, id: rand(100), last_name: name)

        expect { subject.delete(:identifier) }.to raise_error(KeyError)
      end
    end

    context "when calling with a key that is in messages" do
      it "returns the original value" do
        name = Faker::Name.last_name
        subject = described_class.new(:ok, id: rand(100), last_name: name)

        expect(subject.delete(:last_name)).to eq name
      end

      it "deletes the value from the messages hash" do
        name = Faker::Name.last_name
        subject = described_class.new(:ok, id: rand(100), last_name: name)

        expect { subject.delete(:last_name) }
          .to change { subject.fetch(:last_name, nil) }
          .from(name)
          .to(nil)
      end
    end
  end

  describe "#method_missing" do
    context "when method name corresponds to a key in messages" do
      it "returns that value" do
        name = Faker::Name.last_name
        subject = described_class.new(:ok, id: rand(100), last_name: name)

        expect(subject.last_name).to eq name
      end
    end

    context "when the method name doesn't correspond to a key in messages" do
      it "raises a no method error" do
        name = Faker::Name.last_name
        subject = described_class.new(:ok, last_name: name)

        expect { subject.indentifier }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#respond_to?" do
    context "when method name corresponds to a key in messages" do
      it "returns that value" do
        name = Faker::Name.last_name
        subject = described_class.new(:ok, id: rand(100), last_name: name)

        expect(subject.respond_to?(:last_name)).to be true
      end
    end

    context "when the method name doesn't correspond to a key in messages" do
      it "raises a no method error" do
        name = Faker::Name.last_name
        subject = described_class.new(:ok, last_name: name)

        expect(subject.respond_to?(:indentifier)).to be false
      end
    end
  end
end
