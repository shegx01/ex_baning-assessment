defmodule ExBanking.Customer.DataStore do
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
  @spec insert_customer_balance(customer :: ExBanking.Customer.Transaction.t()) :: {:ok, boolean()}
  def insert_customer_balance(%Transaction{user: name, currency: currency, amount: amount}) do
    Cachex.put(@module, {name, currency}, amount)
  end

  @spec update_customer_balance(transaction :: ExBanking.Customer.Transaction.t(),action_key:: atom()) ::
          {:ok, [integer] | integer}
  def update_customer_balance(%Transaction{user: name, currency: currency, amount: amount}, action_key) do
    key = {name, currency}

    Cachex.transaction!(@module, [key], fn worker ->
        case Cachex.exists?(worker, key) do
          {:ok, true} ->
           {:ok, value} =  Cachex.get(worker, key)
           perform_customer_update(worker, key, value,amount, action_key)
          {:ok, false} ->
            Cachex.put(worker, key, 0)
            {:ok, 0}
        end

    end)
  end


  def customer_intra_transfer(%Transaction{from: from_name,to: to_name, currency: currency, amount: amount}) do
    from_key = {from_name, currency}
    to_key = {to_name, currency}

    Cachex.transaction!(@module, [from_key, to_key], fn _worker ->
      from = %Transaction{user: from_name, currency: currency, amount: amount}
      to = %Transaction{user: to_name, currency: currency, amount: amount}

        {:ok, from_user} = update_customer_balance(from, :withdraw)

        {:ok, to_user} = update_customer_balance(to, :deposit)
        IO.inspect(from)
        IO.inspect(to)
        {from_user, to_user}
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

  defp perform_customer_update(worker, key, value,amount, :deposit) do

     Cachex.put(worker, key, value + amount)
     {:ok, value + amount}

  end
  defp perform_customer_update(worker, key, value,amount, :withdraw) do
     Cachex.put(worker, key, value - amount)
{:ok, value - amount}
  end
end
