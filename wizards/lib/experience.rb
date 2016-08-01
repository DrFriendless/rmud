module HasExperience
  def initialize_gold
    @xp = 0
  end

  def add_experience(n)
    @xp += n
  end

  attr_accessor :xp
end