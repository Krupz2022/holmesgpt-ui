// internal/api/handler.go
package api

import (
	"encoding/json"
	"net/http"
	"ui/api/internal/runner"
)

type requestBody struct {
	Prompt string `json:"prompt"`
}

type responseBody struct {
	Output string `json:"output"`
	Error  string `json:"error,omitempty"`
}

func AskHandler(r *runner.Runner) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		var rq requestBody
		if err := json.NewDecoder(req.Body).Decode(&rq); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}
		if len(rq.Prompt) == 0 || len(rq.Prompt) > 5000 {
			http.Error(w, "prompt empty or too long", http.StatusBadRequest)
			return
		}

		out, _, err := r.RunAsk(rq.Prompt)

		resp := responseBody{Output: out}
		if err != nil {
			resp.Error = err.Error()
			w.WriteHeader(http.StatusInternalServerError)
		} else {
			w.WriteHeader(http.StatusOK)
		}
		_ = json.NewEncoder(w).Encode(resp)
	}
}
