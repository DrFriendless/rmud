# things that happen that can be observed in a location

class Effect
  def method_missing(method, *args)
    false
  end
end

class TimeOfDayEffect < Effect
  def initialize(s)
    @message = s
  end

  attr_accessor :message
end