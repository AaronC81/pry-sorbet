# frozen_string_literal: true

class Pry
  class Command
    class ShowInfo
      old_method_sections = instance_method(:method_sections)

      define_method(:method_sections) do |code_object|
        signature = defined?(T::Private::Methods) && T::Private::Methods.signature_for_method(code_object)

        signature_string = if signature
          build_signature_string(signature)
        else
          "Unknown"
        end

        old_method_sections.bind(self).(code_object).merge({
          sorbet: "\n\e[1mSorbet:\e[0m #{signature_string}"
        })
      end

      old_method_header = instance_method(:method_header)

      define_method(:method_header) do |code_object, line_num|
        old_method_header.bind(self).(code_object, line_num) \
          + method_sections(code_object)[:sorbet]
      end

      private

      def build_signature_string(signature)
        call_chain = []

        # Modifiers
        if signature.mode != "standard"
          # This is a string like "overridable_override"
          call_chain += signature.mode.split("_")
        end

        # Parameters
        all_parameters = []

        #   Positional
        all_parameters += signature.arg_types.map do |(name, type)|
          "#{name}: #{type}"
        end

        #   Splat
        if signature.rest_type
          all_parameters << "#{signature.rest_name}: #{signature.rest_type}"
        end

        #   Keyword
        all_parameters += signature.kwarg_types.map do |(name, type)|
          "#{name}: #{type}"
        end

        #   Double-splat
        if signature.rest_type
          all_parameters << "#{signature.keyrest_name}: #{signature.keyrest_type}"
        end

        #   Block
        if signature.block_type
          all_parameters << "#{signature.block_name}: #{signature.block_type}"
        end

        call_chain << "params(#{all_parameters.join(", ")})" if all_parameters.any?

        # Returns
        if signature.return_type.is_a?(T::Private::Types::Void)
          call_chain << "void"
        else
          call_chain << "returns(#{signature.return_type})"
        end

        "sig { #{call_chain.join(".")} }"
      end
    end
  end

  class Method
    # Maybe use a dict or something, I think methods are suitable keys
    define_method(:source_location) do
      loc = super()

      return loc unless defined?(T::Private::Methods)
      signature = T::Private::Methods.signature_for_method(@method)
      return loc unless signature

      return signature.method.source_location
    end
  end
end
