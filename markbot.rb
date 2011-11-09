require 'robot'
require 'Matrix'

class MarkBot
  include Robot

  X = 0
  Y = 1

  MAX_RADAR_SWEEP = 7

  MAX_ROBOT_TURN = 10
  MAX_GUN_TURN = 30
  MAX_RADAR_TURN = 60

  MIN_PARTNER_SAFETY_ANGLE = 3
  MIN_PARTNER_SAFETY_DISTANCE = 300

  MIN_DISTANCE_FROM_PARTNER = 500

  MIN_FIRE_POWER = 0.1
  MAX_FIRE_POWER = 3

  def initialize
    @target_position = Vector[0,0]
    @my_position = Vector[0,0]
    @partner_position = Vector[0,0]

    @partner_dead = false

    @desired_robot_heading = 90
    @robot_turn = 0
    @next_robot_heading = 0


    @desired_gun_heading = 180
    @gun_turn = 0
    @next_gun_heading = 0

    @desired_radar_heading = 270
    @radar_turn = 0
    @next_radar_heading = 0

    @radar_search_direction = 1

    @fire_power = MIN_FIRE_POWER
  end

  def say_info
    say "Me: #{my_position}\nPartner: #{partner_position}\nTarget: #{target_position}\nPower: #{fire_power}"
  end

  def tick events
    update_my_status
    process_partner_messages(events["broadcasts"])
    process_damage(events["got_hit"])
    process_radar(events["robot_scanned"])
    move_away_from_partner
    turn_elements #if time % 50 == 0
    say_info
    fire @fire_power if not_aiming_at_partner
    broadcast "P#{trim(x)}|#{trim(y)}"
  end

  def not_aiming_at_partner
    (angle_to_point(partner_position) - @gun_heading).abs > MIN_PARTNER_SAFETY_ANGLE
  end

  def move_away_from_partner
    if distance_between_points(@my_position, @partner_position) < MIN_DISTANCE_FROM_PARTNER && !@partner_dead
      @desired_robot_heading = angle_to_point(@partner_position)
      accelerate(-1)
    end
  end

  def process_partner_messages(partner_said)
    if partner_said.empty?
      @partner_dead = true
    else
      @partner_dead = false

      if partner_said[0][0][0] == "P"
        partner_x,partner_y = partner_said[0][0][1..-1].split('|').map{|s| s.to_f}
        @partner_position = Vector[partner_x,partner_y]
      elsif partner_said[0][0][0] == "T"
          partner_x,partner_y = partner_said[0][0][1..-1].split('|').map{|s| s.to_f}
          partners_target = Vector[partner_x,partner_y]
          if distance_between_points(@my_position, partners_target) < distance_between_points(@my_position, @target_position)
            set_target_position(partners_target)
          end
      end
    end
  end

  def update_my_status
    @my_position = Vector[@x,@y]
  end

  def process_damage(hits)
    hits.each do |hit|
      process_hit(hit.first)
    end
  end

  def process_hit(hit)
  end

  def process_radar(targets)
    if targets.empty?
      process_empty_scan
    else
      targets.each do |target|
        process_target(target)
      end
    end
  end

  def process_empty_scan
    @desired_radar_heading = (@radar_heading + @radar_search_direction * MAX_RADAR_SWEEP) % 360
    @desired_gun_heading = angle_to_point(@target_position) + Math.sin(time/@fire_power) * 3
    decrease_fire_power
    accelerate(-Math.sin(time/100).abs)
  end

  def set_target_position(test_target_position)
    @target_position = test_target_position
    @desired_gun_heading = angle_to_point(@target_position) + Math.sin(time/@fire_power) * 3
    @radar_search_direction *= -1
    @desired_radar_heading = (angle_to_point(@target_position) + @radar_search_direction * MAX_RADAR_SWEEP) % 360
    @desired_robot_heading = (angle_to_point(@target_position) + 90) % 360
    increase_fire_power
    accelerate(Math.sin(time/100).abs)
  end

  def process_target(target)
    test_target_position = position_from_distance_and_angle(target.first, @radar_heading - MAX_RADAR_SWEEP/2)
    distance_between_firing_line_and_partner = distance_between_point_and_line(@partner_position, @my_position, test_target_position)

    if (distance_between_firing_line_and_partner > MIN_PARTNER_SAFETY_DISTANCE) || @partner_dead
      set_target_position(test_target_position)
      broadcast "T#{trim(@target_position[X])}|#{trim(@target_position[Y])}"
    else
      process_empty_scan
    end
  end

  def increase_fire_power
    @fire_power = [@fire_power + 0.02, MAX_FIRE_POWER].min
  end

  def decrease_fire_power
    @fire_power = [MIN_FIRE_POWER, @fire_power - 0.06].max
  end

  def position_from_distance_and_angle(distance, angle)
    target_vector = Vector[trim(distance * Math.cos(angle * Math::PI/180)),
                           trim(-distance * Math.sin(angle * Math::PI/180))]
    target_vector + @my_position
  end

  def shortest_turn(desired_turn_amount)
    turn_amount = desired_turn_amount

    if (turn_amount.abs > 180)
      turn_amount += -1 * (turn_amount / turn_amount.abs) * 360
    end
    turn_amount
  end

  def turn_the_robot
    turn_amount = shortest_turn(@desired_robot_heading - @heading)
    @robot_turn = [-MAX_ROBOT_TURN, [turn_amount, MAX_ROBOT_TURN].min].max
    @next_robot_heading = @heading + @robot_turn
    turn @robot_turn
  end

  def turn_the_gun
    turn_amount = shortest_turn(@desired_gun_heading - @gun_heading - @robot_turn)
    @gun_turn = [-MAX_GUN_TURN, [turn_amount, MAX_GUN_TURN].min].max
    @next_gun_heading = @gun_heading + @gun_turn + @robot_turn
    turn_gun @gun_turn
  end

  def turn_the_radar
    turn_amount = shortest_turn(@desired_radar_heading - @radar_heading - @robot_turn - @gun_turn)
    @radar_turn = [-MAX_RADAR_TURN, [turn_amount, MAX_RADAR_TURN].min].max
    @next_radar_heading = @radar_heading + @radar_turn + @gun_turn + @robot_turn
    turn_radar @radar_turn
  end

  def turn_elements
    turn_the_robot
    turn_the_gun
    turn_the_radar
  end

  def distance_between_points from, to
    Math.hypot(to[X] - from[X], to[Y] - from[Y])
  end

  def distance_between_point_and_line point, line_start, line_end
    point_to_line = point - line_start
    line = line_end - line_start
    distance = cross_product(point_to_line, line).abs / magnitude(line)
  end

  def angle_to_point point
    a = Math.atan2(@y - point[Y], point[X] - @x) / Math::PI * 180 % 360
  end

  def cross_product v1, v2
    v1[X] * v2[Y] - v1[Y] * v2[X]
  end

  def magnitude v
    Math.sqrt(v[X]*v[X] + v[Y]*v[Y])
  end
  def trim number
    (number * 1000).round.to_f / 1000
  end

  attr_accessor :my_position
  attr_accessor :target_position
  attr_accessor :partner_position

  attr_accessor :partner_dead

  attr_accessor :desired_robot_heading
  attr_accessor :robot_turn
  attr_accessor :next_robot_heading

  attr_accessor :desired_gun_heading
  attr_accessor :gun_turn
  attr_accessor :next_gun_heading

  attr_accessor :desired_radar_heading
  attr_accessor :radar_turn
  attr_accessor :next_radar_heading

  attr_accessor :radar_search_direction
  attr_accessor :radar_scan_range

  attr_accessor :fire_power
end