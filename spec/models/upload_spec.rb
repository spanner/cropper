require 'spec_helper'

describe Upload do
  it { should have_attached_file(:file) }
  its(:precrop_processors) { should == [:thumbnail] }
  its(:precrop_styles) { 
    should == {
      :icon => { :geometry => "40x40#" },
      :precrop => { :geometry => "1600x1600>" }
    }
  }

end
