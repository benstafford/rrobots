class InvaderRadarEngine
  include InvaderMath

  attr_accessor :turn_radar
  attr_accessor :ready_for_metronome

  SAFE_DISTANCE = 125
  MAX_PERSONAL_RADAR_SCAN = 12
  MIN_PERSONAL_RADAR_SCAN = 6

  def initialize invader
    @radar_direction = 1
    @radar_size = MAX_PERSONAL_RADAR_SCAN
    @robot = invader
    @ready_for_metronome = false
    @turn_radar = 0
    @metronome_side = nil
    @last_target_time = nil
  end

  def radar_sweep
    @turn_radar = 0
    if @robot.at_edge
      point_radar
    else
      point_radar_at_opposite_edge
    end
    @turn_radar = [[@turn_radar, 60].min,-60].max
  end

  def scan_radar robots_scanned
    return nil if !@robot.at_edge
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

  def point_radar_at_opposite_edge
    desired_direction = @robot.opposite_edge
    @turn_radar = turn_toward(@robot.radar_heading, desired_direction)
  end


  def enemy? object, friend
    return true if friend.nil?
    distance = distance_between_objects(object, friend)
    if distance < SAFE_DISTANCE
      false
    else
      true
    end
  end

  def corner
    rotated(@robot.heading_of_edge, -90 * @radar_direction)
  end

  def radar_ready_to_start_sweep?
    if (@ready_for_metronome == false) && @robot.radar_heading != corner
        @turn_radar = turn_toward(@robot.radar_heading, corner)
        return false
    end
    true
  end

  def set_direction_from_corner
    if @robot.radar_heading == corner
      @ready_for_metronome = true
      back_to_gun = turn_toward(@robot.radar_heading, @robot.opposite_edge)
      if (back_to_gun > 0)
        @radar_direction = 1
      else
        @radar_direction = -1
      end
    end
  end

  def dont_turn_past_corner new_radar_heading
    if @radar_direction < 0
      if radar_heading_between?(new_radar_heading, corner, rotated(corner, 180))
        @turn_radar = turn_toward(@robot.radar_heading, corner)
      end
    else
      if radar_heading_between?(new_radar_heading, rotated(corner, 180), corner)
        @turn_radar = turn_toward(@robot.radar_heading, corner)
      end
    end
  end

  def point_radar
    return if !radar_ready_to_start_sweep?
    set_direction_from_corner
    keep_on_target
    @turn_radar = @radar_size * @radar_direction
    new_radar_heading = rotated(@robot.radar_heading, @turn_radar)
    dont_turn_past_corner new_radar_heading
  end

  def scan_passed_him
    @radar_direction = 0 - @radar_direction
  end

  def lost_him
    #@ready_for_metronome = false
    @radar_size = MAX_PERSONAL_RADAR_SCAN
  end

  def keep_on_target
    return if @last_target_time.nil?
    time_since_scan = @robot.time - @last_target_time
    scan_passed_him if time_since_scan == 1
    lost_him if time_since_scan == 4
  end

  def locate_enemy scan
    if @ready_for_metronome == false
      return nil
    end
    if @radar_size <= MIN_PERSONAL_RADAR_SCAN
      radar = rotated(@robot.radar_heading, 0 - @radar_size/2)
      enemy = get_radar_point(radar, scan, @robot.location )
      @last_target_time = @robot.time
      return enemy
    end

    if !friend_in_section_at_distance?(scan)
      @radar_size = @radar_size/2
      @radar_direction = 0 - @radar_direction
    end
    return nil
  end

  def friend_in_section_at_distance? distance
    if @robot.friend.nil?
      return false
    end
    friend_distance = distance_between_objects(@robot.location, @robot.friend)
    if (friend_distance - distance).abs > SAFE_DISTANCE
      return false
    end
    end_radar = @robot.radar_heading
    begin_radar = rotated(@robot.radar_heading, 0 - @radar_size)

    min_angle = [end_radar, begin_radar].min
    max_angle = [end_radar, begin_radar].max
    left_angle = max_angle
    right_angle = min_angle
    if max_angle > 270 and min_angle < 90
      left_angle = min_angle
      right_angle = max_angle
    end
    if radar_heading_between? degree_from_point_to_point(@robot.location, @robot.friend),left_angle, right_angle
      return true
    end
    return false
  end

end

