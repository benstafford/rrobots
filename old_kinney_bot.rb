require 'robot'

class KinneyBot
  include Robot

  attr_reader :partner
  attr_reader :my_x
  attr_reader :my_y

  attr_accessor :my_heading

  def initialize
    @partner = Partner.new
    @my_x = 0
    @my_y = 0
  end

  def tick events
    begin_tick events
  end

  def fire_gun_if_not_partner power
    fire(power) if !two_angles_within_fifteen_degrees? gun_heading, @partner.angle
  end

  def begin_tick events
    @my_x = x
    @my_y = y
    process_events events
  end

  def turn_to_heading
    turning_degrees = (heading-@my_heading).abs.round
    if turning_degrees >=10
      turn 10
      10
    else
      turn turning_degrees
      turning_degrees
    end
  end

  def angle_between_two_points(x1, y1, x2, y2)
    delta_x = (x2-x1)
    delta_y = (y2-y1)
    rounded_angle_from_inverse_tangent(delta_y, delta_x).to_i
  end

  def rounded_angle_from_inverse_tangent delta_y, delta_x
    angle = (Math.atan2(delta_y, delta_x) * (180.0 / Math::PI)).round
    angle += 360 if angle < 0
    angle.to_i
  end

  def opposite_angle_between_two_points(x1, y1, x2, y2)
    360 - angle_between_two_points(x1, y1, x2, y2)
  end

  def angle_away_from_center
    center = map_middle
    opposite_angle_between_two_points(@my_x, @my_y, center['x'], center['y'])
  end

    def two_angles_within_fifteen_degrees? gun_angle, p_angle
      ((gun_angle - p_angle).abs) <= 15
    end

  def process_events events
    puts "PROCESSING EVENTS: #{events.inspect}"
    events.each do |event_name, event_data|
      if event_name == 'broadcasts'
        process_broadcast event_data
      elsif event_name == 'robot_scanned'
        @scanned_bots = []
        event_data.each do |scanned_data|
          @scanned_bots << scanned_data[0]
        end
        if !@scanned_bots.empty?
          #find_enemy_by_hyp @scanned_bots[0]
        end
      end
    end
  end

  def find_enemy_by_distance distance
    my_radar_heading = radar_heading
    tx = @my_x + Math.cos((my_radar_heading-5) * (Math::PI / 180.0)) * distance
    ty = @my_y - Math.sin((my_radar_heading-5) * (Math::PI / 180.0)) * distance
    [tx.to_i,ty.to_i]
  end

  def process_broadcast broadcast_data
    broadcast_data.each do |message|
      message_data = message[0].split('|')
        if message_data[0] == 'loc'
          p_x = message_data[1].to_i
          p_y = message_data[2].to_i
          @partner.set_location p_x, p_y
          @partner.set_angle angle_between_two_points(@my_x,@my_y, p_x, p_y)
        end
    end
  end

  def map_middle
    {'x' => (battlefield_width/2), 'y' => (battlefield_height/2)}
  end
end

class Partner
  attr_reader :x
  attr_reader :y
  attr_reader :angle
  def set_location x, y
    @x = x
    @y = y
  end

  def set_angle angle
    @angle = angle
  end
end

