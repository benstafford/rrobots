$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')

require 'PolarIce'
require 'Matrix'

describe 'PolarIce' do
  before(:each) do
    @bot = PolarIce.new
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
      @bot.accelerationRate.should_not == nil
    end
    it 'should have a default hull rotation' do
      @bot.hullRotation.should_not == nil
    end
    it 'should have a default gun rotation' do
      @bot.gunRotation.should_not == nil
    end
    it 'should have a default radar rotation' do
      @bot.radarRotation.should_not == nil
    end
    it 'should have a default fire power' do
      @bot.firePower.should_not == nil
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
      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(10)
      @bot.stub!(:accelerate)
      @bot.stub!(:turn)
      @bot.stub!(:turn_gun)
      @bot.stub!(:turn_radar)
      @bot.stub!(:fire)
      @bot.stub!(:broadcast)
      @bot.stub!(:say)
    end
    it 'should handle a nil tick' do
      @bot.tick nil
    end
    describe 'It should initialize variables on a tick' do
      it 'should store its position as a vector' do
        @bot.tick nil
        @bot.currentPosition.should == Vector[5,10]
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
        @bot.accelerationRate = 1
        @bot.should_receive(:accelerate).with(1)
        @bot.perform_actions
      end
      it 'should rotate its hull the desired amount' do
        @bot.hullRotation = 10
        @bot.should_receive(:turn).with(10)
        @bot.perform_actions
      end
      it 'should rotate its gun the desired amount' do
        @bot.gunRotation = 15
        @bot.should_receive(:turn_gun).with(15)
        @bot.perform_actions
      end
      it 'should rotate its radar the desired amount' do
        @bot.radarRotation = 15
        @bot.should_receive(:turn_radar).with(15)
        @bot.perform_actions
      end
      it 'should fire the desired amount' do
        @bot.firePower = 0.1
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
      @bot.stub!(:accelerate)
      @bot.stub!(:turn)
      @bot.stub!(:turn_gun)
      @bot.stub!(:turn_radar)
      @bot.stub!(:fire)
      @bot.stub!(:broadcast)
      @bot.stub!(:say)

      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(10)
      @bot.stub!(:speed).and_return(0)
      @bot.stub!(:heading).and_return(1)
      @bot.stub!(:gun_heading).and_return(2)
      @bot.stub!(:radar_heading).and_return(3)
      @bot.tick nil

      @bot.stub!(:x).and_return(6)
      @bot.stub!(:y).and_return(11)
      @bot.stub!(:speed).and_return(1)
      @bot.stub!(:heading).and_return(2)
      @bot.stub!(:gun_heading).and_return(3)
      @bot.stub!(:radar_heading).and_return(4)
    end
    it 'should know its previous position' do
      @bot.previousPosition.should == Vector[5,10]
    end
    it 'should know its previous heading' do
      @bot.previousHeading.should == 1
    end
    it 'should know its previous gun heading' do
      @bot.previousGunHeading.should == 2
    end
    it 'should know its previous radar heading' do
      @bot.previousRadarHeading.should == 3
    end
    it 'should know its previous speed' do
      @bot.previousSpeed.should == 0
    end

  end
  describe 'It should turn' do
    before(:each) do
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
      @bot.stub!(:heading).and_return(90)
      @bot.stub!(:gun_heading).and_return(90)
      @bot.stub!(:radar_heading).and_return(90)

      @bot.desiredPosition = nil
    end
    describe 'towards headings' do
      describe 'It should turn its hull toward a desired heading' do
        it 'should not turn if it is at the desired heading' do
          @bot.desiredHeading = 90
          @bot.should_receive(:turn).with(0)
          @bot.tick nil
        end
        it 'should turn counter-clockwise immediately to the desired heading if within range' do
          @bot.desiredHeading = 80
          @bot.should_receive(:turn).with(-10)
          @bot.tick nil
        end
        it 'should turn clockwise immediately to the desired heading if within range' do
          @bot.desiredHeading = 100
          @bot.should_receive(:turn).with(10)
          @bot.tick nil
        end
        it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
          @bot.desiredHeading = 79
          @bot.should_receive(:turn).with(-10)
          @bot.tick nil
        end
        it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
          @bot.desiredHeading = 101
          @bot.should_receive(:turn).with(10)
          @bot.tick nil
        end
        it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
          @bot.desiredHeading = 359
          @bot.should_receive(:turn).with(-10)
          @bot.tick nil
        end
        it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
          @bot.desiredHeading = -91
          @bot.should_receive(:turn).with(10)
          @bot.tick nil
        end
      end
      describe 'It should turn its gun toward a desired heading' do
        describe 'It should turn its gun just like the hull if the hull is not turning' do
          before (:each) do
            @bot.desiredHeading = 90
            @bot.desiredGunTarget = nil
            @bot.desiredPosition = nil
          end
          it 'should not turn if it is at the desired heading' do
            @bot.desiredGunHeading = @bot.desiredHeading
            @bot.should_receive(:turn_gun).with(0)
            @bot.tick nil
          end
          it 'should turn counter-clockwise immediately to the desired heading if within range' do
            @bot.desiredGunHeading = @bot.desiredHeading-30
            @bot.should_receive(:turn_gun).with(-30)
            @bot.tick nil
          end
          it 'should turn clockwise immediately to the desired heading if within range' do
            @bot.desiredGunHeading = @bot.desiredHeading+30
            @bot.should_receive(:turn_gun).with(30)
            @bot.tick nil
          end
          it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
            @bot.desiredGunHeading = @bot.desiredHeading-31
            @bot.should_receive(:turn_gun).with(-30)
            @bot.tick nil
          end
          it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
            @bot.desiredGunHeading = @bot.desiredHeading+31
            @bot.should_receive(:turn_gun).with(30)
            @bot.tick nil
          end
          it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
            @bot.desiredGunHeading = @bot.desiredHeading+181
            @bot.should_receive(:turn_gun).with(-30)
            @bot.tick nil
          end
          it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
            @bot.desiredGunHeading = @bot.desiredHeading-181
            @bot.should_receive(:turn_gun).with(30)
            @bot.tick nil
          end
        end
        describe 'It should adjust for any hull movement' do
          describe 'It should adjust for counter-clockwise hull movement' do
            before (:each) do
              @bot.desiredHeading = 100
              @bot.desiredGunTarget = nil
              @bot.desiredPosition = nil
            end
            it 'should not turn if it is at the desired heading' do
              @bot.desiredGunHeading = @bot.desiredHeading
              @bot.should_receive(:turn_gun).with(0)
              @bot.tick nil
            end
            it 'should turn counter-clockwise immediately to the desired heading if within range' do
              @bot.desiredGunHeading = @bot.desiredHeading-30
              @bot.should_receive(:turn_gun).with(-30)
              @bot.tick nil
            end
            it 'should turn clockwise immediately to the desired heading if within range' do
              @bot.desiredGunHeading = @bot.desiredHeading+30
              @bot.should_receive(:turn_gun).with(30)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredGunHeading = @bot.desiredHeading-31
              @bot.should_receive(:turn_gun).with(-30)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredGunHeading = @bot.desiredHeading+31
              @bot.should_receive(:turn_gun).with(30)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredGunHeading = @bot.desiredHeading+181
              @bot.should_receive(:turn_gun).with(-30)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredGunHeading = @bot.desiredHeading-181
              @bot.should_receive(:turn_gun).with(30)
              @bot.tick nil
            end
          end
          describe 'It should adjust for clockwise hull movement' do
            before (:each) do
              @bot.desiredHeading = 80
              @bot.desiredGunTarget = nil
              @bot.desiredRadarTarget = nil
              @bot.desiredPosition = nil
            end
            it 'should not turn if it is at the desired heading' do
              @bot.desiredGunHeading = @bot.desiredHeading
              @bot.should_receive(:turn_gun).with(0)
              @bot.tick nil
            end
            it 'should turn counter-clockwise immediately to the desired heading if within range' do
              @bot.desiredGunHeading = @bot.desiredHeading-30
              @bot.should_receive(:turn_gun).with(-30)
              @bot.tick nil
            end
            it 'should turn clockwise immediately to the desired heading if within range' do
              @bot.desiredGunHeading = @bot.desiredHeading+30
              @bot.should_receive(:turn_gun).with(30)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredGunHeading = @bot.desiredHeading-31
              @bot.should_receive(:turn_gun).with(-30)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredGunHeading = @bot.desiredHeading+31
              @bot.should_receive(:turn_gun).with(30)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredGunHeading = @bot.desiredHeading+181
              @bot.should_receive(:turn_gun).with(-30)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredGunHeading = @bot.desiredHeading-181
              @bot.should_receive(:turn_gun).with(30)
              @bot.tick nil
            end
          end
        end
      end
      describe 'It should turn its radar toward a desired heading' do
        describe 'It should turn just like the hull if the hull and gun are not turning' do
          before (:each) do
            @bot.desiredHeading = 90
            @bot.desiredGunHeading = @bot.desiredHeading
            @bot.desiredGunTarget = nil
            @bot.desiredRadarTarget = nil
            @bot.desiredPosition = nil
          end
          it 'should not turn if it is at the desired heading' do
            @bot.desiredRadarHeading = @bot.desiredHeading
            @bot.should_receive(:turn_radar).with(0)
            @bot.tick nil
          end
          it 'should turn counter-clockwise immediately to the desired heading if within range' do
            @bot.desiredRadarHeading = @bot.desiredHeading-60
            @bot.should_receive(:turn_radar).with(-60)
            @bot.tick nil
          end
          it 'should turn clockwise immediately to the desired heading if within range' do
            @bot.desiredRadarHeading = @bot.desiredHeading+60
            @bot.should_receive(:turn_radar).with(60)
            @bot.tick nil
          end
          it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
            @bot.desiredRadarHeading = @bot.desiredHeading-61
            @bot.should_receive(:turn_radar).with(-60)
            @bot.tick nil
          end
          it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
            @bot.desiredRadarHeading = @bot.desiredHeading+61
            @bot.should_receive(:turn_radar).with(60)
            @bot.tick nil
          end
          it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
            @bot.desiredRadarHeading = @bot.desiredHeading+181
            @bot.should_receive(:turn_radar).with(-60)
            @bot.tick nil
          end
          it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
            @bot.desiredRadarHeading = @bot.desiredHeading-181
            @bot.should_receive(:turn_radar).with(60)
            @bot.tick nil
          end
        end
        describe 'It should adjust for any hull movement' do
          describe 'It should adjust for counter-clockwise hull movement' do
            before (:each) do
              @bot.desiredHeading = 100
              @bot.desiredGunHeading = @bot.desiredHeading
              @bot.desiredGunTarget = nil
              @bot.desiredRadarTarget = nil
              @bot.desiredPosition = nil
            end
            it 'should not turn if it is at the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredHeading
              @bot.should_receive(:turn_radar).with(0)
              @bot.tick nil
            end
            it 'should turn counter-clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredHeading-60
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredHeading+60
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredHeading-61
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredHeading+61
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredHeading+181
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredHeading-181
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
          end
          describe 'It should adjust for clockwise hull movement' do
            before (:each) do
              @bot.desiredHeading = 80
              @bot.desiredGunHeading = @bot.desiredHeading
              @bot.desiredGunTarget = nil
              @bot.desiredRadarTarget = nil
              @bot.desiredPosition = nil
            end
            it 'should not turn if it is at the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredHeading
              @bot.should_receive(:turn_radar).with(0)
              @bot.tick nil
            end
            it 'should turn counter-clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredHeading-60
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredHeading+60
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredHeading-61
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredHeading+61
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredHeading+181
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredHeading-181
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
          end
        end
        describe 'It should adjust for any gun movement' do
          describe 'It should adjust for counter-clockwise gun movement' do
            before (:each) do
              @bot.desiredHeading = 90
              @bot.desiredGunHeading = @bot.desiredHeading + 30
            end
            it 'should not turn if it is at the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading
              @bot.should_receive(:turn_radar).with(0)
              @bot.tick nil
            end
            it 'should turn counter-clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading-60
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading+60
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading-61
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading+61
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading+181
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading-181
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
          end
          describe 'It should adjust for clockwise gun movement' do
            before (:each) do
              @bot.desiredHeading = 90
              @bot.desiredGunHeading = @bot.desiredHeading - 30
              @bot.desiredGunTarget = nil
              @bot.desiredRadarTarget = nil
              @bot.desiredPosition = nil
            end
            it 'should not turn if it is at the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading
              @bot.should_receive(:turn_radar).with(0)
              @bot.tick nil
            end
            it 'should turn counter-clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading-60
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise immediately to the desired heading if within range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading+60
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading-61
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount toward the desired heading if outside of range' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading+61
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
            it 'should turn clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading+181
              @bot.should_receive(:turn_radar).with(-60)
              @bot.tick nil
            end
            it 'should turn counter-clockwise the maximum amount if that is the shortest angular distance from the desired heading' do
              @bot.desiredRadarHeading = @bot.desiredGunHeading-181
              @bot.should_receive(:turn_radar).with(60)
              @bot.tick nil
            end
          end
        end
      end
    end
    describe 'towards targets' do
      describe 'It should aim its hull toward a desired position' do
        it 'should be able to aim east' do
          @bot.desiredPosition = Vector[1600,800]
          @bot.tick nil
          @bot.desiredHeading.should == 0
        end
        it 'should be able to aim northeast' do
          @bot.desiredPosition = Vector[1600,0]
          @bot.tick nil
          @bot.desiredHeading.should == 45
        end
        it 'should be able to aim north' do
          @bot.desiredPosition = Vector[800,0]
          @bot.tick nil
          @bot.desiredHeading.should == 90
        end
        it 'should be able to aim northwest' do
          @bot.desiredPosition = Vector[0,0]
          @bot.tick nil
          @bot.desiredHeading.should == 135
        end
        it 'should be able to aim west' do
          @bot.desiredPosition = Vector[0,800]
          @bot.tick nil
          @bot.desiredHeading.should == 180
        end
        it 'should be able to aim southwest' do
          @bot.desiredPosition = Vector[0,1600]
          @bot.tick nil
          @bot.desiredHeading.should == 225
        end
        it 'should be able to aim south' do
          @bot.desiredPosition = Vector[800,1600]
          @bot.tick nil
          @bot.desiredHeading.should == 270
        end
        it 'should be able to aim southeast' do
          @bot.desiredPosition = Vector[1600,1600]
          @bot.tick nil
          @bot.desiredHeading.should == 315
        end
      end
      describe 'It should aim its gun toward desired targets' do
        it 'should be able to aim east' do
          @bot.desiredGunTarget = Vector[1600,800]
          @bot.tick nil
          @bot.desiredGunHeading.should == 0
        end
        it 'should be able to aim northeast' do
          @bot.desiredGunTarget = Vector[1600,0]
          @bot.tick nil
          @bot.desiredGunHeading.should == 45
        end
        it 'should be able to aim north' do
          @bot.desiredGunTarget = Vector[800,0]
          @bot.tick nil
          @bot.desiredGunHeading.should == 90
        end
        it 'should be able to aim northwest' do
          @bot.desiredGunTarget = Vector[0,0]
          @bot.tick nil
          @bot.desiredGunHeading.should == 135
        end
        it 'should be able to aim west' do
          @bot.desiredGunTarget = Vector[0,800]
          @bot.tick nil
          @bot.desiredGunHeading.should == 180
        end
        it 'should be able to aim southwest' do
          @bot.desiredGunTarget = Vector[0,1600]
          @bot.tick nil
          @bot.desiredGunHeading.should == 225
        end
        it 'should be able to aim south' do
          @bot.desiredGunTarget = Vector[800,1600]
          @bot.tick nil
          @bot.desiredGunHeading.should == 270
        end
        it 'should be able to aim southeast' do
          @bot.desiredGunTarget = Vector[1600,1600]
          @bot.tick nil
          @bot.desiredGunHeading.should == 315
        end
      end
      describe 'It should aim its radar toward desired targets' do
        it 'should be able to aim east' do
          @bot.desiredRadarTarget = Vector[1600,800]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 0
        end
        it 'should be able to aim northeast' do
          @bot.desiredRadarTarget = Vector[1600,0]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 45
        end
        it 'should be able to aim north' do
          @bot.desiredRadarTarget = Vector[800,0]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 90
        end
        it 'should be able to aim northwest' do
          @bot.desiredRadarTarget = Vector[0,0]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 135
        end
        it 'should be able to aim west' do
          @bot.desiredRadarTarget = Vector[0,800]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 180
        end
        it 'should be able to aim southwest' do
          @bot.desiredRadarTarget = Vector[0,1600]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 225
        end
        it 'should be able to aim south' do
          @bot.desiredRadarTarget = Vector[800,1600]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 270
        end
        it 'should be able to aim southeast' do
          @bot.desiredRadarTarget = Vector[1600,1600]
          @bot.tick nil
          @bot.desiredRadarHeading.should == 315
        end
      end
    end
  end
  describe 'It should move' do
    before(:each) do
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

      @bot.desiredMaximumSpeed = 8
    end
    describe 'at a desired speed' do
      before(:each) do
        @bot.desiredPosition = nil
      end
      it 'should not accelerate if already at desired speed' do
        @bot.stub!(:speed).and_return(0)
        @bot.desiredSpeed = 0
        @bot.should_receive(:accelerate).with(0)
        @bot.tick nil
      end
      it 'should accelerate if moving slower than desired speed' do
        @bot.stub!(:speed).and_return(0)
        @bot.desiredSpeed = 8
        @bot.should_receive(:accelerate).with(1)
        @bot.tick nil
      end
      it 'should decelerate if moving faster than desired speed' do
        @bot.stub!(:speed).and_return(0)
        @bot.desiredSpeed = -8
        @bot.should_receive(:accelerate).with(-1)
        @bot.tick nil
      end
    end
    describe "to a desired position" do
      it 'should not move if at the desired position' do
        @bot.desiredPosition = Vector[800,800]
        @bot.should_receive(:accelerate).with(0)
        @bot.tick nil
        @bot.desiredSpeed.should == 0
      end
      it 'should accelerate to 1 if 1 <= distance < 4' do
        @bot.desiredPosition = Vector[803,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 1
      end
      it 'should accelerate to 2 if 4 <= distance < 9' do
        @bot.desiredPosition = Vector[808,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 2
      end
      it 'should accelerate to 3 if 9 <= distance < 16' do
        @bot.desiredPosition = Vector[815,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 3
      end
      it 'should accelerate to 4 if 16 <= distance < 25' do
        @bot.desiredPosition = Vector[824,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 4
      end
      it 'should accelerate to 5 if 25 < distance < 36' do
        @bot.desiredPosition = Vector[835,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 5
      end
      it 'should accelerate to 6 if 36 < distance < 49' do
        @bot.desiredPosition = Vector[848,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 6
      end
      it 'should accelerate to 7 if 49 < distance < 64' do
        @bot.desiredPosition = Vector[863,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 7
      end
      it 'should accelerate to >= if 64' do
        @bot.desiredPosition = Vector[864,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 8
      end
      it 'should clamp at 8' do
        @bot.desiredPosition = Vector[1600,800]
        @bot.tick nil
        @bot.desiredSpeed.should == 8
      end
      it 'should clamp at desired maximum speed' do
        @bot.desiredMaximumSpeed = 4
        @bot.desiredPosition = Vector[1600,800]
        @bot.tick nil
        @bot.desiredSpeed.should == @bot.desiredMaximumSpeed
      end
    end
  end
end

