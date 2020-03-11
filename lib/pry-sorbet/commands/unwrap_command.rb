# frozen_string_literal: true

module PrySorbet
  class UnwrapCommand < Pry::ClassCommand
    match "sorbet-unwrap"
    group "Sorbet"
    description "Unwrap all methods wrapped by Sorbet runtime"
    command_options requires_gem: "sorbet-runtime"

    banner <<~BANNER
      Usage: sorbet-unwrap

      Unwrap all methods wrapped by Sorbet runtime
    BANNER

    def process
      return unless defined?(T::Private::Methods)

      # For each signature wrapper, call the lambda associated with the wrapper
      # to finalize the method wrapping
      sig_wrappers = T::Private::Methods.instance_variable_get(:@sig_wrappers) || {}
      sig_wrappers.values.each do |sig_wrapper|
        sig_wrapper.call
      rescue NameError
      end

      # Now that all methods are properly wrapped with optimized wrappers
      # we can replace them with the original methods
      signatures_by_method = T::Private::Methods.instance_variable_get(:@signatures_by_method) || {}
      signatures_by_method.values.each do |signature|
        T::Configuration.without_ruby_warnings do
          T::Private::DeclState.current.without_on_method_added do
            signature.owner.send(:define_method, signature.method_name, signature.method)
          end
        end
      end
    end
  end
end

Pry::Commands.add_command(PrySorbet::UnwrapCommand)
