require 'sorbet-runtime'
require 'pry'

class Pry
  class Command
    class ShowInfo
      old_method_sections = instance_method(:method_sections)

      define_method(:method_sections) do |code_object|
        old_method_sections.bind(self).(code_object).merge({
          sorbet: "\n\e[1mSorbet:\e[0m It's here!"
        })
      end

      old_method_header = instance_method(:method_header)

      define_method(:method_header) do |code_object, line_num|
        #p code_object.instance_variable_get :@method

        old_method_header.bind(self).(code_object, line_num) \
          + method_sections(code_object)[:sorbet]
      end
    end
  end

  class Method
    define_method(:initialize) do |method, known_info = {}|
      @method = method
      @known_info = known_info

      # Read the first line of this method's source
      if method.source_location
        file_path, line = method.source_location
        first_source_line = IO.readlines(file_path)[line - 1]

        # This is how Sorbet replaces methods.
        # If Sorbet undergoes drastic refactorings, this may need to be updated!
        if first_source_line.strip == "T::Private::ClassUtils.replace_method(mod, method_name) do |*args, &blk|"
          puts "This method is a Sorbet method."

          @sorbet_method = true
          @sorbet_true_source_location = 
            T::Utils.signature_for_instance_method(@method.owner, @method.name).method.source_location

          # Replace the read method with its real source method
          p T::Utils.signature_for_instance_method(@method.owner, @method.name).method.source_location
          #@method = T::Utils.signature_for_instance_method(@method.owner, @method.name).method
        end

        # TODO: if anything goes wrong, silently ignore it - we were probably in
        # an eval context
      end

      puts "Building a method with #{method.source_location}"
    end

    #old_source_locaiton = instance_method(:source_location)

    define_method(:source_location) do
      puts "Calling overridden source_location on #{self.inspect}"

      if @sorbet_method
        puts "fetching source location for a Sorbet method"
        @sorbet_true_source_location
      else
        #source_location.bind(self).()
        super()
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