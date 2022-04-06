module CubanLinx
  module CallChain
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      private

      def define_link(name, &function)
        define_method(name) { function }
      end

      def execution_chain(name, functions:)
        define_method(name) { Chain.new(functions, context: self) }
      end
    end
  end
end
