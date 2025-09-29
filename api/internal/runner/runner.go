package runner

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Runner struct {
	Path    string
	Timeout time.Duration
}

func NewRunner(timeout time.Duration) (*Runner, error) {
	path, err := exec.LookPath("holmes")
	if err != nil {
		return nil, fmt.Errorf("holmes binary not found in PATH: %w", err)
	}
	return &Runner{Path: path, Timeout: timeout}, nil
}

//func extractAiPromptSingleLine(outStr string) string {
//	outStr = strings.ReplaceAll(outStr, "\r\n", "\n")
//	re := regexp.MustCompile(`(?ms)^AI:.*\n[\s\S]*`)
//	matches := re.FindAllString(outStr, -1)
//	if len(matches) == 0 {
//		return ""
//	}
//
//	return strings.TrimSpace(matches[len(matches)-1])
//}

func extractAiPromptBlock(outStr string) string {
	// normalize CRLF to LF
	outStr = strings.ReplaceAll(outStr, "\r\n", "\n")

	// find all start indices of lines that begin with "AI:"
	re := regexp.MustCompile(`(?m)^AI:`)
	indices := re.FindAllStringIndex(outStr, -1)
	if len(indices) == 0 {
		return ""
	}

	// take the start index of the last match and slice from there to EOF
	start := indices[len(indices)-1][0]
	return strings.TrimSpace(outStr[start:])
}

func (r *Runner) RunAsk(prompt string) (string, string, error) {
	if err := godotenv.Load(); err != nil {
		fmt.Fprintf(os.Stderr, "godotenv.Load: %v\n", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), r.Timeout)
	defer cancel()

	args := []string{"ask", prompt, `--model=azure/gpt-40`, "-n"}
	cmd := exec.CommandContext(ctx, r.Path, args...)
	cmd.Env = os.Environ()

	out, err := cmd.CombinedOutput()

	outStr := string(out)

	Aioutput := extractAiPromptBlock(outStr)

	return string(Aioutput), "", err
}

type RunnerInterface interface {
	RunAsk(prompt string) (string, string, error)
}
