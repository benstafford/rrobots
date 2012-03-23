describe 'SimpleGunner' do
  before(:each) do
    @gunner = SimpleGunner.new
  end

  it 'should give a turn_amount' do
    @gunner.turn_amount.should_not == nil
  end
end