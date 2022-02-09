defmodule ExBankingTest do
  use ExUnit.Case
  alias ExBanking

  describe "create_user/1" do
    test "success: create_user return right response" do
      assert :ok = ExBanking.create_user("user")
      assert {:error, :user_already_exists} = ExBanking.create_user("user")
      assert {:error, :wrong_arguments} = ExBanking.create_user("")
    end
  end

  describe "deposit/1" do
    test "success: deposit" do
      user = "John Doe"
      assert :ok == user |> ExBanking.create_user()
      assert {:ok, 20.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 40.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 60.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 20.0} == user |> ExBanking.deposit(20, "NGN")
      assert {:ok, 80.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 80.0} == user |> ExBanking.deposit(80, "GBP")
      assert {:ok, 100.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 120.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 120.0} == user |> ExBanking.deposit(120, "BTC")
      assert {:ok, 140.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 160.0} == user |> ExBanking.deposit(20, "USD")
      assert {:error, :user_does_not_exist} = "frank" |> ExBanking.deposit(20, "USD")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit(nil, "USD")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit(20.0, "")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit('"', "")
    end
  end

  describe "withdraw/1" do
    test "success: withdraw fund from system" do
      user = "James Brandt"
      assert :ok == user |> ExBanking.create_user()
      assert {:ok, 20.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 40.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 60.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 80.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 100.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 120.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 140.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 160.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 140.0} == user |> ExBanking.withdraw(20, "USD")
      assert {:ok, 120.0} == user |> ExBanking.withdraw(20, "USD")
      assert {:ok, 100.0} == user |> ExBanking.withdraw(20, "USD")
      assert {:error, :user_does_not_exist} = "no existing user" |> ExBanking.withdraw(20, "USD")
      assert {:error, :not_enough_money} == user |> ExBanking.withdraw(200, "USD")
      assert {:error, :not_enough_money} == user |> ExBanking.withdraw(101, "USD")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit(nil, "USD")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit(20.0, "")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit('"', "")
    end
  end

  describe "balance/1" do
    test "success: balance of the user rerturns right result" do
      user = "Johnny Depp"
      assert :ok == user |> ExBanking.create_user()
      assert {:ok, 20.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 40.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 60.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 80.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 100.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 120.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 10.0} == user |> ExBanking.deposit(10, "XFR")
      assert {:ok, 140.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 120.0} == user |> ExBanking.deposit(120, "XMR")
      assert {:ok, 160.0} == user |> ExBanking.deposit(20, "USD")
      assert {:ok, 160.0} = user |> ExBanking.balance("USD")
      assert {:ok, 120.0} = user |> ExBanking.balance("XMR")
      assert {:ok, 10.0} = user |> ExBanking.balance("XFR")
      assert {:error, :user_does_not_exist} = "fred" |> ExBanking.balance("USD")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit(nil, "USD")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit(20.0, "")
      assert {:error, :wrong_arguments} == user |> ExBanking.deposit('"', "")
    end
  end

  describe "send/1" do
    test "success: send  accurately returns its result" do
      user1 = "Johnny Cage"
      user2 = "Brian James"

      assert {:error, :sender_does_not_exist} == user1 |> ExBanking.send(user2, 200, "USD")
      assert :ok == user1 |> ExBanking.create_user()
      assert {:ok, 200.0} == user1 |> ExBanking.deposit(200, "USD")
      assert {:error, :receiver_does_not_exist} == user1 |> ExBanking.send(user2, 200, "USD")
      assert {:error, :wrong_arguments} == user2 |> ExBanking.send(user2, 200, "USD")
      assert {:error, :user_does_not_exist} == user2 |> ExBanking.deposit(200, "USD")
      assert :ok == user2 |> ExBanking.create_user()
      assert {:ok, 200.0} == user2 |> ExBanking.deposit(200, "USD")
      assert {:ok, 0.0, 400.0} == user1 |> ExBanking.send(user2, 200, "USD")
      assert {:error, :user_does_not_exist} = "Jack" |> ExBanking.balance("USD")
      assert {:error, :wrong_arguments} == user1 |> ExBanking.send(nil, 40, "CAD")
      assert {:error, :wrong_arguments} == nil |> ExBanking.send(user2, 40, "CAD")
      assert {:error, :wrong_arguments} == user1 |> ExBanking.send(user2, nil, "CAD")
      assert {:error, :wrong_arguments} == user1 |> ExBanking.send(user2, 21, nil)
    end
  end
end
