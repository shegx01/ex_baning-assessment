defmodule ExBanking.CustomerConsumerRegistry do
  alias ExBanking.Customer.Consumer

  @spec start_link :: {:error, any} | {:ok, pid}
  def start_link do
    Registry.start_link(keys: :unique, name: Consumer)
  end

  @spec via_tuple(name :: String.t()) ::
          {:via, Registry, {ExBanking.Customer.Consumer, name :: String.t()}}
  def via_tuple(name) do
    {:via, Registry, {Consumer, name}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: Consumer,
      start: {__MODULE__, :start_link, []}
    )
  end
end
