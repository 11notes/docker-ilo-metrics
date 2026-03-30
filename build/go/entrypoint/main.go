package main

import (
	"github.com/11notes/go-eleven"
)

const APP_ROOT = "/usr/local/bin"
const APP_BIN = "ilo-metrics"

func main() {
	// get user and password
	user, err := eleven.Container.GetSecret("ILO_METRICS_USER", "ILO_METRICS_USER_FILE")
	if err != nil {
		eleven.LogFatal("you must set ILO_METRICS_USER or ILO_METRICS_USER_FILE!")
	}

	password, err := eleven.Container.GetSecret("ILO_METRICS_PASSWORD", "ILO_METRICS_PASSWORD_FILE")
	if err != nil {
		eleven.LogFatal("you must set ILO_METRICS_PASSWORD or ILO_METRICS_PASSWORD_FILE!")
	}

	// start app
	eleven.Container.Run(APP_ROOT, APP_BIN, []string{"-web.listen-address=:9090", "-web.telemetry-path=/metrics", "-api.max-concurrent-requests=4", "-api.username=" + user, "-api.password=" + password})
}