require 'spec_helper'

describe Ripple::Document::Persistence do
  # require 'support/models/widget'

  before :each do
    @client = Ripple.client
    @bucket = Ripple.client.bucket("widgets")
    @widget = Widget.new(:size => 1000)
  end

  it "forces the content type to 'application/json'" do
    @widget.robject.content_type = 'application/not-json'

    @client.should_receive(:store_object) do |obj, *_|
      obj.content_type.should == 'application/json'
    end

    @widget.save
  end

  it "should save a new object to Riak" do
    json = @widget.attributes.merge("_type" => "Widget")
    @client.should_receive(:store_object) do |obj, _, _, _|
      obj.data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.save
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
  end

  it "should modify attributes and save a new object" do
    json = @widget.attributes.merge("_type" => "Widget", "size" => 5)
    @client.should_receive(:store_object) do |obj, _, _, _|
      obj.data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.update_attributes(:size => 5)
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
  end

  it "should modify a single attribute and save a new object" do
    json = @widget.attributes.merge("_type" => "Widget", "size" => 5)
    @client.should_receive(:store_object) do |obj, _, _, _|
      obj.data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.update_attribute(:size, 5)
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
    @widget.size.should == 5
  end

  it "should instantiate and save a new object to riak" do
    json = @widget.attributes.merge(:size => 10, :shipped_at => Time.utc(2000,"jan",1,20,15,1), :_type => 'Widget')
    @client.should_receive(:store_object) do |obj, _, _, _|
      obj.key.should be_nil
      obj.data.should == json
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget = Widget.create(:size => 10, :shipped_at => Time.utc(2000,"jan",1,20,15,1))
    @widget.size.should == 10
    @widget.shipped_at.should == Time.utc(2000,"jan",1,20,15,1)
    @widget.should_not be_a_new_record
  end

  it "should instantiate and save a new object to riak and allow its attributes to be set via a block" do
    json = @widget.attributes.merge(:size => 10, :_type => 'Widget')
    @client.should_receive(:store_object) do |obj, _, _, _|
      obj.data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget = Widget.create do |widget|
      widget.size = 10
    end
    @widget.size.should == 10
    @widget.should_not be_a_new_record
  end

  it "should save the attributes not having a corresponding property" do
    attrs = @widget.attributes.merge("_type" => "Widget", "unknown_property" => "a_value")
    @client.should_receive(:store_object) do |obj, _, _, _|
      obj.data.should == attrs
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget["unknown_property"] = "a_value"
    @widget.save
    @widget.key.should == "new_widget"
    @widget.should_not be_a_new_record
    @widget.changes.should be_blank
  end

  it "should allow unexpected exceptions to be raised" do
    robject = mock("robject", :key => @widget.key, "data=" => true, "content_type=" => true, "indexes=" => true)
    robject.should_receive(:store).and_raise(Riak::ProtobuffsFailedRequest.new(:not_found, "not found"))
    @widget.stub!(:robject).and_return(robject)
    lambda { @widget.save }.should raise_error(Riak::FailedRequest)
  end

  it "should reload a saved object, including associations" do
    json = @widget.attributes.merge(:_type => "Widget")
    @client.should_receive(:store_object) do |obj, _, _, _|
      obj.data.should == json
      obj.key.should be_nil
      # Simulate loading the response with the key
      obj.key = "new_widget"
    end
    @widget.save
    @client.should_receive(:reload_object) do |obj, _|
      obj.key.should == "new_widget"
      obj.content_type = 'application/json'
      obj.raw_data = '{"name":"spring","size":10,"shipped_at":"Sat, 01 Jan 2000 20:15:01 -0000","_type":"Widget"}'
      obj
    end

    @widget.widget_parts.should_receive(:reset)
    @widget.reload
    @widget.changes.should be_blank
    @widget.name.should == "spring"
    @widget.size.should == 10
    @widget.shipped_at.should == Time.utc(2000,"jan",1,20,15,1)
  end

  it "should destroy a saved object" do
    @client.should_receive(:store_object).and_return(true)
    @widget.key = "foo"
    @widget.save
    @widget.should_not be_new
    @client.should_receive(:delete_object).and_return(true)
    @widget.destroy.should be_true
    @widget.should be_frozen
    @widget.should be_deleted
  end

  it "should destroy all saved objects" do
    @widget.should_receive(:destroy).and_return(true)
    Widget.should_receive(:list).and_yield(@widget)
    Widget.destroy_all.should be_true
  end

  context 'when a delete fails' do
    let(:error) { Riak::FailedRequest.new("Riak could not delete your object") }
    before(:each) do
      @widget.stub(:new? => false)
      @widget.robject.should_receive(:delete).and_raise(error)
    end

    it 'causes destroy to return false' do
      @widget.destroy.should be_false
    end

    it 'causes destroy! to raise an error' do
      expect {
        @widget.destroy!
      }.to raise_error(Riak::FailedRequest)
    end
  end

  it "should freeze an unsaved object when destroying" do
    @client.should_not_receive(:delete_object)
    @widget.destroy.should be_true
    @widget.should be_frozen
  end

  it "should be able to call #errors after destroying" do
    @widget.destroy.should be_true
    @widget.should be_frozen
    expect { @widget.errors }.to_not raise_error
  end

  it "should be a root document" do
    @widget._root_document.should == @widget
  end

  describe "when storing a class using single-bucket inheritance" do
    before :each do
      @cog = Cog.new(:size => 1000)
    end

    it "should store the _type field as the class name" do
      json = @cog.attributes.merge("_type" => "Cog")
      @client.should_receive(:store_object) do |obj, _, _, _|
        obj.data.should == json
        obj.key = "new_widget"
      end
      @cog.save
      @cog.should_not be_new_record
    end
  end

  describe "modifying the default quorum values" do
    before :each do
      Widget.set_quorums :r => 1, :w => 1, :dw => 0, :rw => 1
      @bucket = mock("bucket", :name => "widgets")
      @robject = mock("object", :data => {"name" => "bar"}, :key => "gear")
      Widget.stub(:bucket).and_return(@bucket)
    end

    it "should use the supplied R value when reading" do
      @bucket.should_receive(:get).with("gear", :r => 1).and_return(@robject)
      Widget.find("gear")
    end

    it "should use the supplied W and DW values when storing" do
      Widget.new do |widget|
        widget.key = "gear"
        widget.send(:robject).should_receive(:store).with({:w => 1, :dw => 0})
        widget.save
      end
    end

    it "should use the supplied RW when deleting" do
      widget = Widget.new
      widget.key = "gear"
      widget.instance_variable_set(:@new, false)
      widget.send(:robject).should_receive(:delete).with({:rw => 1})
      widget.destroy
    end
  end

  shared_examples_for "saving a parent document with linked child documents" do
    before(:each) do
      @client.stub(:store_object)
    end

    it 'saves new children when the parent is saved' do
      children.each do |child|
        child.stub(:new? => true)
        child.should_receive(:save)
      end
      parent.save
    end

    it 'saves children that have changes when the parent is saved' do
      children.each do |child|
        child.stub(:new? => false)
        child.stub(:changed? => true)
        child.should_receive(:save)
      end
      parent.save
    end

    it 'does not save children that have no changes and are not new when the parent is saved' do
      children.each do |child|
        child.stub(:new? => false)
        child.stub(:changed? => false)
        child.should_not_receive(:save)
      end
      parent.save
    end
  end

  context "for a document with a many linked association" do
    before(:all) do
      # check assumptions of these examples
      Widget.associations[:widget_parts].should be_many
      Widget.associations[:widget_parts].should be_linked
    end

    it_behaves_like "saving a parent document with linked child documents" do
      let(:parent)   { Widget.new(:name => 'fizzbuzz') }
      let(:children) { %w[ fizz buzz ].map { |n| WidgetPart.new(:name => n) } }

      before(:each) do
        children.each { |c| parent.widget_parts << c }
      end
    end
  end

  describe "for a document with a one linked association" do
    before(:all) do
      # check assumptions of these examples
      Invoice.associations[:customer].should be_one
      Invoice.associations[:customer].should be_linked
    end

    it_behaves_like "saving a parent document with linked child documents" do
      let(:parent)   { Invoice.new }
      let(:children) { [Customer.new] }

      before(:each) do
        parent.customer = children.first
      end
    end
  end

  shared_examples_for "embedded association persistence logic" do
    before(:each) do
      @client.stub(:store_object)
    end

    it "does not save children when the parent is saved" do
      children.each do |child|
        child.stub(:new? => true, :changed? => true)
        child.should_not_receive(:save)
      end

      parent.save
    end
  end

  describe "for a document with a many embedded association" do
    before(:all) do
      # check assumptions of these examples
      Clock.associations[:modes].should be_many
      Clock.associations[:modes].should be_embedded
    end

    it_behaves_like "embedded association persistence logic" do
      let(:parent)   { Clock.new }
      let(:children) { [1, 2].map { |i| Mode.new } }

      before(:each) do
        children.each { |c| parent.modes << c }
      end
    end
  end

  describe "for a document with a one embedded association" do
    before(:all) do
      # check assumptions of these examples
      Parent.associations[:child].should be_one
      Parent.associations[:child].should be_embedded
    end

    it_behaves_like "embedded association persistence logic" do
      let(:parent)   { Parent.new }
      let(:children) { [Child.new(:name => 'Bobby', :age => 9)] }

      before(:each) do
        parent.child = children.first
      end
    end
  end
end
