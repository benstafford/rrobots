require 'robot'

class Invader
   include Robot
  attr_accessor :last_scan_time
  attr_accessor :last_scan_pursued
  attr_accessor :friend_provided_target
  attr_accessor :last_target_time
  attr_accessor :distance_to_edge
  attr_accessor :position_on_edge
  attr_accessor :width_of_edge
  attr_accessor :heading_of_edge
  attr_accessor :intent_heading
  attr_accessor :currrent_direction

  DISTANCE_PAST_SCAN = 0
  CLOCKWISE = -1
  COUNTERCLOCKWISE = 1
  SAFE_DISTANCE = 125
  FIRE_POWER = 0.1

  def firePower
    if trial.nil?
      return FIRE_POWER
    else
      return trial / 10
    end
  end



  def initialize
    @current_direction = 1
    @last_scan_time = 0
    @last_target_time = 0
  end

  def record_position distance_to_edge, position_on_edge, width_of_edge, heading_of_edge
    @distance_to_edge = distance_to_edge
    @position_on_edge = position_on_edge
    @width_of_edge = width_of_edge
    @heading_of_edge = heading_of_edge
  end

def tick events
  broadcast "me=#{@x.to_i},#{@y.to_i}"
  if at_edge?
    if get_heading_from_friend?
      full_speed_ahead
    else
      handle_radar_scan_results
      check_recent_radar
      if need_to_turn?
        turn_around
      else
        if reaching_bottom_edge_turn_around
          return
        end
        if reaching_top_edge_turn_around
          return
        end

        full_speed_ahead
        if @last_target_time > @last_scan_time and time - @last_target_time < 5
          #aim at last provided target still.
          fire_toward_target @friend_provided_target
        else
          point_gun opposite_edge
          turn_radar_away_from_edge
          fire_stream_but_dont_hit_friend
        end
      end
    end
  else
    head_to_edge
  end
end

private
  def handle_radar_scan_results
    robots_scanned = events['robot_scanned']
    if robots_scanned.count>0 and radar_heading == opposite_edge
      scan = robots_scanned.pop.first
      enemy = get_scan_loc(scan)
      if isEnemy?(enemy)
        broadcast "Enemy=#{enemy.x.to_i},#{enemy.y.to_i}"
        @last_scan_time = time
        @last_scan_pursued = false
      end
    end
  end

  def isEnemy? object
    friend = friend_location()
    distance = distance_between_objects(object, friend)
    if distance < SAFE_DISTANCE
      false
    else
      true
    end
  end

  def friend_location
    broadcasts = events['broadcasts']
    if (broadcasts.count > 0)
      broadcasts.each do |broadcast_message|
        broadcast_message[0].split(";").each do |message|
          if message[0..2]=="me="
            location = message[3..100].split(",")
            return Point.new(location[0].to_i, location[1].to_i)
          end
        end
      end
    end
    return Point.new(0,0)
  end

  def enemy_location
   broadcasts = events['broadcasts']
   if (broadcasts.count > 0)
     broadcasts.each do |broadcast_message|
       message = broadcast_message[0]
       if message[0..5]=="Enemy="
         location = message[6..100].split(",")
         enemy = Point.new(location[0].to_i, location[1].to_i)
         return enemy
       end
     end
   end
   return Point.new(0,0)
  end

  def distance_between_objects object1, object2
    Math.hypot(object1.y - object2.y, object2.x - object1.x)
  end

  def get_scan_loc distance
    Point.new(@position_on_edge, @distance_to_edge + distance)
  end

  def get_heading_from_friend?
    enemy = enemy_location
    if (enemy.x == 0 and enemy.y == 0)
      return false
    end

    @friend_provided_target = enemy
    @last_target_time = time
    target_position = get_target_position(enemy)
    if target_position > 0
      if target_position < @position_on_edge - size
        say "Coming Buddy!"
        @current_direction = -1
      else
        "Hold on, I'll get him!'"
        if target_position > @position_on_edge + size
          @current_direction = 1
        end
      end
    end
    fire_toward_target enemy

    return true
  end

  def fire_toward_target enemy
    gun_direction = toward_point(enemy, gun_heading)
    if gun_direction > 30
      gun_direction = 30
    end
    if gun_direction < -30
      gun_direction = -30
    end
    turn_gun gun_direction
    turn_radar 0-gun_direction
    if gun_direction == gun_heading
      fire 1.0
    else
      fire firePower()
    end
  end

  def degree_from_point point
    a = Math.atan2(@y - point.y, point.x - @x) / Math::PI * 180 % 360
  end

  def get_target_position enemy
    0
  end

  def check_recent_radar
    if time - DISTANCE_PAST_SCAN > @last_scan_time and @last_scan_pursued == false
      @current_direction = 0 - @current_direction
      @last_scan_pursued = true
    end
  end

  def at_edge?
    @distance_to_edge <= (size + 1)
  end

  def head_to_edge
    turn_radar 1 if time == 0
    accelerate 1
    if heading != @heading_of_edge
      turn 10 - heading%10
    end
    turn_gun 10
    fire 3 unless events['robot_scanned'].empty?
  end

  def need_to_turn?
    heading!=@intent_heading
  end

  def turn_around
      stop
      turn 10 - heading%10
  end

  def point_gun direction
    if (gun_heading != direction)
      turn_gun turn_direction(gun_heading, direction)* (30 - gun_heading%30)
    end
  end

  def fire_stream_but_dont_hit_friend
    if (events['broadcasts'].count > 0)
      if (@position_on_edge > size * 2)
        fire firePower()
      end
    else
      fire firePower()
    end
  end

  def full_speed_ahead
      accelerate @current_direction
  end

  def turn_radar_away_from_edge

  end

  def reaching_bottom_edge_turn_around
    if @current_direction < 0 and @position_on_edge <= size + 1
      #if check_top_corner?
      #  return true
      #end
      @current_direction = 1
    end
    false
  end

  def check_top_corner?
   false
  end

  def reaching_top_edge_turn_around
    if @current_direction > 0 and @position_on_edge >= @width_of_edge - size
      #if check_bottom_corner?
      #  return true
      #end
      @current_direction = -1
    end
    false
  end

  def check_bottom_corner?
    false
  end

  def opposite_edge
    direction = @heading_of_edge + 180
    if direction >= 360
      direction -= 360
    end
    direction
  end

  def toward_bottom
    if @heading_of_edge < 135
      @heading_of_edge + 90
    else
      @heading_of_edge - 90
    end
  end

  def toward_top
    if @heading_of_edge < 135
      top = @heading_of_edge - 90
    else
      top = @heading_of_edge + 90
    end
    if top >= 360
      top -= 360
    end
    if top < 0
      top += 360
    end
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


  def turn_direction current_heading, desired_heading
    if desired_heading == 0
       if current_heading > 180
         return COUNTERCLOCKWISE
       else
         return CLOCKWISE
       end
    end
    if desired_heading == 90
      if current_heading > 90 and current_heading < 270
        return CLOCKWISE
      else
        return COUNTERCLOCKWISE
      end
    end
    if desired_heading == 180
      if current_heading < 180
        return COUNTERCLOCKWISE
      else
        return CLOCKWISE
      end
    end
    if desired_heading == 270
      if current_heading > 90 and current_heading < 270
        return COUNTERCLOCKWISE
      else
        return CLOCKWISE
      end
    end
  end

  class Point
    attr_accessor :x,:y
    def initialize(x,y)
      @x,@y = x,y
    end
  end
end