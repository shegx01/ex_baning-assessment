defmodule ExBanking.CustomerConsumerRegistry do
  alias ExBanking.Customer.Consumer

  def start_link do
    Registry.start_link(keys: :unique, name: Consumer)
  end

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
