// app.js — keep both user and ai messages in history (up to last 6 exchanges)

const chatWindow = document.getElementById("chat-window");
const promptInput = document.getElementById("prompt");
const sendBtn = document.getElementById("send-btn");
const convList = document.getElementById("conversations");
const newConvBtn = document.querySelector(".new-conv");

const maxExchanges = 6; // up to 6 user+ai pairs
const maxMessages = maxExchanges * 2; // each exchange has user + ai
const maxChars = 4500; // guardrail for combined prompt length

// History: array of { role: "user"|"ai", text: string }, oldest -> newest
let history = [];

// UI helpers
function addMessage(text, who) {
  const div = document.createElement("div");
  div.className = `message ${who}`;
  div.innerText = text;
  chatWindow.appendChild(div);
  chatWindow.scrollTop = chatWindow.scrollHeight;
  return div;
}

function addMuted(text) {
  const div = document.createElement("div");
  div.className = "message muted";
  div.innerText = text;
  chatWindow.appendChild(div);
  chatWindow.scrollTop = chatWindow.scrollHeight;
  return div;
}

function truncateForList(s, n = 60) {
  return s.length > n ? s.slice(0, n - 1) + "…" : s;
}

// Build combined prompt from history + current newPrompt.
// Format: chronological messages (User/AI labeled), then the new User prompt as the final line.
// Ensures total length <= maxChars by dropping oldest exchanges first.
function buildCombinedPrompt(newPrompt) {
  // clone history texts into labeled parts
  const parts = history.map(m => `${m.role === "user" ? "User:" : "AI:"} ${m.text}`);

  // append the new prompt as the last "User:" entry
  parts.push(`User: ${newPrompt}`);

  // join with double newline for clarity
  let combined = parts.join("\n\n");

  // If too long, drop oldest exchange pairs (user+ai)
  // We'll drop two messages at a time to preserve pair structure where possible.
  while (combined.length > maxChars && parts.length > 1) {
    // remove the oldest two items if possible (first user and maybe ai)
    // but to be safe remove one item first, then loop again if needed
    parts.shift(); // remove oldest message
    // try to keep consistent pairs by removing another if still too long
    if (combined.length > maxChars && parts.length > 1) parts.shift();
    combined = parts.join("\n\n");
  }

  // Final safeguard: if still too long, truncate from the front so the tail remains
  if (combined.length > maxChars) {
    combined = combined.slice(combined.length - maxChars);
  }

  return combined;
}

// Push a user message then later an ai message after success.
// Ensures history length <= maxMessages by dropping oldest messages.
function pushUserAndAi(userText, aiText) {
  history.push({ role: "user", text: userText });
  history.push({ role: "ai", text: aiText });

  // Trim oldest entries if we exceed allowed messages
  while (history.length > maxMessages) {
    history.shift();
  }
}

// Networking + UI flow
async function sendPrompt() {
  const prompt = promptInput.value.trim();
  if (!prompt) return;

  // show user message locally (single prompt as user typed)
  addMessage(prompt, "user");
  promptInput.value = "";

  // build combined prompt (includes historical user+ai and this user)
  const combinedPrompt = buildCombinedPrompt(prompt);

  // show temporary thinking indicator
  const loading = addMuted("Thinking…");

  try {
    sendBtn.disabled = true;
    promptInput.disabled = true;

    const res = await fetch("http://localhost:8080/ask", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: combinedPrompt }),
    });

    const data = await res.json();

    loading.remove();
    sendBtn.disabled = false;
    promptInput.disabled = false;
    promptInput.focus();

    if (data.error) {
      addMessage("Error: " + data.error, "ai");
      // do NOT push to history on error
    } else {
       
      let aiReply = data.output.trim(); 
      if (aiReply.startsWith("AI:")) {
        aiReply = aiReply.slice(3).trim();
      }
      // show AI response
      addMessage(data.output, "ai");

      // push both user and ai into history for future context
      pushUserAndAi(prompt, data.output);

    }
  } catch (err) {
    loading.remove();
    sendBtn.disabled = false;
    promptInput.disabled = false;
    addMessage("Request failed: " + err.message, "ai");
  }
}

// Conversation list item helper (non-persistent)
function pushConversation(name) {
  const div = document.createElement("div");
  div.className = "conv-item";
  div.innerText = name;
  convList.prepend(div);
  if (convList.children.length > 10) convList.removeChild(convList.lastChild);
}

newConvBtn.addEventListener("click", () => {
  chatWindow.innerHTML = "";
  history = []; // reset history for new conversation
  pushConversation("New chat " + new Date().toLocaleTimeString());
  promptInput.focus();
});

sendBtn.addEventListener("click", sendPrompt);
promptInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    sendPrompt();
  }
});

// Init UI
pushConversation("Session " + new Date().toLocaleTimeString());
promptInput.focus();
