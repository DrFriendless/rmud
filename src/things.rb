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
    @properties.each {
        |k,v| obj.instance_variable_set("@"+k, v)
    }
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

# A thing in the world
class Thing
  def initialize()
    @verbs = []
    verb(["get", :it]) { |response,command,match|
      if @location == command.body.location
        if self.can_be_carried?
          self.move_to(command.body)
          # todo tell the room
        else
          response.message = "You can't take that."
        end
        response.handled = true
      end
    }
    alias_verb(["take", :it], ["get", :it])
    verb(["drop", :it]) { |response,command,match|
      if @location == command.body
        self.move_to(command.body.location)
        # todo tell the room
      else
        response.message = "You don't have that."
      end
      response.handled = true
    }
  end

  attr_accessor :short
  attr_accessor :long
  attr_accessor :location
  attr_accessor :identity

  def is_called?(name)
    if @identity && !@identities
      @identities = @identity.split(",").each { |i| i.strip() }
    end
    @identities && @identities.include?(name)
  end

  def persist(data)
    data[persistence_key] = {} unless data[persistence_key]
  end

  def restore(data, by_persistence_key)
  end

  def persistence_key()
    @thingClass.persistence_key + "@#{object_id}"
  end

  def world()
    @thingClass.world
  end

  def move_to_location(key)
    loc = world.find_singleton(key) || world.find_singleton("lib/Room/lostandfound")
    move_to(loc)
  end

  def move_to(dest)
    if @location
      @location.remove(self)
    end
    @location = ()
    if dest
      dest.receive(self)
    end
    @location = dest
  end

  def create(s)
    tcr = ThingClassRef.new(@thingClass.wizard, s)
    world.instantiate_ref(tcr)
  end

  def method_missing(method, *args)
    puts method
    # now we can try to get dogs to quack.
  end

  def verb(pattern, &block)
    @verbs.push(Verb.new(pattern, block))
  end

  def alias_verb(pattern1, pattern2)
    @verbs.each { |v|
      if v.pattern == pattern2
        verb(pattern1, &v.block)
        return
      end
    }
    puts "Aliased verb not found #{pattern2}"
  end

  def handle(response, command)
    if !@verbs; return () end
    @verbs.each { |v|
      match = v.match(command, self)
      if match; v.handle(response, command, match) end
      if response.handled; return response end
    }
  end

  def can_be_carried?()
    true
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
    data[persistence_key] = {} unless data[persistence_key]
    data[persistence_key][:contents] = @contents.map { |t| t.persistence_key }
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

