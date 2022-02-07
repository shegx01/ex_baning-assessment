defmodule ExBanking.CustomerRegistry do
  alias ExBanking.Customer.Producer
  def start_link do
    Registry.start_link(keys: :unique, name: Producer)
  end

  def via_tuple(name) do
    {:via, Registry, {Producer, name}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: Producer,
      start: {__MODULE__, :start_link, []}
    )
  end
end
