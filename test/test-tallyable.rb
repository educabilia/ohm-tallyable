require 'test/unit'
require 'ohm/tallyable'

class Event < Ohm::Model
  include Ohm::Callbacks
  include Ohm::Tallyable

  attribute :location
  tally :location
end

class TallyableTest < Test::Unit::TestCase
  def setup
    Ohm.flush
    Event.create(location: "Buenos Aires")
  end

  def test_leaderboard
    Event.create(location: "Buenos Aires")
    Event.create(location: "Rosario")
    l = Event.leaderboard(:location)
    assert_equal [["Buenos Aires", 2], ["Rosario", 1]], l
  end

  def test_update
    Event[1].update(location: "Corrientes")
    l = Event.leaderboard(:location)
    assert_equal [["Corrientes", 1]], l
  end

  def test_nil
    Event[1].update(location: nil)
    l = Event.leaderboard(:location)
    assert_equal [], l
  end

  def test_create_nil
    Event.create(location: nil)
    l = Event.leaderboard(:location)
    assert_equal [["Buenos Aires", 1]], l
  end

  def test_delete
    Event[1].delete
    l = Event.leaderboard(:location)
    assert_equal [], l
  end

  def test_retally
    Event.create(location: "Buenos Aires")
    Event.create(location: "Rosario")
    Event.retally(:location)

    l = Event.leaderboard(:location)
    assert_equal [["Buenos Aires", 2], ["Rosario", 1]], l
  end
end

class Post < Ohm::Model
  include Ohm::Callbacks
  include Ohm::Tallyable

  attribute :category
  attribute :site
  tally :category, by: :site
end

class TallyableByTest < Test::Unit::TestCase
  def setup
    Ohm.flush
    Post.create(category: "Personal", site: "ar")
    Post.create(category: "Personal", site: "ar")
    Post.create(category: "Work", site: "ar")
  end

  def test_leaderboard
    Post.create(category: "Personal", site: "uy")
    uy = Post.leaderboard(:category, site: "uy")
    ar = Post.leaderboard(:category, site: "ar")
    assert_equal [["Personal", 1]], uy
    assert_equal [["Personal", 2], ["Work", 1]], ar
  end

  def test_update
    Post[1].update(category: "Work", site: "uy")
    uy = Post.leaderboard(:category, site: "uy")
    ar = Post.leaderboard(:category, site: "ar")
    assert_equal [["Work", 1]], uy
    assert_equal [["Personal", 1], ["Work", 1]], ar
  end

  def test_delete
    Post[1].delete
    l = Post.leaderboard(:category, site: "ar")
    assert_equal [["Personal", 1], ["Work", 1]], l
  end

  def test_leaderboard_invalid
    assert_raise(ArgumentError) do
      Post.leaderboard(:foo, site: "ar")
    end
    assert_raise(ArgumentError) do
      Post.leaderboard(:category)
    end
    assert_raise(ArgumentError) do
      Post.leaderboard(:category, foo: "bar")
    end
  end

  def test_retally
    Post.retally(:category)
    l = Post.leaderboard(:category, site: "ar")
    assert_equal [["Personal", 2], ["Work", 1]], l
  end

  def post_retally_all
    Post.retally(:category)
    l = Post.leaderboard(:category, site: "ar")
    assert_equal [["Personal", 2], ["Work", 1]], l
  end
end
