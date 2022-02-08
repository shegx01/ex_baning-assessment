import Config

# config :logger, :console,
#   format: "\n$time $metadata[$level] $levelpad$message\n",
#   metadata: [:application, :module, :function, :pid, :registered_name, :file, :line]

import_config "#{config_env()}.exs"
