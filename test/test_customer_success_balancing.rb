# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/focus'
require 'timeout'
require 'pry'

# CustomerSuccess Balancing
class CustomerSuccessBalancing
  attr :customer_success, :customers, :customer_success_away, :matrix

  def initialize(customer_success, customers, customer_success_away)
    @customer_success = customer_success
    @customers = customers
    @customer_success_away = customer_success_away
  end

  def execute
    # Removes customers success away
    remove_csa if customer_success_away.any?

    # Organize params to facilitate the logics
    sort_params

    # class with the principal logic, commented bellow
    distribute_customers

    # Return 0 if there is a draw between the customer success's with most customers
    return 0 if draw?

    # If none of the CSs has at least one customer, return 0
    # Else return the id of the customer success with most customers
    css_with_most_customers.nil? ? 0 : css_with_most_customers[:id]
  end

  def sort_params
    @customer_success = customer_success.sort_by { |cs| cs[:score] }
    @customers = customers.sort_by { |c| c[:score] }
  end

  def remove_csa
    customer_success.reject! { |cs| customer_success_away.include? cs[:id] }
  end

  def remove_already_taken_customer(customers, already_taken_customer)
    customers.reject! { |c| already_taken_customer.include? c[:id] }
  end

  def distribute_customers # rubocop:todo Metrics/AbcSize
    @matrix = []

    # Iterate over the CSs to distribute customers
    customer_success.each_with_index do |cs, index|
      matrix << { id: cs[:id], customer: [] }

      # Iterate over the customers to check if he should go to current CSs
      customers.each do |c|
        matrix[index][:customer] << c[:id] if c[:score] <= cs[:score]
      end

      # Removes customer that already been taken by the current CSs
      remove_already_taken_customer(customers, matrix[index][:customer]) if matrix[index][:customer].any?
    end
  end

  def draw?
    matrix.sort_by! { |m| m[:customer].count }.reverse!

    return true if matrix[0][:customer].count == matrix[1][:customer].count

    false
  end

  # Retrive the CSs with the most customers
  def css_with_most_customers
    matrix.max_by { |m| m[:customer].count }
  end
end

# Class of tests
class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    css =       [{ id: 1, score: 60 }, { id: 2, score: 20 },
                 { id: 3, score: 95 }, { id: 4, score: 75 }]

    customers = [{ id: 1, score: 90 }, { id: 2, score: 20 },
                 { id: 3, score: 70 }, { id: 4, score: 40 },
                 { id: 5, score: 60 }, { id: 6, score: 10 }]

    balancer = CustomerSuccessBalancing.new(css, customers, [2, 4])
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    css = array_to_map([11, 21, 31, 3, 4, 5])
    customers = array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60])

    balancer = CustomerSuccessBalancing.new(css, customers, [])
    assert_equal 0, balancer.execute
  end

  focus def test_scenario_three
    customer_success = (1..999).to_a
    customers = Array.new(10_000, 998)

    balancer = CustomerSuccessBalancing.new(array_to_map(customer_success), array_to_map(customers), [999])

    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(array_to_map([1, 2, 3, 4, 5, 6]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 2, 3, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [1, 3, 2])
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [4, 5, 6])
    assert_equal 3, balancer.execute
  end

  def array_to_map(arr)
    out = []
    arr.each_with_index { |score, index| out.push({ id: index + 1, score: score }) }
    out
  end
end
