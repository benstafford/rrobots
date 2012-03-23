$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../../')

require 'PolarIce'
require 'Matrix'

def test_acceleration(desiredSpeed, expectedAcceleration)
  @simplicity.stub!(:speed).and_return(0)
  @simplicity.driver.desired_speed = desiredSpeed
  @simplicity.should_receive(:accelerate).with(expectedAcceleration)
  @simplicity.tick nil
end

def test_move_to_position(desired_target, expected_speed)
  @simplicity.driver.desired_target = desired_target
  @simplicity.tick nil
  @simplicity.driver.desired_speed.should == expected_speed
end

def test_rotation(rotator, desired_heading, expected_rotation)
  rotator.desired_heading = desired_heading
  @simplicity.tick nil
  rotator.rotation.should == expected_rotation
end

def test_aim_at_target(rotator, desired_target, expected_heading)
  rotator.desired_target = desired_target
  @simplicity.tick nil
  rotator.desired_heading.should == expected_heading
end

def total_rotation
  (@simplicity.radar.rotation + @simplicity.gunner.rotation + @simplicity.driver.rotation)
end

def scan_60_degrees
  @simplicity.tick @events
  total_rotation.should == 60
end

def do_quick_scan(targets = nil)
  5.times { scan_60_degrees }
  if (targets != nil)
    if (targets.class == Array)
      @simplicity.radar.sightings += targets
    else
      @simplicity.radar.sightings << targets
    end
  end
#  scan_60_degrees
  @simplicity.tick @events
end

def expect_first_scan(radarHeading, gunHeading, turn, robotScanned=nil)
  @events['robot_scanned'].clear
  @events['robot_scanned'] << robotScanned if robotScanned != nil
  @simplicity.stub!(:radar_heading).and_return(radarHeading)
  @simplicity.stub!(:gun_heading).and_return(gunHeading)
  @simplicity.tick @events
  (@simplicity.driver.rotation + @simplicity.gunner.rotation + @simplicity.radar.rotation).should == turn
end

def expect_scan(heading, turn, robotScanned=nil)
  @events['robot_scanned'].clear
  @events['robot_scanned'] << robotScanned if robotScanned != nil
  @simplicity.stub!(:radar_heading).and_return(heading)
  @simplicity.stub!(:gun_heading).and_return(heading)
  @simplicity.tick @events
  (@simplicity.driver.rotation + @simplicity.gunner.rotation + @simplicity.radar.rotation).should == turn
end

def stub_actions
  @simplicity.stub!(:accelerate)
  @simplicity.stub!(:turn)
  @simplicity.stub!(:turn_gun)
  @simplicity.stub!(:turn_radar)
  @simplicity.stub!(:fire)
  @simplicity.stub!(:broadcast)
  @simplicity.stub!(:say)
end

def stub_status
  @simplicity.stub!(:x).and_return(800)
  @simplicity.stub!(:y).and_return(800)
  @simplicity.stub!(:speed).and_return(0)
  @simplicity.stub!(:heading).and_return(0)
  @simplicity.stub!(:gun_heading).and_return(0)
  @simplicity.stub!(:radar_heading).and_return(0)
  @simplicity.stub!(:time).and_return(2)
  @simplicity.stub!(:size).and_return(60)
end

def set_defaults
  @simplicity.driver.desired_target = nil
  @simplicity.driver.desired_heading = nil
  @simplicity.driver.desired_speed = nil
  @simplicity.driver.desired_max_speed = 8
  @simplicity.gunner.desired_target = nil
  @simplicity.gunner.desired_heading = nil
  @simplicity.radar.desired_target = nil
  @simplicity.radar.desired_heading = nil
end

