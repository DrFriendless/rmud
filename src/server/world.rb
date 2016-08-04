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

  def load
    load_wizards
    restore(@database.load)
    reset
  end

  # load definitions of objects from YAML.
  def load_wizards
    lib = ()
    wizdirs = []
    singletons = {}
    move_tos = {}
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
      load_wizard(dir, singletons)
    }
    singletons.each { |tc, destination|
      obj = tc.instantiate
      @singletons.push(obj)
      @all_things.push(obj)
      if destination; move_tos[obj] = dest(tc.wizard, destination) end
    }
    move_tos.each { |obj,dest|
      obj.move_to(find_singleton(dest))
    }
  end

  def load_wizard(dir, singletons)
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
      if filename.end_with?('.yml')
        abs_fn = "#{dir.path}/#{filename}"
        yaml = Psych.load_file(abs_fn)
        yaml.each {
            |k,v| load_from_file(wizard, k, v, singletons)
        }
      end
    }
  end

  def dest(wizard, v)
    (v && v.count("/") == 1) ? wizard + '/' + v : v
  end

  def load_from_file(wizard, key, props, singletons)
    tcr = ThingClassRef.new(wizard, key)
    tc = tcr.thingclass(self, props)
    @thingClasses[tcr.key] = tc
    if tc.ruby_class.ancestors.include? Singleton
      singletons[tc] = props['destination']
    end
  end

  def persist
    data = {}
    @all_things.select { |s| !s.do_not_persist? }.each { |s| s.persist(data) }
    @database.save(data)
    @all_players.each { |p| @database.save_player(p.name, p.player_persistence_data) }
  end

  def create(key)
    thing = @thingClasses[key].instantiate
    @all_things.push(thing)
    thing
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
      obj.location.remove_from_container(obj)
    end
    if obj.is_a? Singleton
      @singletons.delete(obj)
    end
    @all_things.delete(obj)
    p "Destroyed #{obj.persistence_key}"
  end

  def instantiate_player(username)
    data = @database.retrieve_player(username)
    body_class = (data && data[:body]) || 'lib/PlayerBody/default'
    thing = instantiate_class(@thingClasses[body_class] || @thingClasses['lib/PlayerBody/default'])
    thing.name = username
    thing.short = username
    thing.long = "#{username} is a player."
    thing.restore_player_persistence_data(data)
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
    body.move_to_location("lib/Room/lostandfound")
  end

  def find_singleton(key)
    @singletons.each { |s|
      if s.persistence_key == key
        return s
      end
    }
    nil
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
      else
        # singleton
        by_persistence_key[id] = find_singleton(id)
        puts "did not load #{id}" unless by_persistence_key[id]
      end
    }
    data.each { |vs|
      id = vs[:_id]
      t = by_persistence_key[id]
      t.restore(vs, by_persistence_key) if t
    }
    # if we didn't have a record of something, tell it has just been created
    @singletons.each { |s|
      s.on_world_create unless by_persistence_key[s.persistence_key]
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