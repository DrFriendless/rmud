# a thing that can't be taken but can define verbs, such as a landscape feature.

class Virtual < Thing
  include Directions
  include Singleton

  def initialize
    super
    @short = nil
    @long = nil
  end

  # properties loaded from YAML have been set
  def after_properties_set()
    super
    add_direction_verbs
    if @examine_it
      verb(["examine", :it]) { |response, command, match|
        response.message = @examine_it
        response.handled = true
      }
    end
    if @climb_it_no
      verb(["climb", :it]) { |response, command, match|
        response.message = @climb_it_no
        response.handled = true
      }
    end
    if @climb_it_yes
      @climb_it_yes = local_dest(@climb_it_yes)
      verb(["climb", :it]) { |response, command, match|
        command.body.go_to(@climb_it_yes, @climb_departure)
        response.handled = true
      }
    end
    if @enter_it
      @enter_it = local_dest(@enter_it)
      verb(["enter", :it]) { |response, command, match|
        command.body.go_to(@enter_it, @enter_departure)
        response.handled = true
      }
    end
    if @enter
      @enter = local_dest(@enter)
      verb(["enter"]) { |response, command, match|
        command.body.go_to(@enter, @enter_departure)
        response.handled = true
      }
    end
  end

  def carriable?
    false
  end

  attr_reader :short
  attr_reader :long
  attr_reader :destination
end