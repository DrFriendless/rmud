class Arcadia < Outdoor
  def lit?
    true
  end

  def publish_to_room(effect)
    super unless effect.is_a? TimeOfDayEffect
  end
end