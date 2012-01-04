require 'InvaderMath'

class InvaderFiringEngine
  include InvaderMath

  attr_accessor :turn_gun
  attr_accessor :firepower

  def initialize invader
    @robot = invader
    @turn_gun = 0
    @firepower = 0
  end

  def fire
    @turn_gun = 0
    @firepower = 0
    aim
    shoot
    dont_fire_at_friend
  end

  private
  def target
    @robot.target
  end

  def power_based_on_distance
    this = InvaderPoint.new(@robot.x, @robot.y)
    distance = distance_between_objects(this, target)
    firepower = 3.0 - (distance/780)
    return firepower
    #0.3
    #3.0
  end

  def dont_fire_at_friend
    return if @robot.friend.nil?
    friend_direction = degree_from_point_to_point @robot.location, @robot.friend
    @firepower = 0 if radar_heading_between?(friend_direction, rotated(@robot.gun_heading,3), rotated(@robot.gun_heading, -3))
    return if @robot.friend_edge.nil?
    @firepower = 0 if @robot.gun_heading == @robot.opposite_edge and @robot.my_distance_to_edge(@robot.friend_edge.to_i) < (2 * @robot.size + 1)
  end

  def point_gun direction
    if (@robot.gun_heading != direction)
      @turn_gun = turn_toward(@robot.gun_heading, direction)
      @turn_gun = [[@turn_gun, 30].min,-30].max
    end
  end

  def aim
    if target.nil?
      point_gun @robot.opposite_edge
    else
      current_target = target
      if !@robot.enemy_speed.nil?
        current_target = aim_ahead_of_target
      end
      point_gun degree_from_point_to_point(@robot.location_next_tick, current_target)
    end
  end

  def aim_ahead_of_target
    current_target = target
    enemy_speed = @robot.enemy_speed
    enemy_x_velocity = enemy_speed * Math.cos(@robot.enemy_direction.to_rad)
    enemy_y_velocity = enemy_speed * Math.sin(@robot.enemy_direction.to_rad)
    x_distance = (current_target.x - @robot.location_next_tick.x)
    y_distance = (current_target.y - @robot.location_next_tick.y)
    new_x = current_target.x
    new_y = current_target.y
    time = 1
    while (x_distance/time + enemy_x_velocity).abs > 30 or (y_distance/time - enemy_y_velocity).abs > 30
      time = time + 1
      new_x = new_x + enemy_x_velocity
      new_y = new_y - enemy_y_velocity
    end
    InvaderPoint.new(new_x, new_y)
    #x_component = (x_distance/time + enemy_x_velocity)/30
    #y_component = (y_distance/time + enemy_y_velocity)/30

  end

  def shoot
    if target.nil?
      @firepower = 0.1
    else
      @firepower = power_based_on_distance
    end
  end
end
