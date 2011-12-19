class InvaderRadarEngine
  attr_accessor :turn_radar
  attr_accessor :robot
  attr_accessor :ready_for_metronome
  attr_accessor :metronome_side
  attr_accessor :math

  RADAR_LEAD = 5

  def initialize invader
    @robot = invader
    @ready_for_metronome = true
    @math = InvaderMath.new
    @turn_radar = 0
  end

  def radar_sweep
    @turn_radar = 0
    point_radar
    @turn_radar = [[@turn_radar, 60].min,-60].max
  end

  def scan_radar robots_scanned
    return nil if @ready_for_metronome == false
    if robots_scanned.count > 0
      scan_list = []
      robots_scanned.each do |element|
        scan_list << element.first
      end
      scan_list.sort!
      scan_list.each do |scan|
        enemy = locate_enemy(scan)
        if !enemy.nil? and enemy?(enemy, @robot.friend)
          return enemy
        end
      end
    end
    nil
  end

  private

  def point_radar
    desired_direction = @robot.opposite_edge
    if (@robot.radar_heading == desired_direction)
      @ready_for_metronome = true
      desired_direction = lead_search_movement(@robot.radar_heading, @robot.current_direction)
    end
    @turn_radar = @robot.math.turn_toward(@robot.radar_heading, desired_direction)
  end

  def locate_enemy scan
    get_scan_loc(scan, @robot.current_direction, @robot.opposite_edge, @robot.location)
  end

  def lead_search_movement(current_heading, direction)
    current_heading + (direction * RADAR_LEAD)
  end

  def get_corner_scan_location radar_heading, distance, location
    return @math.get_radar_point(radar_heading, distance, location)
  end

 def get_scan_loc distance, direction, edge, location
   direction = @robot.current_direction
   return @math.get_radar_point(edge + 5*direction, distance, location)
 end

  SAFE_DISTANCE = 125

  def enemy? object, friend
    return true if friend.nil?
    distance = @math.distance_between_objects(object, friend)
    if distance < SAFE_DISTANCE
      false
    else
      true
    end
  end
end

class InvaderRadarEngineSearching < InvaderRadarEngine
  attr_accessor :radar_direction
  attr_accessor :radar_size

  def initialize invader
    @radar_direction = 1
    @radar_size = 60
    super(invader)
  end

  def corner
    @math.rotated(@robot.heading_of_edge, -90 * @radar_direction)
  end

  def point_radar
    if (@ready_for_metronome == false) && @robot.radar_heading != corner
      @turn_radar = @math.turn_toward(@robot.radar_heading, corner)
      return
    end
    #puts "current radar_direction = #{@radar_direction}, heading = #{@robot.radar_heading}, corner = #{corner}"
    if @robot.radar_heading == corner
      @ready_for_metronome = true
      back_to_gun = @math.turn_toward(@robot.radar_heading, @robot.opposite_edge)
      if (back_to_gun > 0)
        @radar_direction = 1
      else
        @radar_direction = -1
      end
    end

    @turn_radar = @radar_size * @radar_direction
    new_radar_direction = @math.rotated(@robot.radar_heading, @turn_radar)
    if @radar_direction < 0
      if @math.radar_heading_between?(new_radar_direction, corner, @math.rotated(corner, 180))
        @turn_radar = @math.turn_toward(@robot.radar_heading, corner)
      end
    else
      if @math.radar_heading_between?(new_radar_direction, @math.rotated(corner, 180), corner)
        @turn_radar = @math.turn_toward(@robot.radar_heading, corner)
      end
    end
    #puts "turning #{@turn_radar}, new radar_direction = #{@radar_direction}"
  end

  def locate_enemy scan
    if @ready_for_metronome == false
      return nil
    end
    if @radar_size < 4
      radar = @math.rotated(@robot.radar_heading, 0 - @radar_size/2)
      enemy = @math.get_radar_point(radar, scan, @robot.location )
      @ready_for_metronome = false
      @radar_size = 60
      return enemy
    end

    if enemy_not_in_section_at_distance? scan
      @radar_size = @radar_size/2
      @radar_direction = 0 - @radar_direction
    end
    return nil
  end

  def enemy_not_in_section_at_distance? distance
    if @robot.friend.nil?
      return true
    end
    friend_distance = @math.distance_between_objects(@robot.location, @robot.friend)
    if (friend_distance - distance).abs < SAFE_DISTANCE
      return false
    end
    end_radar = @robot.radar_heading
    begin_radar = @math.rotated(@robot.radar_heading, 0 - @radar_size)

    min_angle = [end_radar, begin_radar].min
    max_angle = [end_radar, begin_radar].max
    left_angle = max_angle
    right_angle = min_angle
    if max_angle > 270 and min_angle < 90
      left_angle = min_angle
      right_angle = max_angle
    end
    if @math.radar_heading_between? @math.degree_from_point_to_point(@robot.location, @robot.friend),left_angle, right_angle
      return false
    end
    return true
  end

end

class InvaderRadarEngineHeadToEdge < InvaderRadarEngine
  def point_radar
    @ready_for_metronome = true
    @turn_radar = 1 if @robot.time == 0
  end
end

class InvaderRadarEngineSearchOppositeCorner < InvaderRadarEngine
  def locate_enemy scan
    desired_direction = @math.rotated(@robot.heading_of_edge, @robot.current_direction * -90)
    get_corner_scan_location(desired_direction, scan.to_f, @robot.location)
  end

  def point_radar
    desired_direction = @math.rotated(@robot.heading_of_edge, @robot.current_direction * -90)
    check_direction = @math.rotated(@robot.heading_of_edge, @robot.current_direction * -91)
    if (@robot.radar_heading == desired_direction)
      @ready_for_metronome = true
      desired_direction = check_direction
    end
    if (@robot.radar_heading == check_direction) and @robot.found_enemy.nil?
      @robot.change_mode InvaderMode::HEAD_TO_EDGE
    end
    @turn_radar = @robot.math.turn_toward(@robot.radar_heading, desired_direction)
  end
end

class InvaderRadarEngineProvidedTarget < InvaderRadarEngine
  attr_accessor :target_enemy

  def point_radar
    @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    last_known_location = @target_enemy
    enemy_direction = @math.degree_from_point_to_point(@robot.location, last_known_location)
    left_side = @math.rotated(enemy_direction,5)
    right_side = @math.rotated(enemy_direction, -5)
    if @ready_for_metronome == false
      if @robot.math.radar_heading_between?(enemy_direction, left_side, right_side)
        @ready_for_metronome = true
        @metronome_side = "left"
      else
        @turn_radar = @math.turn_toward(@robot.radar_heading, enemy_direction)
      end
    end
    if (@ready_for_metronome == true)
      if @metronome_side == "left"
        @turn_radar =@math.turn_toward(@robot.radar_heading, left_side)
        @metronome_side = "right"
      else
        @turn_radar =@math.turn_toward(@robot.radar_heading, right_side)
        @metronome_side = "left"
      end
    end
  end

  def locate_enemy scan
    @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    desired_direction = @math.degree_from_point_to_point(@robot.location, @target_enemy)
    enemy = @math.get_radar_point(desired_direction, scan.to_f, @robot.location)
    return enemy
  end
end
