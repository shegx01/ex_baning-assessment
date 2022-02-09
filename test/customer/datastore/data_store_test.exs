defmodule ExBanking.Customer.DataStoreTest do
  use ExUnit.Case, async: true
  alias ExBanking.Customer.{DataStore, Transaction}

  setup do
    on_exit(fn ->
      Cachex.reset(DataStore)
    end)

    %{
      customer_one: %Transaction{
        amount: Transaction.input_to_money(20),
        user: "Jane Doe",
        currency: "GBP"
      },
      customer_two: %Transaction{
        amount: Transaction.input_to_money(20.1),
        currency: "GBP",
        user: "Jane"
      }
    }
  end

  describe "insert_customer_balance/1" do
    test "success: customer insertion pass", %{customer_one: customer_one} do
      assert match?({:ok, true}, DataStore.insert_customer_balance(customer_one))
    end
  end

  describe "update_customer_balance/1" do
    test "success: customer_balance is updated", %{customer_one: customer_one} do
      data =
        1..20
        |> Enum.map(&{:ok, Transaction.input_to_money(&1)})

      data
      |> Enum.each(fn {:ok, fund} ->
        assert {:ok, money} = DataStore.update_customer_balance(customer_one)
        assert fund < money
      end)
    end
  end

  describe "get_account_balance/1" do
    test "success: returns accurate account balance ", %{customer_two: customer_two} do
      DataStore.insert_customer_balance(customer_two)

      assert {:ok, amount} =
               DataStore.get_account_balance({customer_two.user, customer_two.currency})

      assert amount == customer_two.amount
    end
  end

  describe "success: account_exists/1" do
    test "check account_exists? returns ", %{customer_two: customer_two} do
      assert false == DataStore.account_exists?(customer_two)
      DataStore.insert_customer_balance(customer_two)
      assert true == DataStore.account_exists?({customer_two.user, customer_two.currency})
    end
  end
end
