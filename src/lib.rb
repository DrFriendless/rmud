class Body < Thing
  include Container

  def initialize()
    super
    initialize_contents
  end

  def persist(data)
    super
    persist_contents(data)
    data[:maxhp] = @maxhp
    data[:hp] = @hp
  end
end

class PlayerBody < Body
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

  def loaded_from_file()
    cs = @thingClass.properties["contains"]
    if cs then
      refs = cs.split()
      refs.map { |rs|
        create(rs).move_to(self)
      }
    end
  end
end