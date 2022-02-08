defmodule ExBanking.Customer.Consumer do
  use GenStage
  alias ExBanking.{CustomerProducerRegistry, CustomerConsumerRegistry}
  alias ExBanking.Customer.Worker

  @max_demand 10

  def start_link(user) do
    pid = user |> get_consumer_pid()

    {:ok, _} =
      pid
      |> GenStage.sync_subscribe(
        to: CustomerProducerRegistry.via_tuple(user),
        max_demand: @max_demand,
        min_demand: 1
      )

    {:ok, pid}
  end

  defp get_consumer_pid(user) do
    case GenStage.start_link(__MODULE__, user, name: CustomerConsumerRegistry.via_tuple(user)) do
      {:ok, pid} -> pid
      {:error, {_, pid}} -> pid
    end
  end

  # def init(_arg) do
  #   children = [%{id: Worker, start: {Worker, :start_link, []}, restart: :temporary}]
  #   opts = [strategy: :one_for_one]
  #   ConsumerSupervisor.init(children, opts)
  # end

  def init(_) do
    {:consumer, :ok}
  end

  def handle_events(events, _from, state) do
    events
    |> Enum.each(fn {sender, transaction} ->
      response = transaction |> Worker.make_transaction()
      GenStage.reply(sender, response)
    end)

    {:noreply, [], state}
  end
end
