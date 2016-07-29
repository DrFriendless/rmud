require 'psych'
require 'yaml'
require_relative './thingutil'

class World
  def initialize(database)
    @database = database
    @singletons = []
    @all_things = []
    @thingClasses = {}
    @all_players = []
    @time = 0
    @time_of_day = 0
  end

  attr_reader :time
  attr_reader :time_of_day

  def load()
    load_wizards
    restore(@database.load)
  end

  # load definitions of objects from YAML.
  def load_wizards()
    lib = ()
    wizdirs = []
    Dir["./wizards/*"].each { |filename|
      f = File.new(filename)
      if File.directory?(f)
        if File.basename(f) == "lib"
          lib = f
        else
          wizdirs.push(f)
        end
      end
    }
    wizdirs = [lib] + wizdirs
    wizdirs.each { |dir|
      load_wizard(dir)
    }
    @all_things += @singletons
  end

  def load_wizard(dir)
    wizard = File.basename(File.new(dir))
    # load Ruby
    Dir.entries(File.absolute_path(dir.path)).each { |filename|
      if filename.end_with?(".rb")
        abs_fn = "#{dir.path}/#{filename}"
        require abs_fn
      end
    }
    # load YAML
    Dir.entries(File.absolute_path(dir.path)).each { |filename|
      if filename.end_with?(".yml")
        abs_fn = "#{dir.path}/#{filename}"
        yaml = Psych.load_file(abs_fn)
        yaml.each {
            |k,v| load_from_file(wizard, k, v)
        }
      end
    }
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
  end

  def persist_data()
    data = {}
    @all_things.
        each { |s| s.persist(data) }
    data
  end

  def instantiate_ref(thingclassref)
    if !@thingClasses[thingclassref.key]
      puts "Can't instantiate #{thingclassref.key}."
      return
    end
    thing = @thingClasses[thingclassref.key].instantiate
    @all_things.push(thing)
    thing
  end

  def instantiate_gold(s)
    n = parse_money(s)
    gold = instantiate_class(@thingClasses["lib/Gold/default"])
    gold.add_gold(n)
    gold
  end

  def instantiate_class(thingclass)
    thing = thingclass.instantiate
    @all_things.push(thing)
    thing
  end

  def destroy(obj)
    if obj.location
      obj.location.remove(obj)
    end
    if obj.is_a? Singleton
      @singletons.delete(obj)
    end
    @all_things.delete(obj)
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

  def find_player(username)
    @all_players.select { |p| p.name == username }.first
  end

  def remove_player(body)
    @all_things.delete(body)
    @all_players.delete(body)
  end

  def find_singleton(key)
    @singletons.each { |s|
      if s.persistence_key == key
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
        if tc
          by_persistence_key[id] = instantiate_class(tc)
        else
          puts "No thing class #{key}."
        end
      elsif id.start_with?("player")
        by_persistence_key[id] = instantiate_player(t[:name])
        # where the player will go to when they log in again.
        by_persistence_key[id].loc = t[:loc]
      else
        # singleton
        by_persistence_key[id] = find_singleton(id)
        if !by_persistence_key[id]
          p "did not load #{id}"
        end
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
        s.on_world_create
      end
    }
  end

  def heartbeat
    # ticks since epoch
    @time = Time.now.to_i / 2
    @time_of_day = @time % 600
    @all_things.each { |t| t.heartbeat(@time, @time_of_day) }
  end

  def reset
    @singletons.each { |t| t.reset }
  end
end
