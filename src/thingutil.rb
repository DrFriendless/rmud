# Code related to Things. The Thing class is big and gets its own file.

# properties that should not be set by the YAML.
BANNED_PROPERTIES = ["contents", "verbs"]

class ThingClass
  def initialize(tcr, p, rc, world)
    @thing_class_ref = tcr
    @properties = p
    @ruby_class= rc
    @world = world
  end

  attr_reader :properties
  attr_reader :ruby_class
  attr_reader :world

  def wizard()
    @thing_class_ref.wizard
  end

  def instantiate
    obj = @ruby_class.new
    obj.instance_variable_set(:@thingClass, self)
    BANNED_PROPERTIES.each { |p| @properties.delete(p) }
    @properties.each { |k,v|
      obj.instance_variable_set("@"+k, v)
    }
    obj.after_properties_set
    obj
  end

  def persistence_key()
    @thing_class_ref.key
  end
end

class ThingClassRef
  def initialize(w, s)
    fields = s.split("/")
    @wizard = fields[-3] || w
    @clazz = fields[-2]
    @id = fields[-1]
  end

  attr_reader :wizard

  def key()
    "#{@wizard}/#{@clazz}/#{@id}"
  end

  def thingclass(world, props)
    clazz = Object::const_get(@clazz)
    ThingClass.new(self, props, clazz, world)
  end
end

class Verb
  def initialize(pattern, block)
    @pattern = pattern
    @block = block
  end

  attr_reader :pattern
  attr_reader :block

  def handle(response, command, match)
    @block.call(response, command, match)
  end

  def match(command, subject)
    match_words(@pattern, command.words, subject)
  end

  def match_words(pattern, words, subject)
    if pattern.empty? && words.empty?; return true end
    if pattern.empty? || words.empty?; return false end
    if pattern[0] == :star || pattern[0] == "*"
      (0..words.size).each { |n| if match_words(pattern.drop(1), words.drop(n), subject); return true end }
      return false
    elsif pattern[0] == :it
      (1..words.size).each { |n|
        if subject.is_called?(words[0,n].join(" ")) && match_words(pattern.drop(1), words.drop(n), subject)
          return true
        end
      }
      return false
    else
      (pattern[0] == words[0]) && match_words(pattern.drop(1), words.drop(1), subject)
    end
  end
end

# marker to indicate that there is one of these and it always exists.
module Singleton
  def persistence_key()
    @thingClass.persistence_key
  end
end

module Container
  def initialize_contents()
    @contents = []
  end

  attr_reader :contents

  def persist_contents(data)
    data[persistence_key] ||= {}
    data[persistence_key][:contents] = @contents.
        select { |t| !t.is_do_not_persist? }.
        map { |t| t.persistence_key }
  end

  def restore_contents(data, by_persistence_key)
    contents = data[:contents]
    contents.each { |key|
      if by_persistence_key[key]
        by_persistence_key[key].move_to(self)
      else
        puts "Did not find #{key}"
      end
    }
  end

  def remove(thing)
    if @contents.include? thing
      @contents.delete thing
    end
  end

  def receive(thing)
    if !@contents.include? thing
      @contents.push thing
    end
  end
end

