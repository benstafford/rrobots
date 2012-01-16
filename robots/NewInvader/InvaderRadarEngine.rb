class InvaderRadarEngine
  include InvaderMath

  attr_accessor :turn_radar

  SAFE_DISTANCE = 125
  MAX_PERSONAL_RADAR_SCAN = 48
  MIN_PERSONAL_RADAR_SCAN = 3

  def initialize invader
    @radar_direction = 1
    @radar_size = MAX_PERSONAL_RADAR_SCAN
    @robot = invader
    @turn_radar = 0
    @last_target_time = nil
  end

  def radar_sweep
    @turn_radar = 0
    keep_on_target
    @turn_radar = @radar_size * @radar_direction
    avoid_scanning_past_my_edge if @robot.at_edge
    @turn_radar = [[@turn_radar, 60].min,-60].max
  end

  def scan_radar robots_scanned
    if robots_scanned.count > 0
      scan_list = []
      robots_scanned.each do |element|
        scan_list << element.first
      end
      scan_list.sort!
      scan_list.each do |scan|
        enemy = locate_enemy(scan)
        if @radar_size <= MIN_PERSONAL_RADAR_SCAN
          #accurate
          if enemy?(enemy, @robot.friend)
            @last_target_time = @robot.time
            @radar_direction = 0 - @radar_direction
            return enemy

          end
        else
          #inaccurate, but a starting point.
          if !friend_in_section_at_distance?(scan)
            #scan_back_tighter_to_better_locate
            decrease_radar_size "got a hint where he is"
            @radar_direction = 0 - @radar_direction
            @last_target_time = @robot.time
            return enemy
          end
        end
      end
    end
    nil
  end

  private

  def avoid_scanning_past_my_edge
    point_away_from_corner if @robot.radar_heading == corner
    dont_turn_past_corner
  end

  def point_away_from_corner
    direction = turn_toward(corner, @robot.opposite_edge)
    @radar_direction = -1 if direction < 0
    @radar_direction = 1 if direction > 0
    @turn_radar = @radar_size * @radar_direction
  end

  def corner
    rotated(@robot.heading_of_edge, -90 * @radar_direction)
  end

  def dont_turn_past_corner
    new_radar_heading = rotated(@robot.radar_heading, @turn_radar)
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

  def scan_passed_him
    @radar_direction = 0 - @radar_direction
    increase_radar_size "scan passed him"
  end

  def decrease_radar_size reason
    if @radar_size > MIN_PERSONAL_RADAR_SCAN
      @radar_size = @radar_size / 2
    end
  end

  def increase_radar_size reason
    if @radar_size < MAX_PERSONAL_RADAR_SCAN
      @radar_size = @radar_size * 2
    end
  end

  def lost_him
    @radar_size = MAX_PERSONAL_RADAR_SCAN
    @last_target_time = nil
  end

  def keep_on_target
    return if @last_target_time.nil?
    time_since_scan = @robot.time - @last_target_time
    scan_passed_him if time_since_scan >= 1 and time_since_scan <= 4
    lost_him if time_since_scan == 5
  end

  def locate_enemy scan
      radar = rotated(@robot.radar_heading,(0 - @radar_direction * @radar_size/2))
      get_radar_point(radar, scan, @robot.location )
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

  def enemy? object, friend
    return true if friend.nil?
    distance = distance_between_objects(object, friend)
    if distance < SAFE_DISTANCE
      false
    else
      true
    end
  end
end