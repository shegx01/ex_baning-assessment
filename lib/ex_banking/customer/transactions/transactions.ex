defmodule ExBanking.Customer.Transaction do
  @moduledoc """
    Exchange abstraction representing a single transaction
    in the code
  """
  require Logger
  alias ExBanking.Customer.{DataStore, Producer}
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

  @doc """
    transaction validator for new/4
  """
  @spec new(
          type :: atom(),
          user :: bitstring(),
          amount :: non_neg_integer(),
          currency :: bitstring()
        ) :: t()
  def new(type, user, amount, currency) when is_valid_deposit_withdraw(user, amount, currency) do
    with updated_fund <- amount,
         :ok <- validate_length(user),
         :ok <- validate_length(currency) do
      %Transaction{
        type: type,
        user: user,
        amount: updated_fund,
        currency: currency
      }
    end
  end

  def new(_, _, _, _), do: {:error, :wrong_arguments}

  @spec new(balance :: atom(), user :: String.t(), currency :: String.t()) :: t()
  def new(:balance, user, currency)
      when is_bitstring(user) and is_bitstring(currency) do
    with :ok <- validate_length(user),
         :ok <- validate_length(currency) do
      %Transaction{
        type: :balance,
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
             amount > 0 and not is_nil(amount) do
    with :ok <- validate_length(from_user),
         :ok <- validate_length(to_user),
         :ok <- validate_length(currency),
         updated_fund <- amount do
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
    {:ok, balance} = DataStore.update_customer_balance(transaction)
    {:ok, balance}
  end

  def deposit({:error, _} = error), do: error

  @spec withdraw(transaction :: t()) :: deposit_withdraw_response()
  def withdraw(%Transaction{user: user, amount: amount, currency: currency} = transaction) do
    {:ok, current_fund} = DataStore.get_account_balance({user, currency})

    unless can_make_withdraw?(current_fund, amount) do
      {:error, :not_enough_money}
    else
      updated_fund = Money.subtract(current_fund, amount)
      customer_data = %{transaction | amount: updated_fund}
      customer_data |> DataStore.insert_customer_balance()
      {:ok, updated_fund}
    end
  end

  def withdraw({:error, _} = error), do: error

  @spec get_balance(transaction :: t()) :: {:ok, Money.t()}
  def get_balance(%Transaction{user: user, currency: currency}) do
    DataStore.get_account_balance({user, currency})
  end

  def send_fund(%Transaction{from: from_user, to: to_user}) when from_user == to_user,
    do: {:error, :wrong_arguments}

  @spec send_fund(transaction :: t()) :: send_response()
  def send_fund(
        %Transaction{from: from_user, to: to_user, currency: currency, amount: amount} =
          transaction
      ) do
    {:ok, from_balance} = DataStore.get_account_balance({from_user, currency})

    case can_make_withdraw?(from_balance, amount) do
      true ->
        sender_data = %{
          transaction
          | user: from_user,
            amount: Money.subtract(from_balance, amount)
        }

        receiver_data = %Transaction{
          type: :deposit,
          user: to_user,
          amount: amount,
          currency: currency
        }

        case Producer.create_transaction(receiver_data) do
          {:ok, receiver_new_balance} ->
            {:ok, true} = sender_data |> DataStore.insert_customer_balance()
            Logger.info("logging receiver balance")
            IO.inspect(receiver_new_balance)

            {:ok, Money.subtract(from_balance, amount), receiver_new_balance |> input_to_money()}

          _transaction_struct ->
            # This is an error returned from transaction rollback
            # from receiver

            {:error, :tx_error_occured}
        end

      false ->
        {:error, :not_enough_money}
    end
  end

  def validate_length(input) when is_bitstring(input) do
    unless String.length(input) > 0 do
      {:error, :wrong_arguments}
    else
      :ok
    end
  end

  def validate_length(_), do: {:error, :wrong_arguments}

  def validate_number(%Money{}), do: :ok
  def validate_number(input) when is_number(input) or is_float(input), do: :ok
  def validate_number(_), do: {:error, :wrong_arguments}

  defp can_make_withdraw?(user_balance, amount) do
    case Money.subtract(user_balance, amount) |> Money.cmp(Money.new(0)) do
      :lt -> false
      :gt -> true
      :eq -> true
    end
  end

  def convert_fund_to_money(%Transaction{amount: amount} = transaction),
    do: %{transaction | amount: input_to_money(amount)}

  def input_to_money(%Money{} = user_input) do
    user_input
  end

  def input_to_money(user_input) do
    case Money.parse(user_input) do
      {:ok, money} -> money
      :error -> Money.new(0)
    end
  end

  def format_fund_response({:ok, %Money{} = amount}),
    do: {:ok, Money.to_string(amount) |> String.to_float()}

  def format_fund_response({:ok, %Money{} = sender_amount, %Money{} = receiver_amount}) do
    {:ok, Money.to_string(sender_amount) |> String.to_float(),
     Money.to_string(receiver_amount) |> String.to_float()}
  end

  def format_fund_response(%Money{} = response),
    do: response |> Money.to_string() |> String.to_float()

  def format_fund_response(response), do: response
end
