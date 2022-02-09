defmodule ExBanking.Customer.Producer do
  use GenStage
  alias ExBanking.Customer
  alias ExBanking.CustomerProducerRegistry
  alias ExBanking.Customer.{Transaction}

  @moduledoc """
  - Managing job for each user as a Genstage

  """

  @type transaction_queue :: :queue.queue({sender_id :: pid(), Transaction.t()})
  @spec start_link(user :: String.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(user) do
    GenStage.start_link(__MODULE__, 0, name: via_tuple(user))
  end

  @impl GenStage
  @spec init(initial_demand :: non_neg_integer()) ::
          {:producer, {:queue.queue({sender_pid :: pid()}), transaction :: Transaction.t()}}
  def init(initial_demand) do
    {:producer, {:queue.new(), initial_demand}}
  end

  defp via_tuple(worker_id) do
    CustomerProducerRegistry.via_tuple(worker_id)
  end

  @spec get_pid(worker_id :: String.t()) :: nil | pid()
  def get_pid(worker_id) do
    Customer.StagesDynamicSupervisor.get_pid(:producer, worker_id)
  end

  @spec worker_exists?(worker_id :: String.t()) :: boolean()

  defp worker_exists?(worker_id) do
    Customer.StagesDynamicSupervisor.worker_exists?(worker_id)
  end

  # Genstage server
  # communicating with `ExBanking` module for transaction struct creation
  # and calling calling queueing process

  def create_transaction(%Transaction{user: user} = transaction) when not is_nil(user) do
    case worker_exists?(user) do
      true ->
        GenStage.call(via_tuple(user), {:transaction, transaction})

      false ->
        {:error, :user_does_not_exist}
    end
  end

  def create_transaction(%Transaction{from: from, to: to} = transaction) do
    case from == to do
      true ->
        {:error, :wrong_arguments}

      _ ->
        case worker_exists?(from) do
          true ->
            case worker_exists?(to) do
              true -> GenStage.call(via_tuple(from), {:transaction, transaction})
              false -> {:error, :receiver_does_not_exist}
            end

          false ->
            {:error, :sender_does_not_exist}
        end
    end
  end

  def create_transaction({:error, _} = error), do: error
  def create_transaction(_), do: {:error, :wrong_arguments}

  @doc """
    CONSTRAINT 1
    `In every single moment of time the system should handle 10 or less operations for every individual user`

   - I manually managing queueing process and pending transaction demand
     we dont want to push to the system if max 10 active event is in the system.
   - since we manage the queue, the `pending_demand` must be 0 and max demand     must be 10
     to guarantee this rule
     so the demand from the consumer must have been satisfied if current pending demand is
     equal to 0 in this producer module

     CONSTRAINT 2
     ` If there is any new operation for this user and he/she still has 10 operations in pending state - new operation for this user should immediately return too_many_requests_to_user`

   - This rule holds automatically since our max demain is 10 from the consumer
  """

  @impl GenStage
  def handle_call(
        {:transaction, %Transaction{type: :send, from: from, to: _to} = transaction},
        sender,
        {queue, pending_demand}
      )
      when pending_demand > 0 do
    case get_pid(from) == self() do
      true ->
        queue = enqueue_message(queue, {sender, transaction})

        # we would not want to handle transaction here
        # so lets delegate the work it to handle_info/2
        Process.send(self(), :new_transaction, [])
        {:noreply, [], {queue, pending_demand - 1}}

      false ->
        queue = enqueue_message(queue, {sender, transaction})
        Process.send(self(), :new_transaction, [])
        {:noreply, [], {queue, pending_demand - 1}}
    end
  end

  def handle_call(
        {:transaction, %Transaction{type: :send, from: from, to: _to}},
        _sender,
        state
      ) do
    case get_pid(from) == self() do
      true ->
        message = {:error, :too_many_requests_to_sender}

        {:reply, message, [], state}

      false ->
        message = {:error, :too_many_requests_to_receiver}

        {:reply, message, [], state}
    end
  end

  def handle_call({:transaction, transaction}, sender, {queue, pending_demand})
      when pending_demand > 0 do
    queue = enqueue_message(queue, {sender, transaction})
    # we would not want to handle transaction here
    # so lets delegate the work it to handle_info/2
    Process.send(self(), :new_transaction, [])
    {:noreply, [], {queue, pending_demand - 1}}
  end

  def handle_call({:transaction, _transaction}, _sender, state) do
    message = {:error, :too_many_requests_to_user}

    {:reply, message, [], state}
  end

  #  validating the constraint of :too_many_requests_to_sender and :too_many_requests_to_sender

  # handing demand
  # minimum number of demand expected is 1
  # thanks to genstage, amy pending demand will be
  # served when the event is available
  @impl GenStage
  def handle_demand(demand, {queue, pending_demand}) do
    case :queue.out(queue) do
      {{:value, transaction}, queue} ->
        {:noreply, [transaction], {queue, demand + pending_demand - 1}}

      {:empty, queue} ->
        {:noreply, [], {queue, demand + pending_demand}}
    end
  end

  @impl GenStage
  @spec handle_info(
          :new_transaction,
          {:queue.queue({sender_pid :: pid(), Transaction.t()}),
           pending_demand :: non_neg_integer()}
        ) ::
          {:noreply, list({sender_id :: pid(), Transaction.t()}),
           {:queue.queue({sender_pid :: pid(), Transaction.t()}), non_neg_integer()}}
  def handle_info(:new_transaction, {queue, pending_demand}) do
    case :queue.out(queue) do
      {{:value, transaction}, queue} ->
        {:noreply, [transaction], {queue, pending_demand}}

      {:empty, queue} ->
        {:noreply, [], {queue, pending_demand}}
    end
  end

  @spec enqueue_message(transaction_queue(), {sender_id :: pid(), Transaction.t()}) ::
          transaction_queue()
  defp enqueue_message(queue, message), do: :queue.in(message, queue)
end
