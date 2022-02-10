import Config

config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:application, :module, :function, :pid, :registered_name, :file, :line]

  # default config for money that work with elixir
  # do no change
config :money,
  default_currency: :EUR,
  separator: "",
  delimiter: ".",
  symbol: false,
  symbol_on_right: false,
  symbol_space: false,
  fractional_unit: true,
  strip_insignificant_zeros: false

import_config "#{config_env()}.exs"
