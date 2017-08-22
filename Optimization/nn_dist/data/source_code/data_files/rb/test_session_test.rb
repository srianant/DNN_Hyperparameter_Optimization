require "abstract_unit"
require "stringio"

class ActionController::TestSessionTest < ActiveSupport::TestCase
  def test_initialize_with_values
    session = ActionController::TestSession.new(one: "one", two: "two")
    assert_equal("one", session[:one])
    assert_equal("two", session[:two])
  end

  def test_setting_session_item_sets_item
    session = ActionController::TestSession.new
    session[:key] = "value"
    assert_equal("value", session[:key])
  end

  def test_calling_delete_removes_item_and_returns_its_value
    session = ActionController::TestSession.new
    session[:key] = "value"
    assert_equal("value", session[:key])
    assert_equal("value", session.delete(:key))
    assert_nil(session[:key])
  end

  def test_calling_update_with_params_passes_to_attributes
    session = ActionController::TestSession.new
    session.update("key" => "value")
    assert_equal("value", session[:key])
  end

  def test_clear_empties_session
    session = ActionController::TestSession.new(one: "one", two: "two")
    session.clear
    assert_nil(session[:one])
    assert_nil(session[:two])
  end

  def test_keys_and_values
    session = ActionController::TestSession.new(one: "1", two: "2")
    assert_equal %w(one two), session.keys
    assert_equal %w(1 2), session.values
  end

  def test_fetch_returns_default
    session = ActionController::TestSession.new(one: "1")
    assert_equal("2", session.fetch(:two, "2"))
  end

  def test_fetch_on_symbol_returns_value
    session = ActionController::TestSession.new(one: "1")
    assert_equal("1", session.fetch(:one))
  end

  def test_fetch_on_string_returns_value
    session = ActionController::TestSession.new(one: "1")
    assert_equal("1", session.fetch("one"))
  end

  def test_fetch_returns_block_value
    session = ActionController::TestSession.new(one: "1")
    assert_equal(2, session.fetch("2") { |key| key.to_i })
  end
end
