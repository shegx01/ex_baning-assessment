defmodule ExBanking.Customer.DataStore do
  @moduledoc """
    Database for Customers in the system
    based on ets Cachex based on :ets table
    This module can replaceable as long as the functions here
    are implemented by the replacer and also
    returns valid return type
  """
  alias ExBanking.Customer.Transaction

  @module __MODULE__

  @doc """

  Destructive insert
  used for creating account
  do not use on update!!
  Money will disappear

  """
  @spec insert_customer_balance(customer :: ExBanking.Customer.Transaction.t()) ::
          {:ok, boolean()}
  def insert_customer_balance(%Transaction{user: name, currency: currency, amount: amount}) do
    Cachex.put(@module, {name, currency}, amount)
  end

  @doc """
    performs an update transaction on the store
    returns the updated amount to the caller
  """
  @spec update_customer_balance(transaction :: ExBanking.Customer.Transaction.t()) ::
          {:ok, integer}
  def update_customer_balance(%Transaction{user: name, currency: currency, amount: amount}) do
    key = {name, currency}

    Cachex.transaction!(@module, [key], fn worker ->
      case Cachex.exists?(worker, key) do
        {:ok, true} ->
          {:ok, value} = Cachex.get(worker, key)
          add_to_money(worker, key, value, amount)
          {:ok, Money.add(value, amount)}

        {:ok, false} ->
          Cachex.put(worker, key, amount)
          {:ok, amount}
      end
    end)
  end

  @doc """
    return the amount available in the syastem or create
    one on the fly if no fund is available
  """
  @spec get_account_balance(acount_name :: {String.t(), String.t()}) ::
          {:ok, Money.t()}
  def get_account_balance(account_name) do
    case Cachex.get(@module, account_name) do
      {:ok, nil} -> {:ok, Money.new(0)}
      {:ok, balance} -> {:ok, balance}
    end
  end

  @doc """
    check if the account exists
    not used in the system
  """
  @spec account_exists?(account_name :: String.t()) :: boolean()
  def account_exists?(account_name) do
    {:ok, value} = Cachex.exists?(@module, account_name)
    value
  end


  defp add_to_money(worker, key, value, amount) do
    Cachex.put(worker, key, Money.add(value, amount))
    {:ok, Money.add(value, amount)}
  end
end
