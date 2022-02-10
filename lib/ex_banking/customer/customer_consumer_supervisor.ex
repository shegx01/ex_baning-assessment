defmodule ExBanking.Customer.Consumer do
  @moduledoc """
  `ExBanking.Customer.Consumer` as a DynamicSupervisor starts its children
   as sooon as it receives thems from  `ExBanking.Customer.StagesDynamicSupervisor`.
   starts `ExBanking.Customer.Producer` to perform its works and shot them down when
   they exit normal, Else restart another one if it fails
  """
  use ConsumerSupervisor
  alias ExBanking.{CustomerProducerRegistry, CustomerConsumerRegistry}
  alias ExBanking.Customer.Worker

  @max_demand 10

  @spec start_link(user :: String.t()) ::
          {:ok, atom | pid | {atom, user :: String.t()} | {:via, atom, user :: String.t()}}
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

  @spec get_consumer_pid(user :: String.t()) :: pid()
  defp get_consumer_pid(user) do
    case ConsumerSupervisor.start_link(__MODULE__, user,
           name: CustomerConsumerRegistry.via_tuple(user)
         ) do
      {:ok, pid} -> pid
      {:error, {_, pid}} -> pid
    end
  end

  def init(_arg) do
    children = [%{id: Worker, start: {Worker, :start_link, []}, restart: :temporary}]
    opts = [strategy: :one_for_one]
    ConsumerSupervisor.init(children, opts)
  end
end
