defmodule ExBanking.Customer.Supervisor do
  use DynamicSupervisor
  alias ExBanking.Customer
  alias ExBanking.Customer.Producer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end


  def start_worker(worker_id) do
    case worker_exists?(worker_id) do
      true ->
        {:error, :user_already_exists}

      false ->
         start_child(worker_id) |> ensure_worker_started()
    end

  end

  @spec worker_exists?(worker_id::String.t()) :: boolean
  def worker_exists?(worker_id) do
    case Registry.lookup(Producer, worker_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  defp ensure_worker_started({:ok, _}), do: :ok
  defp ensure_worker_started({:error, _} = error), do: error


  defp start_child(name) do
    DynamicSupervisor.start_child(__MODULE__,{Customer.Producer, name})
  end

  def init(_init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      # extra_arguments: [init_arg]
    )
  end
end
