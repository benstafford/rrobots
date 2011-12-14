$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')

require 'PolarIce'
require 'Matrix'

def test_acceleration(desiredSpeed, expectedAcceleration)
  @bot.stub!(:speed).and_return(0)
  @bot.desiredDriverSpeed = desiredSpeed
  @bot.should_receive(:accelerate).with(expectedAcceleration)
  @bot.tick nil
end

def test_move_to_position(desiredTarget, expectedSpeed)
  @bot.desiredDriverTarget = desiredTarget
  @bot.tick nil
  @bot.desiredDriverSpeed.should == expectedSpeed
end

def test_rotation(rotator, desiredHeading, expectedRotation)
  rotator.desiredHeading = desiredHeading
  @bot.tick nil
  rotator.rotation.should == expectedRotation
end

def test_aim_at_target(rotator, desiredTarget, expectedHeading)
  rotator.desiredTarget = desiredTarget
  @bot.tick nil
  rotator.desiredHeading.should == expectedHeading
end

def total_rotation
  (@bot.radarRotation + @bot.gunnerRotation + @bot.driverRotation)
end

def scan_60_degrees
  @bot.tick @events
  total_rotation.should == 60
end

def do_quick_scan(targets = nil)
  5.times { scan_60_degrees }
  if (targets != nil)
    if (targets.class == Array)
      @bot.radar.targets += targets
    else
      @bot.radar.targets << targets
    end
  end
#  scan_60_degrees
  @bot.tick @events
end

def expect_first_scan(radarHeading, gunHeading, turn, robotScanned=nil)
  @events['robot_scanned'].clear
  @events['robot_scanned'] << robotScanned if robotScanned != nil
  @bot.stub!(:radar_heading).and_return(radarHeading)
  @bot.stub!(:gun_heading).and_return(gunHeading)
  @bot.tick @events
  (@bot.driverRotation + @bot.gunnerRotation + @bot.radarRotation).should == turn
end

def expect_scan(heading, turn, robotScanned=nil)
  @events['robot_scanned'].clear
  @events['robot_scanned'] << robotScanned if robotScanned != nil
  @bot.stub!(:radar_heading).and_return(heading)
  @bot.stub!(:gun_heading).and_return(heading)
  @bot.tick @events
  (@bot.driverRotation + @bot.gunnerRotation + @bot.radarRotation).should == turn
end

