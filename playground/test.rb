require 'sorbet-runtime'
require 'pry'

class Pry
  class Command
    class ShowInfo
      old_method_sections = instance_method(:method_sections)

      define_method(:method_sections) do |code_object|
        old_method_sections.bind(self).(code_object).merge({
          sorbet: "\n\e[1mSorbet:\e[0m ???"
        })
      end

      old_method_header = instance_method(:method_header)

      define_method(:method_header) do |code_object, line_num|
        old_method_header.bind(self).(code_object, line_num) \
          + method_sections(code_object)[:sorbet]
      end
    end
  end

  class Method
    define_method(:source_location) do
      loc = super()

      file_path, line = loc
      return loc unless file_path && File.exists?(file_path)

      first_source_line = IO.readlines(file_path)[line - 1]

      # This is how Sorbet replaces methods.
      # If Sorbet undergoes drastic refactorings, this may need to be updated!
      if first_source_line.strip == "T::Private::ClassUtils.replace_method(mod, method_name) do |*args, &blk|"
        T::Utils.signature_for_instance_method(@method.owner, @method.name).method.source_location
      else
        loc
      end
    end
  end
end

module X
  extend T::Sig

  sig { returns(Integer) }
  def self.a
    3
  end
end

x = 4

binding.pry

puts X.a