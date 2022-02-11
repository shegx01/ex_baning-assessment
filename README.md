# ExBanking

ExBanking Exercise by for YOLO TEAM Elixir Developer
Specification here [Elixir Test](https://github.com/coingaming/elixir-test)

The system process transactions amoung the customers
created and uniquely identified by the system

## Why use [GenStage](https://hexdocs.pm/gen_stage/GenStage.html) [ConsumerSupervisor](https://hexdocs.pm/gen_stage/ConsumerSupervisor.html#content) ?

GenStage is fantastic in handling processing pipelines with backpressure support.
The advantage of using Genstage is that we have no worry about handling queuing processes and de-queueing them, monitoring the data that child process is processing when they exit. Although we had to synchronize the producer and consumer with ConsumerSupervisor, we do have not to bother ourselves about performance for  Consumer being a single process because ConsumerSupervisor will manage multiple workers up to the maximum demand we set.

## Clone the repository

```bash
  git clone https://github.com/shegx01/ex_banking-assessment.git
```

## Install Dependencies

```bash
mix do deps.get
```

## Perform test and code coverage

```bash
mix test --cover
```

## Generate Documentation/Specification

```bash
mix docs
```

### DESIGN CHOICES

- Empty string type is considered a wrong input.

- if sender is the same as receiver, an error is returned

- Internally, Money is handled by [Money Hex Package](https://hexdocs.pm/money/readme.html) so float overflow will not happen to user funds.

- Transactions are rolled back should the receiver transaction fails to go through

- Each `USER` is represented by a GenStage `Producer` and `ConsumerSupervisor` so that transactions are managed individually.
  
- No Performance Bottleneck from sending more work to `USER` because `ConsumerSupervisor` only manages the events and works are being done in another monitored process by `Elixir TASK`  via `ExBanking.Customer.Worker` module

- Work cannot be lost due to `ConsumerSupervisor` monitors the state of the worker and restarts the job should they fails.

- `USER` is regarded as `ExBanking.Customer`.

- `Transactions` is handled and manipulated by `ExBanking.Customer.Transaction`. This module is responsible for validation, and communication between `USER` and `STORE`.

- `USER Transactions` is represented by a struct that serve as an exchange medium `%ExBanking.Customer.Tranasction{}` between the source `ExBanking.Customer.Producer` and the sink `ExBanking.Customer.Consumer`

## Supervision Tree View

![Supervision Tree](https://user-images.githubusercontent.com/42073367/153468694-9beff593-30fd-4fe4-aba3-ac5e37f1e479.svg)
<!-- 
### See modules inside after generate the docs using

```bash
mix docs
``` -->