describe 'PolarIce' do
  before(:each) do
    @simplicity = PolarIce.new
    @events = Hash.new{|h, k| h[k]=[]}
    @position = Vector[800,800]

    stub_actions
    stub_status
    set_defaults
  end

  it 'should initialize variables' do
    @simplicity.driver.acceleration.should_not == nil
    @simplicity.driver.rotation.should_not == nil
    @simplicity.gunner.rotation.should_not == nil
    @simplicity.radar.rotation.should_not == nil
    @simplicity.loader.power.should_not == nil
    @simplicity.broadcast_message.should_not == nil
    @simplicity.quote.should_not == nil
  end

  describe 'Basic Functionality' do
    before(:each) do
      @simplicity.base_test
    end
    it 'should store its position as a vector' do
      @simplicity.tick nil
      @simplicity.current_position.should == Vector[800,800]
    end
    it 'should perform desired actions on each tick' do
      @simplicity.driver.acceleration = 1
      @simplicity.should_receive(:turn).with(10)
      @simplicity.driver.rotation = 10
      @simplicity.should_receive(:accelerate).with(1)
      @simplicity.gunner.rotation = 15
      @simplicity.should_receive(:turn_gun).with(15)
      @simplicity.radar.rotation = 15
      @simplicity.should_receive(:turn_radar).with(15)
      @simplicity.loader.power = 0.1
      @simplicity.should_receive(:fire).with(0.1)
      @simplicity.broadcast_message = "message"
      @simplicity.should_receive(:broadcast).with("message")
      @simplicity.quote = "quote"
      @simplicity.should_receive(:say).with("quote")
      @simplicity.perform_actions
    end
  end
  describe 'It should know information from the previous tick' do
    before(:each) do
      @simplicity.stub!(:radar_heading).and_return(3)
      @simplicity.tick nil
      @simplicity.stub!(:radar_heading).and_return(4)
    end
    it 'should know its previous radar heading' do
      @simplicity.previous_status.radar_heading.should == 3
    end
  end
  describe 'It should turn' do
    before(:each) do
      @simplicity.stub!(:x).and_return(800)
      @simplicity.stub!(:y).and_return(800)
      @simplicity.stub!(:speed).and_return(0)
      @simplicity.stub!(:heading).and_return(90)
      @simplicity.stub!(:gun_heading).and_return(90)
      @simplicity.stub!(:radar_heading).and_return(90)
      @simplicity.base_test
    end
    describe 'towards headings' do
      describe 'It should turn its hull toward a desired heading' do
        it 'should not turn if it is at the desired heading' do
          test_rotation(@simplicity.driver, 90, 0)
        end
        it 'should turn left immediately to the desired heading if within range' do
          test_rotation(@simplicity.driver, 8, -10)
        end
        it 'should turn right immediately to the desired heading if within range' do
          test_rotation(@simplicity.driver, 100, 10)
        end
        it 'should turn left the maximum amount toward the desired heading if outside of range' do
          test_rotation(@simplicity.driver, 79, -10)
        end
        it 'should turn right the maximum amount toward the desired heading if outside of range' do
          test_rotation(@simplicity.driver, 101, 10)
        end
        it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
          test_rotation(@simplicity.driver, 359, -10)
        end
        it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
          test_rotation(@simplicity.driver, -91, 10)
        end
      end
      describe 'It should turn its gun toward a desired heading' do
        describe 'It should turn its gun just like the hull if the hull is not turning' do
          before (:each) do
            @simplicity.driver.desired_heading = 90
          end
          it 'should not turn if it is at the desired heading' do
            test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading, 0)
          end
          it 'should turn left immediately to the desired heading if within range' do
            test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-30, -30)
          end
          it 'should turn right immediately to the desired heading if within range' do
            test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+30, 30)
          end
          it 'should turn left the maximum amount toward the desired heading if outside of range' do
            test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-31, -30)
          end
          it 'should turn right the maximum amount toward the desired heading if outside of range' do
            test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+31, 30)
          end
          it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+181, -30)
          end
          it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-181, 30)
          end
        end
        describe 'It should adjust for any hull movement' do
          describe 'It should adjust for left hull movement' do
            before (:each) do
              @simplicity.driver.desired_heading = 100
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-30, -30)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+30, 30)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-31, -30)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+31, 30)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+181, -30)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-181, 30)
            end
          end
          describe 'It should adjust for right hull movement' do
            before (:each) do
              @simplicity.driver.desired_heading = 80
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-30, -30)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+30, 30)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-31, -30)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+31, 30)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading+181, -30)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.gunner, @simplicity.driver.desired_heading-181, 30)
            end
          end
        end
      end
      describe 'It should turn its radar toward a desired heading' do
        describe 'It should turn just like the hull if the hull and gun are not turning' do
          before (:each) do
            @simplicity.driver.desired_heading = 90
            @simplicity.gunner.desired_heading = @simplicity.driver.desired_heading
          end
          it 'should not turn if it is at the desired heading' do
            test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading, 0)
          end
          it 'should turn left immediately to the desired heading if within range' do
            test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-60, -60)
          end
          it 'should turn right immediately to the desired heading if within range' do
            test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+60, 60)
          end
          it 'should turn left the maximum amount toward the desired heading if outside of range' do
            test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-61, -60)
          end
          it 'should turn right the maximum amount toward the desired heading if outside of range' do
            test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+61, 60)
          end
          it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+181, -60)
          end
          it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-181, 60)
          end
        end
        describe 'It should adjust for any hull movement' do
          describe 'It should adjust for left hull movement' do
            before (:each) do
              @simplicity.driver.desired_heading = 100
              @simplicity.gunner.desired_heading = @simplicity.driver.desired_heading
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-181, 60)
            end
          end
          describe 'It should adjust for right hull movement' do
            before (:each) do
              @simplicity.driver.desired_heading = 80
              @simplicity.gunner.desired_heading = @simplicity.driver.desired_heading
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-181, 60)
            end
          end
        end
        describe 'It should adjust for any gun movement' do
          describe 'It should adjust for left gun movement' do
            before (:each) do
              @simplicity.driver.desired_heading = 90
              @simplicity.gunner.desired_heading = @simplicity.driver.desired_heading + 30
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-181, 60)
            end
          end
          describe 'It should adjust for right gun movement' do
            before (:each) do
              @simplicity.driver.desired_heading = 90
              @simplicity.gunner.desired_heading = @simplicity.driver.desired_heading - 30
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@simplicity.radar, @simplicity.gunner.desired_heading-181, 60)
            end
          end
        end
      end
    end
    describe 'towards targets' do
      describe 'It should aim its hull toward a desired position' do
        it 'should be able to aim east' do
          test_aim_at_target(@simplicity.driver, Vector[1600,800], 0)
        end
        it 'should be able to aim northeast' do
          test_aim_at_target(@simplicity.driver, Vector[1600,0], 45)
        end
        it 'should be able to aim north' do
          test_aim_at_target(@simplicity.driver, Vector[800,0], 90)
        end
        it 'should be able to aim northwest' do
          test_aim_at_target(@simplicity.driver, Vector[0,0], 135)
        end
        it 'should be able to aim west' do
          test_aim_at_target(@simplicity.driver, Vector[0,800], 180)
        end
        it 'should be able to aim southwest' do
          test_aim_at_target(@simplicity.driver, Vector[0,1600], 225)
        end
        it 'should be able to aim south' do
          test_aim_at_target(@simplicity.driver, Vector[800,1600], 270)
        end
        it 'should be able to aim southeast' do
          test_aim_at_target(@simplicity.driver, Vector[1600,1600], 315)
        end
      end
      describe 'It should aim its gun toward desired targets' do
        it 'should be able to aim east' do
          test_aim_at_target(@simplicity.gunner, Vector[1600,800], 0)
        end
        it 'should be able to aim northeast' do
          test_aim_at_target(@simplicity.gunner, Vector[1600,0], 45)
        end
        it 'should be able to aim north' do
          test_aim_at_target(@simplicity.gunner, Vector[800,0], 90)
        end
        it 'should be able to aim northwest' do
          test_aim_at_target(@simplicity.gunner, Vector[0,0], 135)
        end
        it 'should be able to aim west' do
          test_aim_at_target(@simplicity.gunner, Vector[0,800], 180)
        end
        it 'should be able to aim southwest' do
          test_aim_at_target(@simplicity.gunner, Vector[0,1600], 225)
        end
        it 'should be able to aim south' do
          test_aim_at_target(@simplicity.gunner, Vector[800,1600], 270)
        end
        it 'should be able to aim southeast' do
          test_aim_at_target(@simplicity.gunner, Vector[1600,1600], 315)
        end
      end
      describe 'It should aim its radar toward desired targets' do
        it 'should be able to aim east' do
          test_aim_at_target(@simplicity.radar, Vector[1600,800], 0)
        end
        it 'should be able to aim northeast' do
          test_aim_at_target(@simplicity.radar, Vector[1600,0], 45)
        end
        it 'should be able to aim north' do
          test_aim_at_target(@simplicity.radar, Vector[800,0], 90)
        end
        it 'should be able to aim northwest' do
          test_aim_at_target(@simplicity.radar, Vector[0,0], 135)
        end
        it 'should be able to aim west' do
          test_aim_at_target(@simplicity.radar, Vector[0,800], 180)
        end
        it 'should be able to aim southwest' do
          test_aim_at_target(@simplicity.radar, Vector[0,1600], 225)
        end
        it 'should be able to aim south' do
          test_aim_at_target(@simplicity.radar, Vector[800,1600], 270)
        end
        it 'should be able to aim southeast' do
          test_aim_at_target(@simplicity.radar, Vector[1600,1600], 315)
        end
      end
    end
  end
  describe 'It should move' do
    before(:each) do
      @simplicity.base_test
      @simplicity.stub!(:x).and_return(800)
      @simplicity.stub!(:y).and_return(800)
    end
    describe 'at a desired speed' do
      before(:each) do
        @simplicity.driver.desired_target = nil
      end
      it 'should not accelerate if already at desired speed' do
        test_acceleration(0,0)
      end
      it 'should accelerate if moving slower than desired speed' do
        test_acceleration(8,1)
      end
      it 'should decelerate if moving faster than desired speed' do
        test_acceleration(-8,-1)
      end
    end
    describe "to a desired position" do
      it 'should not move if at the desired position' do
        test_move_to_position(Vector[800,800], 0)
      end
      it 'should accelerate to 1 if 1 <= distance < 4' do
        test_move_to_position(Vector[803,800], 1)
      end
      it 'should accelerate to 2 if 4 <= distance < 9' do
        test_move_to_position(Vector[808,800], 2)
      end
      it 'should accelerate to 3 if 9 <= distance < 16' do
        test_move_to_position(Vector[815,800], 3)
      end
      it 'should accelerate to 4 if 16 <= distance < 25' do
        test_move_to_position(Vector[824,800], 4)
      end
      it 'should accelerate to 5 if 25 < distance < 36' do
        test_move_to_position(Vector[835,800], 5)
      end
      it 'should accelerate to 6 if 36 < distance < 49' do
        test_move_to_position(Vector[848,800], 6)
      end
      it 'should accelerate to 7 if 49 < distance < 64' do
        test_move_to_position(Vector[863,800], 7)
      end
      it 'should accelerate to >= if 64' do
        test_move_to_position(Vector[864,800], 8)
      end
      it 'should clamp at 8' do
        test_move_to_position(Vector[1600,800], 8)
      end
      it 'should clamp at desired maximum speed' do
        @simplicity.driver.desired_max_speed = 4
        test_move_to_position(Vector[1600,800], 4)
      end
    end
  end
  describe 'It should fire' do
    it 'should fire at the desired power' do
      @simplicity.loader.power = 1
      @simplicity.should_receive(:fire).with(1)
      @simplicity.tick nil
    end
  end
  describe 'It should know about being hit' do
    it 'should know if it was never hit' do
      @simplicity.tick nil
      @simplicity.last_hit_time.should == nil
    end

    it 'should know when it was hit' do
      events = Hash.new{|h, k| h[k]=[]}
      events['got_hit'] << 1
      @simplicity.tick events
      @simplicity.last_hit_time.should == @simplicity.time
    end
  end
  describe 'It should handle radar scans' do
    it 'should be ok with no scanned robots' do
      @simplicity.tick @events
    end
    it 'should store targets as sightings' do
      @simplicity.previous_status.radar_heading = 270
      @simplicity.stub!(:radar_heading).and_return(360)
      @events['robot_scanned'] << [400] << [300]
      @simplicity.tick @events
      @simplicity.radar.sightings.should == [Sighting.new(270, 360, 400, 1, @position, 2), Sighting.new(270, 360, 300, 1, @position, 2)]
    end
  end
  describe 'It should scan for the targets' do
    describe 'It should start with a quick wide range search' do
      it 'should start by doing six 60 degree scans' do
        do_quick_scan
      end
      it 'should continue searching if nothing is found' do
        do_quick_scan
        do_quick_scan
      end
      it 'should aim at the first sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(0, 60, 400, 1, @position, 0))
