require 'robot'

class PairClobber
  include Robot
  attr_reader :partner

  GAME_RULES_ROBOT_TURN_LIMIT = 10
  MAX_DISTANCE_FROM_CENTER  = 700
  DESIRED_DISTANCE_FROM_PARTNER = 500..800
  MIN_PARTNER_SAFETY_ANGLE = 12
  GUN_TURN_RANGE = 4..14
  FIRE_POWER = 2.9
  DESIRED_DISTANCE_FROM_ENEMY = 550..625
  DODGE = -20

  def initialize
    @logbook = Logbook.new(self)
    @ticks_since_enemy_seen = 0
    @gun_turn_direction = 1
    @gun_turn_degrees = GUN_TURN_RANGE.max
  end

  def my_location
    Point.new(@x, @y)
  end

  def my_heading
    Heading.new(heading)
  end

  def tick events
    @logbook.take_reading!
    set_ticks_since_enemy_scanned_and_desired_gun_move!
    if shootable_enemy?
      @logbook.shootable_enemy_sighted!
      fire FIRE_POWER
    end
    turned_robot_degrees = move_robot!
    turn_gun_accounting_for turned_robot_degrees
    broadcast my_location.to_msg
  end

  def partner_location
    @logbook.partner_location ? @logbook.partner_location : center.dup
  end

  def set_ticks_since_enemy_scanned_and_desired_gun_move!
    if shootable_enemy?
      @ticks_since_enemy_seen = 0
      @gun_turn_degrees = GUN_TURN_RANGE.min
    else
      @ticks_since_enemy_seen += 1
      reverse_gun_if_have_not_seen_enemy_lately
    end
  end

  def reverse_gun_if_have_not_seen_enemy_lately
    if [1, 4].include? @ticks_since_enemy_seen
      @gun_turn_direction *= -1
      @gun_turn_degrees = GUN_TURN_RANGE.max
    end
  end

  def shootable_enemy?
    @logbook.current_reading.robot_scanned? and not_pointing_toward_partner?
  end

  def turn_gun_accounting_for turned_bot
    magnitude_of_turned_bot = [turned_bot.abs,GAME_RULES_ROBOT_TURN_LIMIT].min
    desired_gun_turn =  @gun_turn_degrees * @gun_turn_direction
    if turned_bot > 0
      desired_gun_turn -=  magnitude_of_turned_bot
    else
      desired_gun_turn +=  magnitude_of_turned_bot
    end
    turn_gun desired_gun_turn
  end

  def partner_not_within_angle(threshold)
    angle = Heading.new(gun_heading).shortest_turn_toward_heading(my_location.degrees_to partner_location)
    angle.abs > threshold
  end

  def not_pointing_toward_partner?
    partner_not_within_angle(MIN_PARTNER_SAFETY_ANGLE) || @logbook.current_reading.partner_dead
  end

  def enemy_too_close?
    @logbook.last_known_enemy_distance && (@logbook.last_known_enemy_distance < DESIRED_DISTANCE_FROM_ENEMY.min)
  end

  def enemy_too_far_away?
    @logbook.last_known_enemy_distance && (@logbook.last_known_enemy_distance > DESIRED_DISTANCE_FROM_ENEMY.max)
  end

  def partner_alive?
    @logbook.partner_alive?
  end

  def partner_too_close?
    (my_location.distance_to partner_location) < DESIRED_DISTANCE_FROM_PARTNER.min && partner_alive?
  end

  def center_too_far_away?
    (my_location.distance_to center) > MAX_DISTANCE_FROM_CENTER
  end

  def turn_towards_enemy
    my_heading.shortest_turn_toward_heading(@logbook.last_known_enemy_heading + DODGE)
  end

  def turn_away_from_enemy
    my_heading.shortest_turn_toward_heading(@logbook.last_known_enemy_heading + 180)
  end

  def desired_turn
    case
      when center_too_far_away?  then shortest_turn_toward_point center
      when partner_too_close?    then turn_away_from_point partner_location
      when enemy_too_close?      then turn_away_from_enemy
      when enemy_too_far_away?   then turn_towards_enemy
      else 0
    end
  end

  def move_robot!
    degrees_to_turn = desired_turn
    turn degrees_to_turn
    accelerate 1
    degrees_to_turn
  end

  def center
    height = battlefield_height || 1600
    width = battlefield_width || 1600
    Point.new(width / 2,height / 2)
  end

  def shortest_turn_toward_point to_point
    my_heading.shortest_turn_toward_heading(my_location.degrees_to to_point)
  end

  def turn_away_from_point to_point
    -1 * shortest_turn_toward_point(to_point)
  end

  class Heading
    SHORTEST_POSSIBLE_TURNS = -180..180
    WHOLE_TURN = 360

    def initialize degrees
      @degrees = degrees
    end

    def shortest_turn_toward_heading other_heading
      proposed_turn = other_heading - @degrees
      case
        when SHORTEST_POSSIBLE_TURNS.include?(proposed_turn) then proposed_turn
        when proposed_turn < SHORTEST_POSSIBLE_TURNS.min     then proposed_turn + WHOLE_TURN
        when proposed_turn > SHORTEST_POSSIBLE_TURNS.max     then proposed_turn - WHOLE_TURN
      end
    end
  end

  class Point
    protected
    attr_reader :x,:y
    public
    def initialize(x,y)
      @x,@y = x,y
    end

    def distance_to(other)
      Math.hypot(other.x - @x, other.y - @y)
    end

    def degrees_to(other)
      Math.atan2(@y - other.y, other.x - @x) / Math::PI * 180 % 360
    end

    def to_msg
      "#{x.round}|#{y.round}"
    end
  end

  class Readout
    attr_reader :partner_dead
    attr_reader :partner_location

    def initialize(robot)
      @robot = robot
      check_partner_msgs
    end

    def robot_scanned?
      not @robot.events['robot_scanned'].empty?
    end

    def nearest_scanned_robot_distance
      @robot.events['robot_scanned'].min[0]
    end

    def partner
      @robot.partner
    end

    private
    def check_partner_msgs
      partner_said = @robot.events['broadcasts']
      if partner_said.empty?
       @partner_dead = true
      else
        @partner_dead = false
        x,y = partner_said[0][0][0..-1].split('|').map{|s| s.to_f}
        @partner_location = Point.new(x,y)
      end
    end
  end

  class Logbook
     attr_reader :last_known_enemy_heading, :last_known_enemy_distance

     def initialize(robot)
       @robot = robot
       @log = []
     end

     def current_reading
       @log.last
     end

     def partner_alive?
       !current_reading.partner_dead
     end

     def partner_location
       current_reading.partner_location
     end

     def take_reading!
       @log << Readout.new(@robot)
     end

     def shootable_enemy_sighted!
       @last_known_enemy_distance = current_reading.nearest_scanned_robot_distance
       @last_known_enemy_heading = @robot.gun_heading
     end
  end
end
