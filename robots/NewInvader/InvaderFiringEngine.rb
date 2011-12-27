require 'InvaderMath'

class InvaderFiringEngine
  include InvaderMath

  attr_accessor :turn_gun
  attr_accessor :firepower

  def initialize invader
    @robot = invader
    @turn_gun = 0
    @firepower = 0
    @last_target_time = 0
    @target_enemy = nil
  end

  def fire
    @turn_gun = 0
    @firepower = 0
    if @robot.at_edge
      target_an_enemy
      aim
      shoot
      dont_fire_at_friend
    else
      @turn_gun = 10
      @firepower = 3 unless @robot.events['robot_scanned'].empty?
    end
  end

  private

  def target_an_enemy
    @last_target_time = @robot.time unless @robot.broadcast_enemy.nil?
    @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    @last_target_time = @robot.time unless @robot.found_enemy.nil?
    @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
    @target_enemy = nil unless @robot.time - 15 < @last_target_time
  end

  def power_based_on_distance
    this = InvaderPoint.new(@robot.x, @robot.y)
    distance = distance_between_objects(this, @target_enemy)
    firepower = 3.0 - (distance/780)
    return firepower
    #0.1
  end

  def dont_fire_at_friend
    return if @robot.friend.nil?
    friend_direction = degree_from_point_to_point @robot.location, @robot.friend
    @firepower = 0 if radar_heading_between?(friend_direction, rotated(@robot.gun_heading,3), rotated(@robot.gun_heading, -3))
    return if @robot.friend_edge.nil?
    @firepower = 0 if @robot.gun_heading == @robot.opposite_edge and @robot.distance_to_edge(@robot.friend_edge.to_i) < (2 * @robot.size + 1)
  end

  def point_gun direction
    if (@robot.gun_heading != direction)
      @turn_gun = turn_toward(@robot.gun_heading, direction)
      @turn_gun = [[@turn_gun, 30].min,-30].max
    end
  end

  def aim
    if @target_enemy.nil?
      point_gun @robot.opposite_edge + Math.sin(@robot.time)
    else
      point_gun degree_from_point_to_point(@robot.location_next_tick, @target_enemy) + Math.sin(@robot.time)
    end
  end

  def shoot
    if @target_enemy.nil?
      @firepower = 0.1
    else
      @firepower = power_based_on_distance
    end
  end
end
