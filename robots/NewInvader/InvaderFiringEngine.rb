

class InvaderFiringEngine
  attr_accessor :turn_gun
  attr_accessor :firepower
  attr_accessor :robot
  attr_accessor :target_enemy
  attr_accessor :math

  def initialize invader
    @robot = invader
    @math = InvaderMath.new
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

  def power_based_on_distance
    #this = InvaderPoint.new(@robot.x, @robot.y)
    #distance = @math.distance_between_objects(this, @target_enemy)
    #firepower = 3.0 - (distance/780)
    #return firepower
    0.1
  end

  def dont_fire_at_friend
    return if @robot.friend.nil?
    friend_direction = @math.degree_from_point_to_point @robot.location, @robot.friend
    @firepower = 0 if @math.radar_heading_between?(friend_direction, @math.rotated(@robot.gun_heading,3), @math.rotated(@robot.gun_heading, -3))
    return if @robot.friend_edge.nil?
    @firepower = 0 if @robot.gun_heading == @robot.opposite_edge and @robot.distance_to_edge(@robot.friend_edge.to_i) < (2 * @robot.size + 1)
  end

  def point_gun direction
    if (@robot.gun_heading != direction)
      @turn_gun = @math.turn_toward(@robot.gun_heading, direction)
      @turn_gun = [[@turn_gun, 30].min,-30].max
    end
  end
end

class InvaderGunnerHeadToEdge <  InvaderFiringEngine
  def aim
    @turn_gun = 10
  end

  def shoot
    @firepower = 3 unless @robot.events['robot_scanned'].empty?
  end
end

class InvaderGunnerProvidedTarget < InvaderFiringEngine
  def aim
    @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    point_gun @math.degree_from_point_to_point(@robot.location_next_tick, @target_enemy) + Math.sin(@robot.time)
  end

  def shoot
    @firepower = power_based_on_distance
  end
end

class InvaderGunnerFoundTarget < InvaderFiringEngine
  def aim
    @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
    point_gun @math.degree_from_point_to_point(@robot.location_next_tick, @target_enemy) + Math.sin(@robot.time)
  end

  def shoot
    @firepower = power_based_on_distance
  end
end

class InvaderGunnerSearching < InvaderFiringEngine
  def aim
    point_gun @robot.opposite_edge + Math.sin(@robot.time)
  end

  def shoot
    @firepower = 0.1
  end
end

class InvaderGunnerShootOppositeCorner < InvaderFiringEngine
  def aim
    point_gun desired_gun_heading # + Math.sin(@robot.time)
  end

  def desired_gun_heading
    @math.rotated(@robot.heading_of_edge, @robot.current_direction * -90)
  end

  def shoot
    if @robot.gun_heading == desired_gun_heading
      @firepower = 3.0
    end
  end
end
