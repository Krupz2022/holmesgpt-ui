package api

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type Message struct {
	Role string `json:"role"`
	Text string `json:"text"`
	TS   string `json:"ts,omitempty"`
}
type HistoryPayload struct {
	SessionID string    `json:"sessionId"`
	Turn      int       `json:"turn,omitempty"`
	Messages  []Message `json:"messages"`
}

type snapshot struct {
	//ReceivedAt time.Time `json:"received_at"`
	//SessionID  string    `json:"session"`
	//Turn       int       `json:"turn,omitempty"`
	//Count      int       `json:"count"`
	Messages []Message `json:"messages"`
}

const (
	maxBodyBytes       = 1 << 20
	maxMessagesPerPost = 200
	logRoot            = "/var/log/ai-chat"
)

func HistoryHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)
	defer r.Body.Close()

	var p HistoryPayload
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()

	if err := dec.Decode(&p); err != nil {
		http.Error(w, "bad request: "+err.Error(), http.StatusBadRequest)
		return
	}

	if err := validatePayload(&p); err != nil {
		http.Error(w, "Invalid PAYLOAD "+err.Error(), http.StatusBadRequest)
		return
	}

	today := time.Now().UTC().Format("2006-01-02")
	dir := filepath.Join(logRoot, today)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		http.Error(w, "server cant make dir ERROR", http.StatusInternalServerError)
		return
	}

	filename := fmt.Sprintf("%s.jsonl", today)
	path := filepath.Join(dir, filename)

	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		http.Error(w, "server open error", http.StatusInternalServerError)
		return
	}
	defer f.Close()

	snap := snapshot{
		//	ReceivedAt: time.Now().UTC(),
		//	SessionID:  p.SessionID,
		//	Count:      len(p.Messages),
		Messages: p.Messages,
	}
	b, err := json.Marshal(snap)

	if err != nil {
		http.Error(w, "server marshal error", http.StatusInternalServerError)
		return
	}

	bw := bufio.NewWriterSize(f, 64<<10)
	if _, err := bw.Write(b); err != nil {
		http.Error(w, "server write error", http.StatusInternalServerError)
		return
	}
	if err := bw.WriteByte('\n'); err != nil {
		http.Error(w, "server write error", http.StatusInternalServerError)
		return
	}
	if err := bw.Flush(); err != nil {
		http.Error(w, "server flush error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

func validatePayload(p *HistoryPayload) error {
	if p.SessionID == "" {
		return errors.New("sessionId required")
	}
	if len(p.Messages) == 0 {
		return errors.New("messages empty")
	}
	if len(p.Messages) > maxMessagesPerPost {
		return fmt.Errorf("too many messages (max %d)", maxMessagesPerPost)
	}
	for i := range p.Messages {
		m := &p.Messages[i]
		role := strings.ToLower(m.Role)
		if role != "user" && role != "ai" {
			return fmt.Errorf("messages[%d].role must be 'user' or 'ai'", i)
		}
		// basic redaction example for bearer tokens
		if strings.Contains(strings.ToLower(m.Text), "bearer ") {
			m.Text = "[redacted token]"
		}
		if len(m.Text) > 8000 {
			return fmt.Errorf("messages[%d].text too long", i)
		}
	}
	return nil
}

//func sanitizeFilename(s string) string {
//	s = strings.ReplaceAll(s, "..", "")
//	return strings.Map(func(r rune) rune {
//		switch r {
//		case '/', '\\', ':', '*', '?', '"', '<', '>', '|':
//			return '_'
//		default:
//			return r
//		}
//	}, s)
//}
