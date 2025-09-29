package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"ui/api/internal/api"
	"ui/api/internal/runner"
)

func corsMiddleware(next http.Handler) http.Handler {
	allowedOrigin := "http://localhost:5500" // restrict in dev -> production: use exact origin(s)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		w.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		// If you use credentials (cookies / auth), set this and ensure origin is not "*"
		// w.Header().Set("Access-Control-Allow-Credentials", "true")

		// Preflight requests (OPTIONS) - no body needed
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	// Create the runner
	cliTimeout := 60 * time.Second
	r, err := runner.NewRunner(cliTimeout)
	if err != nil {
		log.Fatalf("failed to create runner: %v", err)
	}

	// Build HTTP server
	mux := http.NewServeMux()
	mux.HandleFunc("/ask", api.AskHandler(r))
	mux.HandleFunc("/history", api.HistoryHandler)

	handler := corsMiddleware(mux)

	srv := &http.Server{
		Addr:         ":8000",
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Run in goroutine
	go func() {
		log.Printf("listening on %s\n", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server failed: %v", err)
		}
	}()

	// Graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	log.Println("shutdown signal received, shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("graceful shutdown failed: %v", err)
		if cerr := srv.Close(); cerr != nil {
			log.Printf("server close failed: %v", cerr)
		}
	}
	log.Println("server stopped")
}
