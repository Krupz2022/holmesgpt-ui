async function saveHistory() {
  // include timestamps so server can store them if desired
  const nowISO = new Date().toISOString();
  const payload = {
    sessionId,
    messages: history.map(m => ({ role: m.role, text: m.text, ts: nowISO })),
  };

  try {
    await fetch("http://localhost:8000/history", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      keepalive: true, // helps when tab closes
    });
  } catch {
    // non-blocking; ignore errors here
  }
}