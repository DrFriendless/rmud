class Body < Thing
  include Container

  def initialize()
    super
    initialize_contents
  end

  def persist(data)
    super
    persist_contents(data)
    data[persistence_key] = {} unless data[persistence_key]
    data[persistence_key][:maxhp] = @maxhp
    data[persistence_key][:hp] = @hp
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
    @maxhp = data[:maxhp]
    @hp = data[:hp]
  end
end

class PlayerBody < Body
  attr_accessor :name

  def persistence_key()
    "lib/PlayerBody/#{name}"
  end

  def handle(response, command)
    if command == "look"
      response.handled = true
      response.message = "whut"
    end
    if command == "yes"
      response.handled = true
      response.message = "Computer says YES"
    elsif command == "no"
      response.handled = true
    end
  end
end

class Creature < Body

end

class Room < Thing
  include Container
  include Singleton

  def initialize()
    super
    initialize_contents
  end

  def persist(data)
    super
    persist_contents(data)
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
  end

  def on_world_create()
    cs = @thingClass.properties["contains"]
    if cs then
      refs = cs.split()
      refs.map { |rs|
        create(rs).move_to(self)
      }
    end
  end
end