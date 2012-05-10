require 'spec_helper'

describe Thing do
  it { should belong_to :friend_upload }
  it { should belong_to :pet_upload }
end
