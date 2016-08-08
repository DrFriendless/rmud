# A PlayerBody is special because it can appear and disappear as players log in and out.
class PlayerBody < Body
  include HasExperience
  include HasAlignment
  include HasScore

  attr_accessor :name
  attr_accessor :effect_callback
  attr_writer :short
  attr_writer :long

  def initialize
    super
    initialize_score
    initialize_xp
    initialize_alignment
    @loc = "lib/Room/lostandfound"
  end

  def after_properties_set
    super
    receive_into_container(world.create("lib/PlayerSoul/default"))
  end

  def persistence_key
    "player/#{@name}"
  end

  def persist(data)
    super
    data[persistence_key][:name] = @name
  end

  def player_persistence_data()
    data = {}
    data[:body] = 'lib/PlayerBody/default'
    data[:loc] = @location.persistence_key
    data[:gp] = @gp
    data[:questxp] = @questxp
    data[:combatxp] = @combatxp
    data[:score] = @score
    data
  end

  def restore_player_persistence_data(data)
    p "Restoring #{name} => #{data}"
    @gp = (data && data[:gp]) || 0
    @combatxp = (data && data[:combatxp]) || 0
    @questxp = (data && data[:quetxp]) || 0
    @score = (data && data[:score]) || 0
    loc = data && data[:loc]
    # some rooms are bad to restart in.
    if !loc || world.find_singleton(loc)&.norestart
      loc = "lib/Room/hallofdoors"
    end
    p "goto loc #{loc}"
    move_to_location(loc)
  end

  def effect(effect)
    if @effect_callback
      e = effect.message_for(self)
      if e; @effect_callback.effect(e) end
    end
  end

  def tell(message)
    ob = Observation.new(message)
    @effect_callback.effect(ob)
  end

  def attacked_by(other)
    # let the player choose what to do.
  end

  def link_dead
    !effect_callback || !effect_callback.ping?
  end

  def xp_for_killing
    0
  end
end

