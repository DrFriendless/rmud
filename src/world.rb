require 'psych'
require 'yaml'
require_relative './thingutil'
require_relative './lib'

class World
  def initialize(database)
    @database = database
    @singletons = []
    @all_things = []
    @thingClasses = {}
    @all_players = []
  end

  def load()
    load_lib
    restore(@database.load)
  end

  # load definitions of objects from YAML.
  def load_lib()
    yaml = Psych.load_file("lib/lib.yml")
    yaml.each {
        |k,v| load_from_file("lib", k, v)
    }
    @all_things += @singletons
  end

  def load_from_file(wizard, key, props)
    tcr = ThingClassRef.new(wizard, key)
    tc = tcr.thingclass(self, props)
    @thingClasses[tcr.key] = tc
    if tc.ruby_class.ancestors.include? Singleton
      obj = tc.instantiate
      @singletons.push obj
    end
  end

  def persist()
    @database.save(persist_data)
    @all_players.each { |p|
      @database.save_player(p.persist_player)
    }
  end

  def persist_data()
    data = {}
    @all_things.
        select { |s| !s.is_do_not_persist? }.
        each { |s| s.persist(data) }
    data
  end

  def instantiate_ref(thingclassref)
    thing = @thingClasses[thingclassref.key].instantiate
    @all_things.push(thing)
    thing
  end

  def instantiate_class(thingclass)
    thing = thingclass.instantiate
    @all_things.push(thing)
    thing
  end

  def instantiate_player(username)
    thing = instantiate_class(@thingClasses["lib/PlayerBody/default"])
    # TODO - description of the player and the class of their body should be stored in the database.
    thing.name = username
    thing.short = username
    thing.long = "#{username} is a player."
    @all_things.push(thing)
    @all_players.push(thing)
    thing
  end

  def remove_player(body)
    @all_things.delete(body)
    @all_players.delete(body)
  end

  def find_singleton(key)
    @singletons.each { |s|
      if s.persistence_key == key
        puts "Found #{key}"
        return s
      end
    }
  end

  # restore data from database
  def restore(data)
    by_persistence_key = {}
    data.each { |t|
      id = t[:_id]
      if id.index('@')
        # non-singleton
        key = id[0..id.index('@')-1]
        tc = @thingClasses[key]
        by_persistence_key[id] = instantiate_class(tc)
      else
        # singleton
        by_persistence_key[id] = find_singleton(id)
      end
    }
    data.each { |vs|
      id = vs[:_id]
      t = by_persistence_key[id]
      if t
        t.restore(vs, by_persistence_key)
      end
    }
    # if we didn't have a record of something, tell it has just been created
    @singletons.each { |s|
      if !by_persistence_key[s.persistence_key]
        puts "on_world_create #{s.persistence_key}"
        s.on_world_create()
      end
    }
  end
end
