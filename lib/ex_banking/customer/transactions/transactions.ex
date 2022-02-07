defmodule ExBanking.Customer.Transaction do
  alias ExBanking.Customer.{DataStore}
  @type t :: %__MODULE__{}
  alias __MODULE__
  defstruct [:type, :user, :amount, :from, :to, currency: 0]

  @type deposit_withdraw_response ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}

  @type send_response ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}

  defguardp is_valid_deposit_withdraw(user, amount, currency)
            when is_bitstring(user) and is_number(amount) and amount >= 0 and
                   is_bitstring(currency)

  @spec new(
          type :: atom(),
          user :: bitstring(),
          amount :: non_neg_integer(),
          currency :: bitstring()
        ) :: t()
  def new(type, user, amount, currency) when is_valid_deposit_withdraw(user, amount, currency) do
    with updated_fund <- Money.convert_to_integer(amount),
         true <- validate_length(user),
         true <- validate_length(currency) do
      %Transaction{
        type: type,
        user: user,
        amount: updated_fund,
        currency: currency
      }
    end
  end

  def new(_, _, _, _), do: {:error, :wrong_arguments}

  @spec new(balance :: atom(), user :: binary(), currency :: binary) :: t()
  def new(:balance, user, currency)
      when is_bitstring(user) and is_bitstring(currency) do
    with true <- validate_length(user),
         true <- validate_length(currency) do
      %Transaction{
        user: user,
        currency: currency
      }
    end
  end

  def new(_, _, _), do: {:error, :wrong_arguments}

  @spec new(
          send :: atom(),
          from_user :: bitstring(),
          to_user :: bitstring(),
          amount :: non_neg_integer(),
          currency :: bitstring()
        ) :: t()
  def new(:send, from_user, to_user, amount, currency)
      when is_bitstring(from_user) and is_bitstring(to_user) and is_bitstring(currency) and
             amount > 0 do
    with true <- validate_length(from_user),
         true <- validate_length(to_user),
         true <- validate_length(currency),
         updated_fund <- Money.convert_to_integer(amount) do
      %Transaction{
        type: :send,
        to: to_user,
        from: from_user,
        currency: currency,
        amount: updated_fund
      }
    end
  end

  def new(_, _, _, _, _), do: {:error, :wrong_arguments}

  @spec deposit(transaction :: ExBanking.Customer.Transaction.t()) ::
          {:ok, integer} | deposit_withdraw_response()

  def deposit(%Transaction{} = transaction) do
    {:ok, balance} = DataStore.update_customer_balance(transaction, :deposit)
    {:ok, balance |> Money.convert_to_integer()}
  end

  def deposit({:error, _} = error), do: error

  @spec withdraw(transaction :: t()) :: deposit_withdraw_response()
  def withdraw(%Transaction{user: user, amount: amount, currency: currency} = transaction) do
    case DataStore.get_account_balance({user, currency}) do
      {:ok, current_fund} ->
        unless current_fund >= amount do
          {:error, :not_enough_money}
        else
          updated_fund = Kernel.-(current_fund, amount)
          customer_data = %{transaction | amount: updated_fund}
          customer_data |> DataStore.update_customer_balance(:withdraw)
          {:ok, updated_fund |> Money.to_float()}
        end

      {:error, _} ->
        {:error, :user_does_not_exist}
    end
  end

  def withdraw({:error, _} = error), do: error

  @spec get_balance(transaction :: t()) :: t()
  def get_balance(%Transaction{user: user, currency: currency}) do
    {:ok, balance} = DataStore.get_account_balance({user, currency})

    {:ok, balance |> Money.to_float()}
  end

  @spec send_fund(transaction :: t()) :: send_response()
  def send_fund(%Transaction{from: from_user, currency: currency} = transaction) do
    case DataStore.get_account_balance({from_user, currency}) do
      {:ok, from_balance} ->
        perform_send_tx(from_balance, transaction)

      {:error, _reason} = error ->
        error
    end
  end

  def send_fund(%Transaction{from: from_user, to: to_user}) when from_user == to_user,
    do: {:error, :wrong_arguments}

  defp perform_send_tx(from_balance, %Transaction{amount: amount} = transaction) do
    do_perform_send_tx(from_balance >= amount, transaction)
  end

  defp do_perform_send_tx(
         true,
         %Transaction{} = transaction
       ) do
    DataStore.customer_intra_transfer(transaction)
  end

  defp do_perform_send_tx(false, _), do: {:error, :not_enough_money}

  def validate_length(input) when is_bitstring(input), do: String.length(input) > 0
  def validate_length(_), do: {:error, :wrong_arguments}
end
