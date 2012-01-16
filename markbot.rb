require 'robot'
require 'Matrix'

class MarkBot
  include Robot

  X = 0
  Y = 1

  TARGET_EXPIRATION = 30

  MAX_RADAR_SWEEP = 7
  MAX_SCAN_RANGE = 170

  MAX_ROBOT_TURN = 10
  MAX_GUN_TURN = 30
  MAX_RADAR_TURN = 60

  MIN_PARTNER_SAFETY_ANGLE = 5
  MIN_PARTNER_SAFETY_DISTANCE = 300

  MIN_DISTANCE_FROM_PARTNER = 500
  MIN_DISTANCE_FROM_WALL = 60

  DESIRED_DISTANCE_FROM_TARGET = 1200

  MOVE_TOWARD_ANGLE = 70
  MIN_FIRE_POWER = 0.1
  MAX_FIRE_POWER = 3

  MOVE_ROBOT = true

  def initialize
    @my_target_position = nil
    @my_target_time = -1
    @my_position = nil

    @partner_position = nil
    @partner_target_position = nil
    @partner_target_time = -1

    @partner_dead = false

    @desired_robot_heading = 0
    @robot_turn = 0
    @next_robot_heading = 0

    @desired_gun_heading = 0
    @gun_turn = 0
    @next_gun_heading = 0

    @desired_radar_heading =
    @radar_turn = 0
    @next_radar_heading = 0

    @radar_search_direction = 1
    @radar_scan_range = MAX_SCAN_RANGE

    @state = "init"
    @fire_power = MIN_FIRE_POWER
  end

  def say_info
    say "Me: #{my_position}\n\
Target: #{my_target_position}\n\
Partner: #{partner_position}\n\
Target: #{partner_target_position}\n\
Power: #{fire_power}\n\
Range: #{radar_scan_range}\n\
Direction: #{radar_search_direction}\n\
         "
  end

  def broadcast_position(code, position)
    broadcast "#{code}#{encode(position[X])}|#{encode(position[Y])}"
  end

  def broadcast_message
    if time % 2 == 0 || @my_target_position == nil
      broadcast_position("P", @my_position)
    else
      broadcast_position("T", @my_target_position)
    end
  end

  def tick events
    update_my_status
    if @state != "init"
      process_damage(events["got_hit"])
      process_radar(events["robot_scanned"])
      process_partner_messages(events["broadcasts"])
      attack(closest_target) if closest_target != nil
      move_the_robot(closest_target)
      scan_for_target
      fire @fire_power if not_aiming_at_partner && closest_target != nil
      broadcast_message
    end
    turn_elements #if time % 50 == 0
    expire_targets
    #say_info
  end

  def expire_targets
    expire_my_target
    expire_partner_target
  end

  def expire_my_target
    if time - @my_target_time >= TARGET_EXPIRATION
      @my_target_position = nil
    end
  end

  def expire_partner_target
    if time - @partner_target_time >= TARGET_EXPIRATION
      @partner_target_position = nil
    end
  end

  def move_the_robot(target)
    if !move_away_from_partner && !move_away_from_walls
      move_toward(target)
    end
  end

  def move_away_from_walls
    near_wall = false
    near_wall ||= @my_position[X] < MIN_DISTANCE_FROM_WALL
    near_wall ||= @my_position[Y] < MIN_DISTANCE_FROM_WALL
    near_wall ||= battlefield_width - @my_position[X] < MIN_DISTANCE_FROM_WALL
    near_wall ||= battlefield_height - @my_position[Y] < MIN_DISTANCE_FROM_WALL

    if near_wall
