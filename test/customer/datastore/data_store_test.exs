defmodule ExBanking.Customer.DataStoreTest do
  use ExUnit.Case, async: true
  alias ExBanking.Customer
  alias ExBanking.Customer.DataStore

  setup do
    %{
      customer_one: %ExBanking.Customer{
        funds: %{},
        id: "26019830-43c8-593b-ab64-783ffc1cf4e3",
        name: "Jane Doe"
      },
      customer_two: %ExBanking.Customer{
        funds: %{},
        id: "86019830-53c8-593b-ab64-083ffcycf4e3",
        name: "Jane"
      }
    }
  end

  describe "update_customer_balance/1" do
    test "customer insertion pass", %{customer_one: customer_one} do
      customer_response = DataStore.update_customer_balance(customer_one)
      assert customer_response == true
      assert is_boolean(customer_response)
    end
  end

  # this might not be neccessary nut since we interfaced the `:ets` table directly
  # we must test our act
  describe "delete_customer_balance/1" do
    test "customer deleted successful in ets table", %{customer_two: customer_two} do
      DataStore.update_customer_balance(customer_two)
      assert is_boolean(DataStore.delete_customer_balance(customer_two.name))
    end
  end

  describe "account_exists/1" do
    test "check account_exists? returns ", %{customer_two: customer_two} do
      assert false == DataStore.account_exists?(customer_two.name)
      Customer.create(customer_two.name)
      assert true == DataStore.account_exists?(customer_two.name)
    end
  end
end