#        print "#{@bot.radar.targets}\n"
        total_rotation.should == 0
      end
      it 'should aim at the second sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(60, 120, 400, 1, @position, 0))
        @simplicity.gunner.desired_heading.should == 90
        @simplicity.radar.desired_heading.should == 60
      end
      it 'should aim at the third sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(120, 180, 400, 1, @position, 0))
        @simplicity.gunner.desired_heading.should == 150
        @simplicity.radar.desired_heading.should == 120
      end
      it 'should aim at the fourth sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(180, 240, 400, 1, @position, 0))
        @simplicity.gunner.desired_heading.should == 210
        @simplicity.radar.desired_heading.should == 180
      end
      it 'should aim at the fifth sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(240, 300, 400, 1, @position, 0))
        @simplicity.gunner.desired_heading.should == 270
        @simplicity.radar.desired_heading.should == 240
      end
      it 'should aim at the sixth sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(300, 360, 400, 1, @position, 0))
        @simplicity.gunner.desired_heading.should == 330
        @simplicity.radar.desired_heading.should == 300
      end
      it 'should aim at the quadrant of the nearest target' do
        targets = Array.new
        targets << Sighting.new(0, 60, 600, 1, @position, 0) << Sighting.new(60, 120, 500, 1, @position, 0) << Sighting.new(120, 180, 400, 1, @position, 0) << Sighting.new(180, 240, 300, 1, @position, 0) << Sighting.new(240, 300, 200, 1, @position, 0) << Sighting.new(300, 360, 100, 1, @position, 0)
        do_quick_scan(targets)
        @simplicity.gunner.desired_heading.should == 330
        @simplicity.radar.desired_heading.should == 300
      end
    end
  end
  describe "It should fight stationary targets that don't shoot" do
    it 'should do a binary search' do
      @target = Vector[168,400]

      do_quick_scan(Sighting.new(120, 180, 400, 1, @position, 0))
      expect_first_scan(120, 150, 30)
      expect_scan(150, 15)
      expect_scan(165, 7)
    end
    it 'should work for position Vector[1435,65] and target Vector[342,531] with radar_heading = 105' do
      target = Vector[342,531]
      position = Vector[1435,65]
      angle = Math.atan2(position[1]-target[1],target[0]-position[0]).to_deg + 360
      distance = Math.hypot(target[0] - position[0], target[1] - position[1])