#      move_toward(@center_position)
      @desired_robot_heading = angle_to_point(@center_position)
      accelerate_the_robot(1)
    end
    near_wall
  end

  def move_toward(target)
    if target == nil
      move_toward(@center_position)
    elsif distance_to(target) > DESIRED_DISTANCE_FROM_TARGET
      @desired_robot_heading = (angle_to_point(target) + MOVE_TOWARD_ANGLE) % 360
      accelerate_the_robot(1)
    else
      @desired_robot_heading = (angle_to_point(target) - MOVE_TOWARD_ANGLE) % 360
      accelerate_the_robot(-1)
    end
  end

  def not_aiming_at_partner
    !toward_partner(@gun_heading)
  end

  def toward_partner(angle)
    !@partner_dead && (@partner_position == nil || (angle_to_point(@partner_position) - angle).abs <= MIN_PARTNER_SAFETY_ANGLE)
  end

  def move_away_from_partner
    moving_away = false
    if @partner_position != nil && !@partner_dead && distance_to(@partner_position) < MIN_DISTANCE_FROM_PARTNER
      @desired_robot_heading = angle_to_point(@partner_position)
      accelerate_the_robot(-1)
      moving_away = true
    end
    moving_away
  end

  def process_partner_message(message)
    message_x, message_y = message[0][1..-1].split('|').map { |s| s.to_i(16).to_f/100 }

    if message[0][0] == "P"
      @partner_position = Vector[message_x,message_y]
    else
      @partner_target_position = Vector[message_x, message_y]
      @partner_target_time = time
    end
  end

  def process_partner_messages(partner_said)
    if partner_said.empty?
      @partner_dead = true
    else
      @partner_dead = false
      partner_said.each do |message|
        process_partner_message(message)
      end
    end
  end

  def update_my_status
    @my_position = Vector[trim(@x),trim(@y)]
    init if time == 0

    if @desired_radar_heading == @radar_heading
      @state="track"
    end
  end

  def init
    @center_position = Vector[battlefield_width/2,battlefield_height/2]
    headingToCenter = angle_to_point(@center_position)
    @desired_gun_heading = headingToCenter
    @desired_radar_heading = headingToCenter
    @desired_robot_heading = headingToCenter
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

  def scan_for_target
    if (@desired_radar_heading == @radar_heading)
      increase_scan_range
      reverse_scan
      if @my_target_position != nil
        @desired_radar_heading = angle_to_point(@my_target_position) + @radar_search_direction * @radar_scan_range
      else
        @desired_radar_heading = angle_to_point(@center_position) + @radar_search_direction * @radar_scan_range
      end
    end
  end

  def increase_scan_range
    @radar_scan_range = [MAX_SCAN_RANGE, @radar_scan_range + MAX_RADAR_SWEEP*2].min
  end

  def decrease_scan_range
    @radar_scan_range = MAX_RADAR_SWEEP
  end

  def process_empty_scan
    decrease_fire_power
  end

  def reverse_scan
    @radar_search_direction *= -1
  end

  def attack target
      @desired_gun_heading = angle_to_point(target) + Math.sin(time) * 2
  end

  def distance_to(point)
    distance_between_points(@my_position, point)
  end

  def closest_target
    if @partner_target_position == nil
      @my_target_position
    elsif @my_target_position == nil
      @partner_target_position
    elsif distance_to(@partner_target_position) < distance_to(@my_target_position) && !@partner_dead
      @partner_target_position
    else
      @my_target_position
    end
  end

  def process_found_target(test_target_position)
    @my_target_position = test_target_position
    @my_target_time = time
    @desired_radar_heading = angle_to_point(@my_target_position)
    decrease_scan_range
    increase_fire_power
  end

  def process_target(target)
    test_target_position = position_from_distance_and_angle(target.first, @radar_heading - MAX_RADAR_SWEEP/2)
    distance_between_firing_line_and_partner = 0
    distance_between_firing_line_and_partner = distance_between_point_and_line(@partner_position, @my_position, test_target_position) if @partner_position != nil

    if @partner_dead || (distance_between_firing_line_and_partner > MIN_PARTNER_SAFETY_DISTANCE) && !toward_partner(angle_to_point(test_target_position))
      process_found_target(test_target_position)
    else
      process_empty_scan
    end
  end

  def increase_fire_power
    @fire_power = [@fire_power + 0.01, MAX_FIRE_POWER].min
  #  @fire_power = ((@battlefield_height - distance_between_points(@my_position, @target_position)).abs / @battlefield_height) * MAX_FIRE_POWER
  end

  def decrease_fire_power
    @fire_power = [MIN_FIRE_POWER, @fire_power - 0.02].max
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

  def scan_turn(desired_turn_amount)
    if @radar_search_direction == 1
      turn_amount = desired_turn_amount.abs
    else
      turn_amount = -desired_turn_amount.abs
    end
    desired_turn_amount
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
    if @state == "init"
      turn_amount = shortest_turn(@desired_radar_heading - @radar_heading - @robot_turn - @gun_turn)
      @radar_turn = [-MAX_RADAR_TURN, [turn_amount, MAX_RADAR_TURN].min].max
    else
      turn_amount = scan_turn(@desired_radar_heading - @radar_heading - @robot_turn - @gun_turn)
      @radar_turn = [-MAX_RADAR_SWEEP, [turn_amount, MAX_RADAR_SWEEP].min].max
    end
    @next_radar_heading = @radar_heading + @radar_turn + @gun_turn + @robot_turn
    turn_radar @radar_turn
  end

  def turn_elements
    turn_the_robot
    turn_the_gun
    turn_the_radar
  end

  def accelerate_the_robot(amount)
    accelerate amount if MOVE_ROBOT
  end

  def distance_between_points from, to
    Math.hypot(to[X] - from[X], to[Y] - from[Y])
  end

  def distance_between_point_and_line point, line_start, line_end
    point_to_line = point - line_start
    line = line_end - line_start
    cross_product(point_to_line, line).abs / magnitude(line)
  end

  def angle_to_point point
    Math.atan2(@y - point[Y], point[X] - @x) / Math::PI * 180 % 360
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

  def encode number
    (trim(number)*100).to_i.to_s(16)
  end
  
  attr_accessor :my_position
  attr_accessor :my_target_position
  attr_accessor :my_target_time

  attr_accessor :partner_position
  attr_accessor :partner_target_position

  attr_accessor :center_position

  attr_accessor :new_target_position
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
  attr_accessor :radar_mode
  attr_accessor :fire_power
  end
