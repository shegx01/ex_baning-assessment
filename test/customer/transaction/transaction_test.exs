defmodule ExBanking.Customer.TransactionTest do
  use ExUnit.Case, async: true
  alias ExBanking.Customer.{Transaction}

  setup do
    valid_deposit_withdraw_tx = Transaction.new(:deposit, "James", 20, "USD")
    withdraw_tx = Transaction.new(:deposit, "James", Transaction.input_to_money(20), "USD")
    valid_balance_tx = %Transaction{} = Transaction.new(:balance, "James", "USD")
    valid_send_tx = %Transaction{} = Transaction.new(:send, "James", "John", 20, "USD")

    %{
      deposit_withdraw: valid_deposit_withdraw_tx,
      withdraw: withdraw_tx,
      balance: valid_balance_tx,
      send: valid_send_tx
    }
  end

  describe "new/1" do
    test "success: type: :deposit" do
      assert %Transaction{} = Transaction.new(:deposit, "James", 20, "USD")
      assert %Transaction{} = Transaction.new(:deposit, "James", 20.0, "GBP")
      assert {:error, :wrong_arguments} = Transaction.new(:deposit, "James", 20, "")
      assert {:error, :wrong_arguments} = Transaction.new(:deposit, "James", 20, nil)
      assert {:error, :wrong_arguments} = Transaction.new(:deposit, "James", "20", "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:deposit, "James", nil, "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:deposit, "James", false, "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:deposit, nil, false, "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:deposit, "", false, "USD")
    end

    test "success: type: :withdraw" do
      assert %Transaction{} = Transaction.new(:withdraw, "James", 20, "USD")
      assert %Transaction{} = Transaction.new(:withdraw, "James", 20.0, "GBP")
      assert {:error, :wrong_arguments} = Transaction.new(:withdraw, "James", 20, "")
      assert {:error, :wrong_arguments} = Transaction.new(:withdraw, "James", 20, nil)
      assert {:error, :wrong_arguments} = Transaction.new(:withdraw, "James", "20", "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:withdraw, "James", nil, "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:withdraw, "James", false, "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:withdraw, nil, false, "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:withdraw, "", false, "USD")
    end

    test "success: type: :balance" do
      assert %Transaction{} = Transaction.new(:balance, "James", "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:balance, "James", "")
      assert {:error, :wrong_arguments} = Transaction.new(:balance, "", "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:balance, "", nil)
      assert {:error, :wrong_arguments} = Transaction.new(:balance, nil, "USD")
      assert {:error, :wrong_arguments} = Transaction.new(:balance, "James", nil, "USD")
    end

    test "success: type: :send" do
      assert %Transaction{} = Transaction.new(:send, "James", "John", 20, "USD")
      assert %Transaction{} = Transaction.new(:send, "James", 20.0, "GBP")
      assert {:error, :wrong_arguments} = Transaction.new(:send, "James", "James", 20, "")
      assert {:error, :wrong_arguments} = Transaction.new(:send, "James", "John", 20, nil)
      assert {:error, :wrong_arguments} = Transaction.new(:send, "James", "", 20, nil)
      assert {:error, :wrong_arguments} = Transaction.new(:send, "", "John", "20", "USD")
    end
  end

  describe "deposit/1" do
    test "success: deposit returns successfully", %{deposit_withdraw: send_struct} do
      assert {:ok, send_struct.amount} == Transaction.deposit(send_struct)
    end
  end

  describe "format_fund/1" do
    test "success: format fuund returns formatted float" do
      assert {:ok, 0.2} = Transaction.format_fund_response({:ok, Money.new(20)})

      assert {:ok, 20.0} =
               Transaction.format_fund_response({:ok, Transaction.input_to_money(20.0)})
    end
  end
end
