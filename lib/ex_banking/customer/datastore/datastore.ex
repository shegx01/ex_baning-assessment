defmodule ExBanking.Customer.DataStore do
  require Logger

  @moduledoc """
    Database for Customers in the system
    based on ets table
    The supervisor is started by `ExBanking.Customer.DataStore.Supervisor`
  """
  alias ExBanking.Customer.Transaction

  @module __MODULE__

  @doc """
  only used after account existence has been validated
  """
  @spec insert_customer_balance(customer :: ExBanking.Customer.Transaction.t()) ::
          {:ok, boolean()}
  def insert_customer_balance(%Transaction{user: name, currency: currency, amount: amount}) do
    Cachex.put(@module, {name, currency}, amount)
  end

  @spec update_customer_balance(transaction :: ExBanking.Customer.Transaction.t()) ::
          {:ok, integer}
  def update_customer_balance(%Transaction{user: name, currency: currency, amount: amount}) do
    key = {name, currency}

    Cachex.transaction!(@module, [key], fn worker ->
      case Cachex.exists?(worker, key) do
        {:ok, true} ->
          {:ok, value} = Cachex.get(worker, key)
          add_to_money(worker, key, value, amount)
          {:ok, value + amount}

        {:ok, false} ->
          Cachex.put(worker, key, amount)
          {:ok, amount}
      end
    end)
  end

  @spec delete_customer_balance(account_name :: String.t()) :: {:ok, boolean()}
  def delete_customer_balance(account_name) do
    Cachex.del(@module, account_name)
  end

  @spec get_account_balance(acount_name :: String.t()) ::
          {:ok, neg_integer()} | {:error, :customer_not_found}
  def get_account_balance(account_name) do
    Cachex.get(@module, account_name)
  end

  @spec account_exists?(account_name :: String.t()) :: boolean()
  def account_exists?(account_name) do
    {:ok, value} = Cachex.exists?(@module, account_name)
    value
  end

  defp add_to_money(worker, key, value, amount) do
    Cachex.put(worker, key, value + amount)
    {:ok, value + amount}
  end
end
