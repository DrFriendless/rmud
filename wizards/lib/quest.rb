require_relative '../../src/server/thing'

class Quest < Thing
  def initialize
    super
    @description = "This is an empty quest."
    @status = "You've done everything required by the quest."
    @xp_award = 0
  end

  # tell the user what the quest is and where it is up to.
  def status
    "#{@description} #{@status}"
  end

  def complete(owner)
    owner.complete_quest(persistence_key, @xp_award)
  end

  def after_properties_set
    @id = class_name
  end

  attr_reader :id
  attr_reader :description
  attr_reader :key
end

class BastQuest < Quest
  def initialize
    super
    @kills = 0
    @status = "You have killed the cat 0 times."
  end

  def record_kill(owner)
    @kills += 1
    @status = "You have killed the cat #{@kills} times."
    if @kills == 9
      complete(owner)
    end
  end

  def persist(data)
    data[:kills] = @kills
    @status = "You have killed the cat #{@kills} times."
  end

  def restore(data, by_persistence_key)
    @kills = data[:kills]
  end
end