RSpec.describe CubanLinx::Collaborator do
  describe "#call" do
    context "when the payload status is :error" do
      it "returns the payload" do
        instance = described_class.new(context_instance, ->(*) { :ok })
        payload = payload_double(:error, messages: { keys: "24 a brick" },
                                         errors: { user: :not_found },)
        expect(instance.call(payload)).to eq payload
      end
    end

    context "when the payload status is :no_op" do
      it "returns the payload" do
        instance = described_class.new(context_instance, ->(*) { :ok })
        payload = payload_double(:no_op, messages: { i: :did_nothing })
        expect(instance.call(payload)).to eq payload
      end
    end

    context "when the payload status is :ok" do
      it "calls instance exec on context instance w/ payload & the fn" do
        ok_function = ->(*) { :ok }
        instance = described_class.new(context_instance, ok_function)
        payload = payload_double
        expect(context_instance)
          .to receive(:instance_exec)
          .with(payload, &ok_function)

        instance.call(payload)
      end

      context "when the call to instance_exec returns :ok" do
        it "returns a new instance of a payload" do
          messages = { from: "staircase to stage" }
          instance = described_class.new(context_instance, ->(*) { :ok })
          payload = payload_double(messages: messages, errors: {})
          expect(instance.call(payload)).to match_payload(:ok, messages)
        end
      end

      context "when the payload returns a non-tuple" do
        context "when returning true" do
          it "raises a pattern matching error" do
            instance = described_class.new(context_instance, ->(*) { true })

            expect do
              instance.call(payload_double)
            end.to raise_error(NoMatchingPatternError)
          end
        end

        context "when returning false" do
          it "raises a pattern matching error" do
            instance = described_class.new(context_instance, ->(*) { false })

            expect do
              instance.call(payload_double)
            end.to raise_error(NoMatchingPatternError)
          end
        end

        context "when returning an integer" do
          it "raises a pattern matching error" do
            rand_fn = ->(*) { (-100..100).to_a.sample }
            instance = described_class.new(context_instance, rand_fn)

            expect { instance.call(payload_double) }
              .to raise_error(NoMatchingPatternError)
          end
        end

        context "when retuning a string" do
          it "raises a pattern matching error" do
            fn = ->(*) { "i don't think this will work" }
            instance = described_class.new(context_instance, fn)

            expect { instance.call(payload_double) }
              .to raise_error(NoMatchingPatternError)
          end
        end

        context "when returning a non-supported status in the tuple" do
          it "raises a pattern matching error" do
            fn = ->(*) { [:non_matching_status, {}, {}] }
            instance = described_class.new(context_instance, fn)

            expect { instance.call(payload_double) }
              .to raise_error(NoMatchingPatternError)
          end
        end
      end

      shared_examples "returning an :ok payload" do
        context "when the payload does not have any messages" do
          it "returns a new instance of a payload" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(messages: initial_message)

            expect(instance.call(payload))
              .to match_payload(:ok, expected_messages, expected_errors)
          end
        end

        context "when the payload has messages" do
          it "returns a new instance of a payload including the messages" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(messages: initial_message)

            expect(instance.call(payload))
              .to match_payload(:ok, expected_messages, expected_errors)
          end
        end

        context "when the payload has errors" do
          it "returns a new instance of a payload including the errors" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(messages: initial_message)

            expect(instance.call(payload))
              .to match_payload(:ok, expected_messages, expected_errors)
          end
        end

        context "when the payload has messages and errors" do
          it "returns instance of payload including the messages & errors" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(messages: initial_message, errors: errors)

            expect(instance.call(payload))
              .to match_payload(
                :ok,
                expected_messages,
                errors.merge(expected_errors),
              )
          end
        end
      end

      shared_examples "returning an :error payload" do
        context "when the payload has messages" do
          it "returns an instance of payload including the expected_messages" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(messages: initial_message)

            expect(instance.call(payload))
              .to match_payload(:error, expected_messages, errors)
          end
        end

        context "when the payload has errors" do
          it "returns a new instance of a payload including the errors" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(errors: errors, messages: initial_message)

            expect(instance.call(payload))
              .to match_payload(:error, expected_messages, errors)
          end
        end

        context "when the payload has expected_messages and errors" do
          it "returns a new payload including the expected messages & errors" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(
              messages: expected_messages,
              errors: errors,
            )

            expect(instance.call(payload))
              .to match_payload(:error, expected_messages, errors)
          end
        end
      end

      context "when the call to instance_exec returns nil" do
        let(:initial_message) { {} }
        let(:expected_messages) { {} }
        let(:errors) { { from: "staircase to stage" } }
        let(:fn) { ->(*) {} }
        let(:expected_errors) { {} }

        include_examples "returning an :ok payload"
      end

      context "when the call to instance_exec returns :ok" do
        let(:initial_message) { { hello: :friend } }
        let(:errors) { { from: "staircase to stage" } }
        let(:fn) { ->(*) { :ok } }
        let(:expected_messages) { initial_message }
        let(:expected_errors) { {} }

        include_examples "returning an :ok payload"
      end

      context "when the call to instance_exec returns [:ok, messages]" do
        let(:errors) { { from: "staircase to stage" } }
        let(:fn) { ->(*) { [:ok, { keys: "24 a brick" }] } }
        let(:initial_message) { { the_world: :is_yours } }
        let(:expected_messages) { initial_message.merge(fn.call.last) }
        let(:expected_errors) { {} }

        include_examples "returning an :ok payload"
      end

      context "when call to instance_exec returns [:ok, messages, errors]" do
        let(:fn) do
          lambda { |*|
            [:ok, { keys: "24 a brick" }, { from: "staircase to stage" }]
          }
        end
        let(:initial_message) { { world: :is_yours } }
        let(:expected_messages) { initial_message.merge(fn.call[1]) }
        let(:expected_errors) { fn.call.last }
        let(:errors) { fn.call.last }

        include_examples "returning an :ok payload"
      end

      context "when the call to instance_exec returns [:error, errors]" do
        let(:fn) { ->(*) { [:error, { msg: "pardon my french" }] } }
        let(:initial_message) { { world: :is_yours } }
        let(:expected_messages) { initial_message  }
        let(:errors) { fn.call.last }

        include_examples "returning an :error payload"
      end

      context "when call to instance_exec returns [:error, messages, errors]" do
        let(:fn) do
          lambda { |*|
            [:error, { msg: "pardon my french" },
             { but: "let me speak Italian" },]
          }
        end
        let(:initial_message) { { world: :is_yours } }
        let(:expected_messages) { initial_message.merge(fn.call[1]) }
        let(:errors) { fn.call.last }

        include_examples "returning an :error payload"
      end

      shared_examples "return a :no_op payload" do
        context "when there no exisiting errors" do
          it "returns a new instance of a payload including the messages" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(messages: initial_message,
                                     errors: initial_error,)
            expect(instance.call(payload))
              .to match_payload(:no_op, expected_messages, expected_errors)
          end
        end

        context "when there are exisiting errors" do
          it "returns a new instance of a payload including the messages" do
            instance = described_class.new(context_instance, fn)
            payload = payload_double(messages: initial_message,
                                     errors: initial_error,)
            expect(instance.call(payload))
              .to match_payload(:no_op, expected_messages, expected_errors)
          end
        end
      end

      context "when call to instance_exec returns [:no_op, messages, errors]" do
        let(:fn) do
          lambda { |*|
            [:no_op, { msg: "pardon my french" },
             { but: "let me speak Italian" },]
          }
        end
        let(:initial_message) { { world: :is_yours } }
        let(:expected_messages) { fn.call[1].merge(initial_message) }
        let(:initial_error) { { chef: "shine like marble, rembarkable" } }
        let(:expected_errors) { initial_error.merge(fn.call.last) }

        include_examples "return a :no_op payload"
      end

      context "when the call to instance_exec returns [:no_op, messages]" do
        let(:fn) { ->(*) { [:no_op, { msg: "pardon my french" }] } }
        let(:initial_message) { { world: :is_yours } }
        let(:expected_messages) { fn.call[1].merge(initial_message) }
        let(:initial_error) { {} }
        let(:expected_errors) { {} }

        include_examples "return a :no_op payload"
      end
    end
  end

  let(:context_class) { Class.new }

  def payload_double(status = :ok, messages: {}, errors: {})
    CubanLinx::Payload.new(status, messages, errors)
  end

  def context_instance(*args)
    @context_instance ||= context_class.new(*args)
  end
end
