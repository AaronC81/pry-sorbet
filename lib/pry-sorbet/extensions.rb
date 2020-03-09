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

      file_path, line = loc
      return loc unless file_path && File.exists?(file_path)

      first_source_line = IO.readlines(file_path)[line - 1]

      # This is how Sorbet replaces methods.
      # If Sorbet undergoes drastic refactorings, this may need to be updated!
      initial_sorbet_line = "T::Private::ClassUtils.replace_method(mod, method_name) do |*args, &blk|"
      replaced_sorbet_line = "mod.send(:define_method, method_sig.method_name) do |*args, &blk|"

      if [initial_sorbet_line, replaced_sorbet_line].include?(first_source_line.strip)
        T::Private::Methods.signature_for_method(@method).method.source_location
      else
        loc
      end
    end
  end
end
