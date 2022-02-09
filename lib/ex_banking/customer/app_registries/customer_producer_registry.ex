defmodule ExBanking.CustomerProducerRegistry do
  alias ExBanking.Customer.Producer

  @spec start_link :: {:error, any} | {:ok, pid}
  def start_link do
    Registry.start_link(keys: :unique, name: Producer)
  end

  @spec via_tuple(String.t()) :: {:via, Registry, {ExBanking.Customer.Producer, String.t()}}
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
