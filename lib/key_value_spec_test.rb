gem 'minitest'

require 'redis'
require 'minitest/autorun'
require './moo_redis/extensions/string'
require './moo_redis/database'
require './moo_redis/transformations'
require './moo_redis/key_value'

class Mule < MooRedis::KeyValue
end

MooRedis::Database.create

describe Mule do
  before do
    @mule = Mule.new
  end

  after do
    @mule = nil
  end

  it "should find the object in the database and create initialize" do
    @mule.id = "25"
    @mule.update_data("30")
    @mule.save

    loaded_mule = Mule.find("25")
    assert_equal @mule, loaded_mule
    @mule.destroy
  end

  it "should set the value correctly through update_data" do
    @mule.update_data("30")
    assert_equal "30", @mule.value
  end

  it "should return nil when no object with that id is found" do
    assert_nil Mule.find("30")
  end

  it "should initialize with empty string" do
    assert_equal "", @mule.value
  end

  it "should implement empty? on the internal string" do
    assert @mule.empty?
    @mule.value = 'foo'
    refute @mule.empty?
  end

  it "should implement eql? and == and compare internal strings" do
    value = 'foo'
    @mule.value = value
    assert @mule == Mule.new(false, nil, value)
    assert @mule.eql?(Mule.new(false, nil, value))
    assert_equal value, @mule.value
  end

  it "should implement inspect and to_s" do
    value = 'foo'
    @mule.value = value
    assert_equal "Mule: #{value.inspect}", @mule.inspect
    assert_equal "Mule:", @mule.to_s
  end

  it "should set autosave initially through constructor" do
    u = Mule.new(true, 'foo', 'bar')
    assert u.autosave?
    u = Mule.new(false, 'foo', 'bar')
    refute u.autosave?
    assert u.destroy
  end

  it "should update autosave" do
    @mule.autosave = true
    assert @mule.autosave?
    @mule.autosave = false
    refute @mule.autosave?
  end

  describe "with set fields" do
    before do
      @mule.id = 'klaus'
      @mule.update_data('cool')
      if MooRedis::Database.db.exists("mule:klaus")
        MooRedis::Database.db.del("mule:klaus")
      end
    end

    after do
      @mule.id = ''
      @mule.update_data(nil)
      if MooRedis::Database.db.exists("mule:klaus")
        MooRedis::Database.db.del("mule:klaus")
      end
    end

    it "should save to database" do
      @mule.save
      saved_data = MooRedis::Transformations.transform("mule:klaus")
      assert_equal @mule.value, saved_data
    end

    it "should reload from the database" do
      @mule.save
      data = @mule.value
      @mule.update_data('franz')
      refute_equal data, @mule.value
      @mule.load
      assert_equal data, @mule.value
    end

    it "should destroy the database entry" do
      @mule.save
      @mule.destroy
      assert_nil Mule.find(@mule.id)
    end
  end
end