#      print "target #{target} pos #{position} angle #{angle} dis #{distance}\n"

      @simplicity.stub!(:x).and_return(position[0])
      @simplicity.stub!(:y).and_return(position[1])
      @simplicity.stub!(:radar_heading).and_return(105)
      do_quick_scan(Sighting.new(165, 225, 1188, 1, position, 0))

      expect_first_scan(165, 195, 30)
      expect_scan(195, 15)
      expect_scan(210, -8, [1188])
      expect_scan(202, 4, [1188])
      expect_scan(206, -2, [1188])
    end
    it 'should work for position Vector[416,610] and target Vector[968,1540] with radar_heading = 97' do
      position = Vector[416,610]
      target = Vector[968,1540]
      angle = Math.atan2(position[1] - target[1], target[0] - position[0]).to_deg.normalize_angle
      distance = Math.hypot(target[0] - position[0], target[1] - position[1])
#      print "target #{target} pos #{position} angle #{angle} dis #{distance}\n"

      @simplicity.stub!(:x).and_return(position[0])
      @simplicity.stub!(:y).and_return(position[1])
      @simplicity.stub!(:radar_heading).and_return(97)
      do_quick_scan(Sighting.new(97, 157, 1081, 1, position, 0))

      expect_first_scan(97, 127, 30)
      expect_scan(127, -15, [1081])
      expect_scan(112, 7, [1081])
      expect_scan(119, 4)
      expect_scan(123, -2, [1081])
    end
    it 'should not attack its partner' do
      target = Vector[1600,800]
      @events['broadcasts'] << ["P0" + target.encode, "east"]
      do_quick_scan(Sighting.new(0, 60, 800, 1, @position, 0))
      do_quick_scan(Sighting.new(0, 60, 800, 1, @position, 0))
    end
    it 'should not attack any of its partners' do
      target = Vector[1600,800]
      target2 = Vector[0,800]
      @events['broadcasts'] << ["P0" + target.encode, "east"] << ["P1" + target2.encode, "west"]
      do_quick_scan([Sighting.new(0, 60, 800, 1, @position, 0), Sighting.new(120, 180, 800, 1, @position, 0)])
      do_quick_scan([Sighting.new(0, 60, 800, 1, @position, 0), Sighting.new(120, 180, 800, 1, @position, 0)])
    end
    describe 'It should maintain lock until the target is not seen' do
      before(:each) do
        position = Vector[416,610]
        target = Vector[968,1540]
        angle = Math.atan2(position[1] - target[1], target[0] - position[0]).to_deg.normalize_angle
        distance = Math.hypot(target[0] - position[0], target[1] - position[1])

        @simplicity.stub!(:x).and_return(position[0])
        @simplicity.stub!(:y).and_return(position[1])
        @simplicity.stub!(:radar_heading).and_return(97)
        do_quick_scan(Sighting.new(97, 157, 1081, 1, position, 0))

        expect_first_scan(97, 127, 30)
        expect_scan(127, -15, [1081])
        expect_scan(112, 7, [1081])
        expect_scan(119, 4)
        expect_scan(123, -2, [1081])
      end
      it 'should look the other direction if target is seen' do
        expect_scan(121, 2, [1081])
      end
    end
  end
  describe 'It should communicate with its partner' do
    it 'should send its position for 0,0' do
      @simplicity.stub!(:x).and_return(0)
      @simplicity.stub(:y).and_return(0)
      @simplicity.should_receive(:broadcast).with("P10,0")
      @simplicity.tick @events
    end
    it 'should send its position for 123, 123 in base 36 as 3f,3f' do
      @simplicity.stub!(:x).and_return(123)
      @simplicity.stub(:y).and_return(123)
      @simplicity.should_receive(:broadcast).with("P13f,3f")
      @simplicity.tick @events
    end
    it 'should send its position for 123, 123 in base 36 as 3f,3f' do
      @simplicity.stub!(:x).and_return(123)
      @simplicity.stub(:y).and_return(123)
      @simplicity.should_receive(:broadcast).with("P13f,3f")
      @simplicity.tick @events
    end
    it 'should receive its partners position P03f,3f as 123,123' do
      @events['broadcasts'] << ["P03f,3f", "east"]
      @simplicity.tick @events
      @simplicity.current_partner_position.should == [Vector[123,123]]
    end
    describe 'It should determine its role based on communication' do
      it 'should receive multiple partners positions' do
        @events['broadcasts'] << ["P13f,3f", "east"] << ["P20,0", "west"]
        @simplicity.tick @events
        @simplicity.current_partner_position.should == [nil, Vector[123,123],Vector[0.0,0.0]]
      end
      it 'should be master if the first message is received at time 2' do
        @simplicity.stub!(:time).and_return(2)
        @events['broadcasts'] << ["P03f,3f", "east"]
        @simplicity.tick @events
        @simplicity.role.should == :master
      end
      it 'should be slave if the first message is received at time 1' do
        @simplicity.stub!(:time).and_return(1)
        @events['broadcasts'] << ["P03f,3f", "east"]
        @simplicity.tick @events
        @simplicity.role.should == :slave
      end
      it 'should be #1 if it sees 1 message on tick 1' do
        @simplicity.stub!(:time).and_return(1)
        @events['broadcasts'] << ["P03f,3f", "east"]
        @simplicity.tick @events
        @simplicity.id.should == 1
      end
      it 'should be #2 if it sees 2 messages on tick 1' do
        @simplicity.stub!(:time).and_return(1)
        @events['broadcasts'] << ["P03f,3f", "east"] << ["P22f,2f", "east"]
        @simplicity.tick @events
        @simplicity.id.should == 2
      end
      it 'should be #2 if it sees 1 messages on tick 2' do
        @simplicity.stub!(:time).and_return(2)
        @events['broadcasts'] << ["P03f,3f", "east"]
        @simplicity.tick @events
        @simplicity.id.should == 2
      end
      it 'should be #3 if it sees 2 messages on tick 2' do
        @simplicity.stub!(:time).and_return(2)
        @events['broadcasts'] << ["P03f,3f", "east"] << ["P02f,2f", "east"]
        @simplicity.tick @events
        @simplicity.id.should == 3
      end
    end
    describe 'It should communicate radar information' do
      it 'should send radar information' do
        @simplicity.stub!(:x).and_return(123)
        @simplicity.stub(:y).and_return(123)
        @simplicity.previous_status = Status.new(Vector[123,123], 0, 0, 0, 0)
        @simplicity.stub(:radar_heading).and_return(10)
        @simplicity.should_receive(:broadcast).with("R13f,3f;2,0,a,1,2")
        @events['robot_scanned'] << [1] << [2]
        @simplicity.tick @events
      end
      it 'should receive its radar information' do
        @events['broadcasts'] << ["R03f,3f,2,0,a,1,2", "east"]
        @simplicity.tick @events
        @simplicity.current_partner_position.should == [Vector[123,123]]
      end
    end
  end
