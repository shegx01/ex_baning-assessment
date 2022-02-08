defmodule ExBanking.Customer.Worker do
  alias ExBanking.Customer.Transaction

  @moduledoc """
   - Handling transaction event pushed by `Customer.GenStage` aka Consumer
  """
  def make_transaction(%Transaction{type: :deposit} = transaction),
    do: transaction |> Transaction.deposit()

  def make_transaction(%Transaction{type: :withdraw} = transaction),
    do: transaction |> Transaction.withdraw()

  def make_transaction(%Transaction{type: :balance} = transaction),
    do: transaction |> Transaction.get_balance()

  def make_transaction(%Transaction{type: :send} = transaction),
    do: transaction |> Transaction.send_fund()
end
