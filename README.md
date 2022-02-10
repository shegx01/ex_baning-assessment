# ExBanking

ExBanking Exercise by for YOLO TEAM Elixir Developer
Specification here [Elixir Test](https://github.com/coingaming/elixir-test)

The system process transactions amoung the customers
created and uniquely identified by the system

## Clone the repository

```bash
  git clone [ex_banking excercise](https://github.com/shegx01/ex_banking-assessment.git)
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

- Internally, Money is handled by [Money Hex Package](https://hexdocs.pm/money/readme.html).

- `USER` is regarded as `ExBanking.Customer`.

- `Transactions` is handled and manipulated by `ExBanking.Customer.Transaction`. This module is responsible for validation, and communication between `USER` and `STORE`.

- `USER Transactions` is represented as a pair of event that is to happen in the system.

- Events are represented by `GenStage`

## Supervision Tree View

![Supervision Tree](https://user-images.githubusercontent.com/42073367/153446938-0d5dab99-e552-4d7f-b7fb-6b005da13917.svg)
