defmodule ExBanking do
  alias ExBanking.Customer
  alias ExBanking.Customer.StagesDynamicSupervisor

  @moduledoc """
    Api module that exposed the app functionality
  """

  @type deposit_withdraw_response ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}

  @doc """
    - Create new user and adhere to api return type if argument meet the requirement
    - Empty user string is rejected
  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(name) when is_bitstring(name) do
    StagesDynamicSupervisor.start_worker(name)
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | deposit_withdraw_response()
  def deposit(user, amount, currency) do
    Customer.Transaction.new(:deposit, user, amount, currency)
    |> Customer.Producer.create_transaction()
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | deposit_withdraw_response()
  def withdraw(user, amount, currency) do
    Customer.Transaction.new(:withdraw, user, amount, currency)
    |> Customer.Producer.create_transaction()
  end

  @spec balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | {:error, Atom.t()}
  def balance(user, currency) do
    Customer.Transaction.new(:balance, user, currency)
    |> Customer.Producer.create_transaction()
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: non_neg_integer(),
          currency :: String.t()
        ) ::
          {:error, :wrong_argument} | ExBanking.Customer.Transaction.t()
  def send(from_user, to_user, amount, currency) do
    Customer.Transaction.new(:send, from_user, to_user, amount, currency)
    |> Customer.Producer.create_transaction()
  end
end