end

describe 'Sighting' do
  it 'should have its members' do
    sighting = Sighting.new(1, 2, 3, 1, @position, 4)
    sighting.start_angle.should == 1
    sighting.end_angle.should == 2
    sighting.distance.should == 3
    sighting.time.should == 4
    sighting.direction.should == 1
  end
  it 'should make all angles between 0 and 360' do
    sighting = Sighting.new(-10, -180, 0, 1, @position, 0)
    sighting.start_angle.should == 350
    sighting.end_angle.should == 180
  end
  describe 'It should calculate needed values' do
    describe 'It should calculate arc length' do
      it 'should calculate arc length' do
        sighting = Sighting.new(90, 270, 100, 1, @position, 0)
        sighting.central_angle.should == 180
      end
      it 'should be positive' do
        sighting = Sighting.new(270, 90, 100, -1, @position, 0)
        sighting.central_angle.should == 180
      end
      it 'should handle passing 0' do
        sighting = Sighting.new(350, 10, 100, 1, @position, 0)
        sighting.central_angle.should == 20
      end
    end
    describe 'It should calculate the bisector' do
      it 'should calculate the bisector normal case' do
        sighting = Sighting.new(90, 270, 100, 1, @position, 0)
        sighting.bisector.should == 180
      end

      it 'should calculate the bisector when it crosses 0' do
        sighting = Sighting.new(300, 360, 100, 1, @position, 0)
        sighting.bisector.should == 330
      end

      it 'should calculate the bisector when the start and end are swapped' do
        sighting = Sighting.new(210, 202, 100, -1, @position, 0)
        sighting.bisector.should == 206
      end
    end
  end
  describe 'It should broaden the scan' do
    it 'should subtract from the start_angle if necessary' do
      sighting = Sighting.new(10, 12, 100, 1, @position, 0)
      sighting.broaden(1)
      sighting.start_angle.should == 9
    end
    it 'should add to the start_angle if necessary' do
      sighting = Sighting.new(12, 10, 100, -1, @position, 0)
      sighting.broaden(1)
      sighting.start_angle.should == 13
    end
    it 'should work for 254, 257' do
      sighting = Sighting.new(254, 257, 100, 1, @position, 0)
      sighting.broaden(1)
      sighting.start_angle.should == 253
    end
    it 'should work for 257, 254' do
      sighting = Sighting.new(257, 254, 100, -1, @position, 0)
      sighting.broaden(1)
      sighting.start_angle.should == 258
    end
    it 'should work for 355,15' do
      sighting = Sighting.new(355, 15, 100,1,  @position, 0)
      sighting.broaden(10)
      sighting.start_angle.should == 345
    end
    it 'should work for 15,355' do
      sighting = Sighting.new(15, 355, 100, -1, @position, 0)
      sighting.broaden(10)
      sighting.start_angle.should == 25
    end
  end
