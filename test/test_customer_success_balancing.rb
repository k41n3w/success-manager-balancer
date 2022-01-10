# frozen_string_literal: true

require 'minitest/autorun'
require 'timeout'

# CustomerSuccess Balancing
class CustomerSuccessBalancing
  attr :customer_success, :customers, :customer_success_away, :matrix

  def initialize(customer_success, customers, customer_success_away)
    @customer_success = customer_success
    @customers = customers
    @customer_success_away = customer_success_away
  end

  def execute
    # Remove os CSs que estão indisponíveis
    remove_csa if customer_success_away.any?

    # Ordena os parametros para facilitar a lógica
    sort_params

    # Método com a lógica principal, comentada mais abaixo
    distribute_customers

    # Retorna 0 caso exista um empate entre os CSs com mais clientes
    return 0 if draw?

    # Se nenhum dos CSs tiver ao menos um cliente, retorna 0
    # Senão, retorna o id do CSs com mais clientes
    css_with_most_customers.nil? ? 0 : css_with_most_customers[:id]
  end

  def remove_csa
    customer_success.reject! { |cs| customer_success_away.include? cs[:id] }
  end

  def sort_params
    @customer_success = customer_success.sort_by { |cs| cs[:score] }
    @customers = customers.sort_by { |c| c[:score] }
  end

  def distribute_customers # rubocop:todo Metrics/AbcSize
    @matrix = []

    # Itera sobre os CSs para distribuir os clientes
    customer_success.each_with_index do |cs, index|
      matrix << { id: cs[:id], customer: [] }

      # Itera sobre os clientes para saber se deve ser adiciona a lista do CS atual
      customers.each do |c|
        # Caso o score do cliente atual seja maior que o score do CS atual quebra o laço
        break if c[:score] > cs[:score]

        # Atribui o cliente atual ao CS atual caso o score do cliente seja menor que o score do CS
        matrix[index][:customer] << c[:id] if c[:score] <= cs[:score]
      end

      # Remove os clientes que já foram pegos pelo CS atual, caso existam
      remove_already_taken_customer(customers, matrix[index][:customer]) if matrix[index][:customer].any?
    end
  end

  def remove_already_taken_customer(customers, already_taken_customer)
    customers.reject! { |c| already_taken_customer.include? c[:id] }
  end

  def draw?
    # Organiza a lista de CSs por número de clientes de forma decrecente
    matrix.sort_by! { |m| m[:customer].count }.reverse!

    # Caso exista empate de número e clientes entre os dois primeiros CSs, retorna true
    return true if matrix[0][:customer].count == matrix[1][:customer].count

    # Se não, retorna false
    false
  end

  # Retorna o CS com mais clientes
  def css_with_most_customers
    matrix.max_by { |m| m[:customer].count }
  end
end

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

  def test_scenario_three
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
