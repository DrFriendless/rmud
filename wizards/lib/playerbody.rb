require_relative '../lib/body'

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
    @loc = "lib/GreatLibrary/library"
    @ghost = false
    @completed_quests = []
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
    data[:name] = @name
  end

  def player_persistence_data()
    data = {}
    data[:body] = 'lib/PlayerBody/default'
    data[:loc] = @location.persistence_key
    data[:gp] = @gp
    data[:questxp] = @questxp
    data[:combatxp] = @combatxp
    data[:score] = @score
    data[:ghost] = @ghost
    data[:wizard] = @wizard
    data[:completed_quests] = @completed_quests
    data
  end

  def restore_player_persistence_data(data)
    p "Restoring #{name} => #{data}"
    @gp = (data && data[:gp]) || 0
    @combatxp = (data && data[:combatxp]) || 0
    @questxp = (data && data[:quetxp]) || 0
    @score = (data && data[:score]) || 0
    @wizard = (data && data[:wizard]) || 0
    @ghost = (data && data[:ghost])
    @completed_quests = (data && data[:completed_quests]) || []
    loc = data && data[:loc]
    # some rooms are bad to restart in.
    if !loc || world.find_singleton(loc)&.norestart
      loc = 'lib/Room/hallofdoors'
    end
    p "restored to location #{loc}"
    move_to_location(loc)
  end

  def complete_quest(id, xp)
    @completed_quests.push(id)
    add_quest_experience(xp)
    tell("You gained #{xp} quest XP.")
  end

  def has_quest(id)
    @completed_quests.include?(id) || (@contents.map { |x| x.class_name }.include?(id))
  end

  def find_quest(id)
    qs = @contents.select { |x| (x.is_a? Quest) && (x.id == id) }
    qs[0] if qs.length > 0
  end

  def effect(effect)
    if @effect_callback
      e = effect.message_for(self)
      if e; @effect_callback.effect(e) end
    end
  end

  def tell(message)
    ob = Observation.new(message)
    # sometimes a tell might occur before the player is fully loaded
    @effect_callback.effect(ob) if @effect_callback
  end

  def attacked_by(other)
    return if ghost?
    # let the player choose what to do.
  end

  def link_dead
    !effect_callback || !effect_callback.ping?
  end

  def xp_for_killing
    0
  end

  def you_died(killed_by)
    super
    @victim = nil
    @ghost = true
    @short = "ghost of Mangrove"
    @poison = 0
    tell("Your soul leaves your body.")
  end

  def receive_into_container(thing)
    if ghost? && ((thing.is_a? Item) || (thing.is_a? Gold))
      location.receive_into_container(thing)
    else
      super
    end
  end

  def ghost?
    @ghost
  end

  def reincarnate
    @ghost = false
  end
end