end

describe 'Target' do
  before (:each) do
    @target = Target.new(Vector[800,800], 0)
  end
  it 'should have a current position' do
    @target.position.should == Vector[800,800]
  end
  it 'should have the time of the last update' do
    @target.time.should == 0
  end
  it 'should have velocity of 0' do
    @target.velocity.should == 0
  end
  it 'should have a heading of 0' do
    @target.heading.should == 0
  end
  it 'should have a velocity vector of 0,0' do
    @target.velocity_vector.should == Vector[0,0]
  end
  describe 'It should accept updates' do
    before(:each) do
      @new_position = Vector[792,800]
      @new_time = 1
      @target.update(@new_position, @new_time)
    end
    it 'should update its position' do
      @target.position.should == @new_position
    end
    it 'should update its time' do
      @target.time.should == @new_time
    end
    it 'should update its velocity' do
      @target.velocity.should == 8
    end
    it 'should update its heading' do
      @target.heading.should == 180
    end
  end
  it 'should provide a velocity vector' do
    target = Target.new(Vector[800,800], 0)
    target.update(Vector[805,795],1)
    target.velocity_vector.should == Vector[5,-5]
    target.update(Vector[795, 805], 3)
    target.velocity_vector.should == Vector[-5,5]
  end
  describe 'It should calculate linear firing angles' do
    it 'should calculate impact times' do
      target = Target.new(Vector[800,800], 0)
      target.update(Vector[800,800], 1)
      target.impact_time(Vector[740,800], 30).should == 2
    end
  end
end
