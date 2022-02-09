defmodule ExBanking.Customer.Worker do
  alias ExBanking.Customer.Transaction

  @moduledoc """
  - This module is called dynamically by `Customer.Consumer.Supervisor`

  """
  def start_link({sender, transaction}) do
    IO.inspect(transaction, label: "args")

    Task.start_link(fn ->
      response = transaction |> make_transaction()
      GenStage.reply(sender, response |> Transaction.format_fund_response())
    end)
  end

  def make_transaction(%Transaction{type: :deposit} = transaction),
    do: transaction |> Transaction.convert_fund_to_money() |> Transaction.deposit()

  def make_transaction(%Transaction{type: :withdraw} = transaction),
    do: transaction |> Transaction.convert_fund_to_money() |> Transaction.withdraw()

  def make_transaction(%Transaction{type: :balance} = transaction),
    do: transaction |> Transaction.get_balance()

  def make_transaction(%Transaction{type: :send} = transaction),
    do: transaction |> Transaction.convert_fund_to_money() |> Transaction.send_fund()
end