describe 'PolarIce' do
  before(:each) do
    @bot = PolarIce.new

    @events = Hash.new{|h, k| h[k]=[]}

    @bot.stub!(:accelerate)
    @bot.stub!(:turn)
    @bot.stub!(:turn_gun)
    @bot.stub!(:turn_radar)
    @bot.stub!(:fire)
    @bot.stub!(:broadcast)
    @bot.stub!(:say)

    @bot.stub!(:x).and_return(800)
    @bot.stub!(:y).and_return(800)
    @bot.stub!(:speed).and_return(0)
    @bot.stub!(:heading).and_return(0)
    @bot.stub!(:gun_heading).and_return(0)
    @bot.stub!(:radar_heading).and_return(0)
    @bot.stub!(:time).and_return(0)
    @bot.stub!(:size).and_return(60)

    @position = Vector[800,800]

    @bot.desiredDriverTarget = nil
    @bot.desiredDriverHeading = nil
    @bot.desiredDriverSpeed = nil
    @bot.desiredGunnerTarget = nil
    @bot.desiredGunnerHeading = nil
    @bot.desiredRadarTarget = nil
    @bot.desiredRadarHeading = nil
    @bot.desiredDriverMaximumSpeed = 8
  end

  describe 'It should know its environment' do
    describe 'It should know its location' do
      it 'should know its x value' do
        @bot.stub!(:x).and_return(5)
        @bot.x.should == 5
      end
      it 'should know its y value' do
        @bot.stub!(:y).and_return(5)
        @bot.y.should == 5
      end
    end
    describe 'It should know its headings' do
      it 'should know its heading' do
        @bot.stub!(:heading).and_return(1)
        @bot.heading.should == 1
      end
      it 'should know its gun heading' do
        @bot.stub!(:gun_heading).and_return(2)
        @bot.gun_heading.should == 2
      end
      it 'should know its radar heading' do
        @bot.stub!(:radar_heading).and_return(3)
        @bot.radar_heading.should == 3
      end
    end
    describe 'It should know the battlefield' do
      it 'should know the battlefield width' do
        @bot.stub!(:battlefield_width).and_return(1)
        @bot.battlefield_width.should == 1
      end
      it 'should know the battlefield height' do
        @bot.stub!(:battlefield_height).and_return(1)
        @bot.battlefield_height.should == 1
      end
      it 'should know the time' do
        @bot.stub!(:time).and_return(5)
        @bot.time.should == 5
      end
    end
    describe 'It should know its life' do
      it 'should know its remaining energy' do
        @bot.stub!(:energy).and_return(1)
        @bot.energy.should == 1
      end
      it 'should know that it is alive' do
        @bot.stub!(:dead).and_return(false)
        @bot.dead.should == false
      end
    end
    describe 'It should know its other status' do
      it 'should know the heat of its gun' do
        @bot.stub!(:gun_heat).and_return(1)
        @bot.gun_heat.should == 1
      end
      it 'should know its size' do
        @bot.stub!(:size).and_return(1)
        @bot.size.should == 1
      end
      it 'should know its current speed' do
        @bot.stub!(:speed).and_return(1)
        @bot.speed.should == 1
      end
    end
  end
  describe 'It should initialize variables' do
    it 'should have a default acceleration rate' do
      @bot.driver.acceleration.should_not == nil
    end
    it 'should have a default hull rotation' do
      @bot.driver.rotation.should_not == nil
    end
    it 'should have a default gun rotation' do
      @bot.gunner.rotation.should_not == nil
    end
    it 'should have a default radar rotation' do
      @bot.radar.rotation.should_not == nil
    end
    it 'should have a default fire power' do
      @bot.desiredLoaderPower.should_not == nil
    end
    it 'should have a default broadcast message' do
      @bot.broadcastMessage.should_not == nil
    end
    it 'should have a default quote' do
      @bot.quote.should_not == nil
    end
  end
  describe 'It should perform actions on each tick' do
    before(:each) do
      @bot.base_test
    end
    it 'should handle a nil tick' do
      @bot.tick nil
    end
    describe 'It should initialize variables on a tick' do
      it 'should store its position as a vector' do
        @bot.tick nil
        @bot.currentPosition.should == Vector[800,800]
      end
    end
    describe 'It should move its parts' do
      it 'should accelerate' do
        @bot.should_receive(:accelerate)
        @bot.tick nil
      end
      it 'should rotate its hull' do
        @bot.should_receive(:turn)
        @bot.tick nil
      end
      it 'should rotate its gun' do
        @bot.should_receive(:turn_gun)
        @bot.tick nil
      end
      it 'should rotate its radar' do
        @bot.should_receive(:turn_radar)
        @bot.tick nil
      end
      it 'should fire' do
        @bot.should_receive(:fire)
        @bot.tick nil
      end
      it 'should broadcast' do
        @bot.should_receive(:broadcast)
        @bot.tick nil
      end
      it 'should say' do
        @bot.should_receive(:say)
        @bot.tick nil
      end
    end
    describe 'It should move its parts desired amounts' do
      it 'should accelerate the desired amount' do
        @bot.driver.acceleration = 1
        @bot.should_receive(:accelerate).with(1)
        @bot.perform_actions
      end
      it 'should rotate its hull the desired amount' do
        @bot.driver.rotation = 10
        @bot.should_receive(:turn).with(10)
        @bot.perform_actions
      end
      it 'should rotate its gun the desired amount' do
        @bot.gunner.rotation = 15
        @bot.should_receive(:turn_gun).with(15)
        @bot.perform_actions
      end
      it 'should rotate its radar the desired amount' do
        @bot.radar.rotation = 15
        @bot.should_receive(:turn_radar).with(15)
        @bot.perform_actions
      end
      it 'should fire the desired amount' do
        @bot.desiredLoaderPower = 0.1
        @bot.should_receive(:fire).with(0.1)
        @bot.perform_actions
      end
      it 'should broadcast the desired message' do
        @bot.broadcastMessage = "message"
        @bot.should_receive(:broadcast).with("message")
        @bot.perform_actions
      end
      it 'should say the desired quote' do
        @bot.quote = "quote"
        @bot.should_receive(:say).with("quote")
        @bot.perform_actions
      end
    end
  end
  describe 'It should know information from the previous tick' do
    before(:each) do
      @bot.stub!(:radar_heading).and_return(3)
      @bot.tick nil
      @bot.stub!(:radar_heading).and_return(4)
    end
    it 'should know its previous radar heading' do
      @bot.previousRadarHeading.should == 3
    end
  end
  describe 'It should turn' do
    before(:each) do
      @bot.stub!(:x).and_return(800)
      @bot.stub!(:y).and_return(800)
      @bot.stub!(:speed).and_return(0)
      @bot.stub!(:heading).and_return(90)
      @bot.stub!(:gun_heading).and_return(90)
      @bot.stub!(:radar_heading).and_return(90)
      @bot.base_test
    end
    describe 'towards headings' do
      describe 'It should turn its hull toward a desired heading' do
        it 'should not turn if it is at the desired heading' do
          test_rotation(@bot.driver, 90, 0)
        end
        it 'should turn left immediately to the desired heading if within range' do
          test_rotation(@bot.driver, 8, -10)
        end
        it 'should turn right immediately to the desired heading if within range' do
          test_rotation(@bot.driver, 100, 10)
        end
        it 'should turn left the maximum amount toward the desired heading if outside of range' do
          test_rotation(@bot.driver, 79, -10)
        end
        it 'should turn right the maximum amount toward the desired heading if outside of range' do
          test_rotation(@bot.driver, 101, 10)
        end
        it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
          test_rotation(@bot.driver, 359, -10)
        end
        it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
          test_rotation(@bot.driver, -91, 10)
        end
      end
      describe 'It should turn its gun toward a desired heading' do
        describe 'It should turn its gun just like the hull if the hull is not turning' do
          before (:each) do
            @bot.desiredDriverHeading = 90
          end
          it 'should not turn if it is at the desired heading' do
            test_rotation(@bot.gunner, @bot.desiredDriverHeading, 0)
          end
          it 'should turn left immediately to the desired heading if within range' do
            test_rotation(@bot.gunner, @bot.desiredDriverHeading-30, -30)
          end
          it 'should turn right immediately to the desired heading if within range' do
            test_rotation(@bot.gunner, @bot.desiredDriverHeading+30, 30)
          end
          it 'should turn left the maximum amount toward the desired heading if outside of range' do
            test_rotation(@bot.gunner, @bot.desiredDriverHeading-31, -30)
          end
          it 'should turn right the maximum amount toward the desired heading if outside of range' do
            test_rotation(@bot.gunner, @bot.desiredDriverHeading+31, 30)
          end
          it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@bot.gunner, @bot.desiredDriverHeading+181, -30)
          end
          it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@bot.gunner, @bot.desiredDriverHeading-181, 30)
          end
        end
        describe 'It should adjust for any hull movement' do
          describe 'It should adjust for left hull movement' do
            before (:each) do
              @bot.desiredDriverHeading = 100
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading-30, -30)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading+30, 30)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading-31, -30)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading+31, 30)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading+181, -30)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading-181, 30)
            end
          end
          describe 'It should adjust for right hull movement' do
            before (:each) do
              @bot.desiredDriverHeading = 80
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading-30, -30)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading+30, 30)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading-31, -30)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading+31, 30)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading+181, -30)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.gunner, @bot.desiredDriverHeading-181, 30)
            end
          end
        end
      end
      describe 'It should turn its radar toward a desired heading' do
        describe 'It should turn just like the hull if the hull and gun are not turning' do
          before (:each) do
            @bot.desiredDriverHeading = 90
            @bot.desiredGunnerHeading = @bot.desiredDriverHeading
          end
          it 'should not turn if it is at the desired heading' do
            test_rotation(@bot.radar, @bot.desiredGunnerHeading, 0)
          end
          it 'should turn left immediately to the desired heading if within range' do
            test_rotation(@bot.radar, @bot.desiredGunnerHeading-60, -60)
          end
          it 'should turn right immediately to the desired heading if within range' do
            test_rotation(@bot.radar, @bot.desiredGunnerHeading+60, 60)
          end
          it 'should turn left the maximum amount toward the desired heading if outside of range' do
            test_rotation(@bot.radar, @bot.desiredGunnerHeading-61, -60)
          end
          it 'should turn right the maximum amount toward the desired heading if outside of range' do
            test_rotation(@bot.radar, @bot.desiredGunnerHeading+61, 60)
          end
          it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@bot.radar, @bot.desiredGunnerHeading+181, -60)
          end
          it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
            test_rotation(@bot.radar, @bot.desiredGunnerHeading-181, 60)
          end
        end
        describe 'It should adjust for any hull movement' do
          describe 'It should adjust for left hull movement' do
            before (:each) do
              @bot.desiredDriverHeading = 100
              @bot.desiredGunnerHeading = @bot.desiredDriverHeading
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-181, 60)
            end
          end
          describe 'It should adjust for right hull movement' do
            before (:each) do
              @bot.desiredDriverHeading = 80
              @bot.desiredGunnerHeading = @bot.desiredDriverHeading
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-181, 60)
            end
          end
        end
        describe 'It should adjust for any gun movement' do
          describe 'It should adjust for left gun movement' do
            before (:each) do
              @bot.desiredDriverHeading = 90
              @bot.desiredGunnerHeading = @bot.desiredDriverHeading + 30
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-181, 60)
            end
          end
          describe 'It should adjust for right gun movement' do
            before (:each) do
              @bot.desiredDriverHeading = 90
              @bot.desiredGunnerHeading = @bot.desiredDriverHeading - 30
            end
            it 'should not turn if it is at the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading, 0)
            end
            it 'should turn left immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-60, -60)
            end
            it 'should turn right immediately to the desired heading if within range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+60, 60)
            end
            it 'should turn left the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-61, -60)
            end
            it 'should turn right the maximum amount toward the desired heading if outside of range' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+61, 60)
            end
            it 'should turn right the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading+181, -60)
            end
            it 'should turn left the maximum amount if that is the shortest angular distance from the desired heading' do
              test_rotation(@bot.radar, @bot.desiredGunnerHeading-181, 60)
            end
          end
        end
      end
    end
    describe 'towards targets' do
      describe 'It should aim its hull toward a desired position' do
        it 'should be able to aim east' do
          test_aim_at_target(@bot.driver, Vector[1600,800], 0)
        end
        it 'should be able to aim northeast' do
          test_aim_at_target(@bot.driver, Vector[1600,0], 45)
        end
        it 'should be able to aim north' do
          test_aim_at_target(@bot.driver, Vector[800,0], 90)
        end
        it 'should be able to aim northwest' do
          test_aim_at_target(@bot.driver, Vector[0,0], 135)
        end
        it 'should be able to aim west' do
          test_aim_at_target(@bot.driver, Vector[0,800], 180)
        end
        it 'should be able to aim southwest' do
          test_aim_at_target(@bot.driver, Vector[0,1600], 225)
        end
        it 'should be able to aim south' do
          test_aim_at_target(@bot.driver, Vector[800,1600], 270)
        end
        it 'should be able to aim southeast' do
          test_aim_at_target(@bot.driver, Vector[1600,1600], 315)
        end
      end
      describe 'It should aim its gun toward desired targets' do
        it 'should be able to aim east' do
          test_aim_at_target(@bot.gunner, Vector[1600,800], 0)
        end
        it 'should be able to aim northeast' do
          test_aim_at_target(@bot.gunner, Vector[1600,0], 45)
        end
        it 'should be able to aim north' do
          test_aim_at_target(@bot.gunner, Vector[800,0], 90)
        end
        it 'should be able to aim northwest' do
          test_aim_at_target(@bot.gunner, Vector[0,0], 135)
        end
        it 'should be able to aim west' do
          test_aim_at_target(@bot.gunner, Vector[0,800], 180)
        end
        it 'should be able to aim southwest' do
          test_aim_at_target(@bot.gunner, Vector[0,1600], 225)
        end
        it 'should be able to aim south' do
          test_aim_at_target(@bot.gunner, Vector[800,1600], 270)
        end
        it 'should be able to aim southeast' do
          test_aim_at_target(@bot.gunner, Vector[1600,1600], 315)
        end
      end
      describe 'It should aim its radar toward desired targets' do
        it 'should be able to aim east' do
          test_aim_at_target(@bot.radar, Vector[1600,800], 0)
        end
        it 'should be able to aim northeast' do
          test_aim_at_target(@bot.radar, Vector[1600,0], 45)
        end
        it 'should be able to aim north' do
          test_aim_at_target(@bot.radar, Vector[800,0], 90)
        end
        it 'should be able to aim northwest' do
          test_aim_at_target(@bot.radar, Vector[0,0], 135)
        end
        it 'should be able to aim west' do
          test_aim_at_target(@bot.radar, Vector[0,800], 180)
        end
        it 'should be able to aim southwest' do
          test_aim_at_target(@bot.radar, Vector[0,1600], 225)
        end
        it 'should be able to aim south' do
          test_aim_at_target(@bot.radar, Vector[800,1600], 270)
        end
        it 'should be able to aim southeast' do
          test_aim_at_target(@bot.radar, Vector[1600,1600], 315)
        end
      end
    end
  end
  describe 'It should move' do
    before(:each) do
      @bot.base_test
      @bot.stub!(:x).and_return(800)
      @bot.stub!(:y).and_return(800)
    end
    describe 'at a desired speed' do
      before(:each) do
        @bot.desiredDriverTarget = nil
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
        @bot.desiredDriverMaximumSpeed = 4
        test_move_to_position(Vector[1600,800], 4)
      end
    end
  end
  describe 'It should fire' do
    it 'should fire at the desired power' do
      @bot.desiredLoaderPower = 1
      @bot.should_receive(:fire).with(1)
      @bot.tick nil
    end
  end
  describe 'It should know about being hit' do
    it 'should know if it was never hit' do
      @bot.tick nil
      @bot.lastHitTime.should == nil
    end

    it 'should know when it was hit' do
      events = Hash.new{|h, k| h[k]=[]}
      events['got_hit'] << 1
      @bot.tick events
      @bot.lastHitTime.should == 0
    end
  end
  describe 'It should handle radar scans' do
    it 'should be ok with no scanned robots' do
      @bot.tick @events
    end
    it 'should store targets as sightings' do
      @bot.previousRadarHeading = 270
      @bot.stub!(:radar_heading).and_return(360)
      @events['robot_scanned'] << [400] << [300]
      @bot.tick @events
      @bot.radar.targets.should == [Sighting.new(270, 360, 400, 1, @position, 0), Sighting.new(270, 360, 300, 1, @position, 0)]
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
        print "#{@bot.radar.targets}\n"
        
        total_rotation.should == 0
      end
      it 'should aim at the second sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(60, 120, 400, 1, @position, 0))
        @bot.desiredGunnerHeading.should == 90
        @bot.desiredRadarHeading.should == 60
      end
      it 'should aim at the third sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(120, 180, 400, 1, @position, 0))
        @bot.desiredGunnerHeading.should == 150
        @bot.desiredRadarHeading.should == 120
      end
      it 'should aim at the fourth sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(180, 240, 400, 1, @position, 0))
        @bot.desiredGunnerHeading.should == 210
        @bot.desiredRadarHeading.should == 180
      end
      it 'should aim at the fifth sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(240, 300, 400, 1, @position, 0))
        @bot.desiredGunnerHeading.should == 270
        @bot.desiredRadarHeading.should == 240
      end
      it 'should aim at the sixth sextant if it only saw a target there' do
        do_quick_scan(Sighting.new(300, 360, 400, 1, @position, 0))
        @bot.desiredGunnerHeading.should == 330
        @bot.desiredRadarHeading.should == 300
      end
      it 'should aim at the quadrant of the nearest target' do
        targets = Array.new
        targets << Sighting.new(0, 60, 600, 1, @position, 0) << Sighting.new(60, 120, 500, 1, @position, 0) << Sighting.new(120, 180, 400, 1, @position, 0) << Sighting.new(180, 240, 300, 1, @position, 0) << Sighting.new(240, 300, 200, 1, @position, 0) << Sighting.new(300, 360, 100, 1, @position, 0)
        do_quick_scan(targets)
        @bot.desiredGunnerHeading.should == 330
        @bot.desiredRadarHeading.should == 300
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
      print "target #{target} pos #{position} angle #{angle} dis #{distance}\n"

      @bot.stub!(:x).and_return(position[0])
      @bot.stub!(:y).and_return(position[1])
      @bot.stub!(:radar_heading).and_return(105)
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
      print "target #{target} pos #{position} angle #{angle} dis #{distance}\n"

      @bot.stub!(:x).and_return(position[0])
      @bot.stub!(:y).and_return(position[1])
      @bot.stub!(:radar_heading).and_return(97)
      do_quick_scan(Sighting.new(97, 157, 1081, 1, position, 0))

      expect_first_scan(97, 127, 30)
      expect_scan(127, -15, [1081])
      expect_scan(112, 7, [1081])
      expect_scan(119, 4)
      expect_scan(123, -2, [1081])
    end
    it 'should not attack its partner' do
      target = Vector[1600,800]
      @events['broadcasts'] << ["P" + target.encode, "east"]
      do_quick_scan(Sighting.new(0, 60, 800, 1, @position, 0))
      do_quick_scan(Sighting.new(0, 60, 800, 1, @position, 0))
    end
    describe 'It should maintain lock until the target is not seen' do
      before(:each) do
        position = Vector[416,610]
        target = Vector[968,1540]
        angle = Math.atan2(position[1] - target[1], target[0] - position[0]).to_deg.normalize_angle
        distance = Math.hypot(target[0] - position[0], target[1] - position[1])
        print "target #{target} pos #{position} angle #{angle} dis #{distance}\n"

        @bot.stub!(:x).and_return(position[0])
        @bot.stub!(:y).and_return(position[1])
        @bot.stub!(:radar_heading).and_return(97)
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
      @bot.stub!(:x).and_return(0)
      @bot.stub(:y).and_return(0)
      @bot.should_receive(:broadcast).with("P0,0")
      @bot.tick @events
    end
    it 'should send its position for 123.45, 123.45 in base 36 as 9ix,9ix' do
      @bot.stub!(:x).and_return(123.45)
      @bot.stub(:y).and_return(123.45)
      @bot.should_receive(:broadcast).with("P9ix,9ix")
      @bot.tick @events
    end
    it 'should receive its partners position P9ix,9ix as 123.45,123.45' do
      @events['broadcasts'] << ["P9ix,9ix", "east"]
      @bot.tick @events
      @bot.currentPartnerPosition.should == Vector[123.45,123.45]
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