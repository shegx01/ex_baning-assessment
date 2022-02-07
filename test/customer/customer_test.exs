defmodule ExBanking.CustomerTest do
  use ExUnit.Case, async: true
  alias ExBanking.Customer

  setup do
    customer_one = "John Doe"
    customer_two = "James Doe"

    %{customer_one: customer_one, customer_two: customer_two}
  end

  describe "create/1" do
    test "customer return :ok atom on success", %{customer_one: customer_one} do
      assert :ok = Customer.create(customer_one)
    end

    test "customer existence ", %{customer_two: customer_two} do
      assert :ok = Customer.create(customer_two)
      assert :user_already_exists = Customer.create(customer_two)
    end

    test "failed on wrong input with desired error", %{customer_one: customer_one} do
      assert {:error, :wrong_arguments} = Customer.create(String.to_atom(customer_one))
    end
  end
end
