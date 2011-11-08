require 'robot'
require 'Matrix'
_x = 0
_y = 1

class MarkBot
  include Robot

  RADAR_SWEEP = 5

  def initialize
    @target_position = Vector[0,0]
    @my_position = Vector[0,0]
  end

  def tick events
    update_my_status
    process_damage(events["got_hit"])
    process_radar(events["robot_scanned"])
    turn_elements

    turn_radar RADAR_SWEEP
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
    say "That wasn't a bit nice!'!\nI'm at #{hit} now.'"
  end

  def process_radar(targets)
    targets.each do |target|
      process_target(target)
    end
  end

  def process_target(target)
    @target_position = position_from_distance_and_angle(target.first, @radar_heading - RADAR_SWEEP/2)
    say "I've got my eyes on you!\nYou: #{target_position}\nMe: #{my_position}"
  end

  def position_from_distance_and_angle(distance, angle)
    target_vector = Vector[distance * Math.cos(angle * Math::PI/180),
                           0 - distance * Math.sin(angle * Math::PI/180)]
    target_vector + @my_position
  end

  attr_accessor :my_position
  attr_accessor :target_position
  attr_accessor :desired_robot_angle
  attr_accessor :desired_gun_angle
  attr_accessor :desired_radar_angle

end