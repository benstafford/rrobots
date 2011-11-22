require 'robot'

class Pair
  include Robot
  attr_accessor :partner

  MAX_ROBOT_TURN = 10 #game rules
  MAX_DISTANCE_FROM_CENTER  = 725
  MIN_DISTANCE_FROM_PARTNER = 410
  MAX_DISTANCE_FROM_PARTNER = 590
  MIN_PARTNER_SAFETY_ANGLE = 14
  MIN_GUN_TURN = 16
  FIRE_POWER = 2.8

  def initialize
    @partner = center.dup
    @partner_dead = false
  end

  def tick events
    check_partner_msgs
    fire FIRE_POWER if scanned_enemy
    adjust_gun_according_to turn_robot
    broadcast "_PP#{trim(x)}|#{trim(y)}"
  end

  def scanned_enemy
    robot_scanned and not_pointing_toward_partner
  end


  def adjust_gun_according_to turned_bot
    magnitude = [turned_bot.abs,MAX_ROBOT_TURN].min
    gun_adjustment = MIN_GUN_TURN
    if turned_bot > 0
      gun_adjustment -=  magnitude
    else
      gun_adjustment +=  magnitude
    end
    turn_gun gun_adjustment
  end

  def not_pointing_toward_partner
    ((toward_point @partner,gun_heading).abs > MIN_PARTNER_SAFETY_ANGLE) || @partner_dead
  end

  def robot_scanned
    not events['robot_scanned'].empty?
  end

  def turn_robot
    desired_turn = 0
    desired_turn = toward_point @partner,heading    if (distance_from_point @partner) > MAX_DISTANCE_FROM_PARTNER
    desired_turn = away_from_point @partner,heading if (distance_from_point @partner) < MIN_DISTANCE_FROM_PARTNER
    desired_turn = toward_point center,heading      if (distance_from_point center)   > MAX_DISTANCE_FROM_CENTER
    turn desired_turn
    accelerate 1
    desired_turn
  end

  def check_partner_msgs
    partner_said = events['broadcasts']
    if partner_said.empty?
      @partner_dead = true
    else
      @partner_dead = false
      @partner.x,@partner.y = partner_said[0][0][3..-1].split('|').map{|s| s.to_f}
    end
  end

  def away_from_point point,from_heading
    -1 * (toward_point point,from_heading)
  end

  def center
    height = battlefield_height || 1600
    width = battlefield_width || 1600
    PairVector.new(width / 2,height / 2)
  end

  def toward_heading to_heading, from_heading
    difference_between = to_heading - from_heading
    if difference_between > 0
      if difference_between < 180
        desired_turn = difference_between
      else #difference_between > 180
        desired_turn = -1 * (360 - difference_between.abs)
      end
    else #difference_between < 0
      if difference_between > -180
        desired_turn = difference_between
      else #difference_between < -180
        desired_turn = 1 * (360 - difference_between.abs)
      end
    end
    desired_turn
  end

  def toward_point point,from_heading
    toward_heading (degree_from_point point), from_heading
  end

  def distance_from_point point
    Math.hypot(point.x - @x, point.y - @y)
  end

  def degree_from_point point
    a = Math.atan2(@y - point.y, point.x - @x) / Math::PI * 180 % 360
  end

  def trim number
    (number * 1000).round.to_f / 1000
  end
end

class PairVector
  attr_accessor :x,:y
  def initialize(x,y)
    @x,@y = x,y
  end
end