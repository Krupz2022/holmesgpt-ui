const chatWindow = document.getElementById("chat-window");
const promptInput = document.getElementById("prompt");
const sendBtn = document.getElementById("send-btn");
const convList = document.getElementById("conversations");
const newConvBtn = document.querySelector(".new-conv");

const maxExchanges = 6; 
const maxMessages = maxExchanges * 2; 
const maxChars = 4500; 


let history = [];


function getSessionId() {
  let id = localStorage.getItem("sessionId");
  if (!id) {
    id = (crypto.randomUUID && crypto.randomUUID()) || (Date.now() + "-" + Math.random().toString(36).slice(2));
    localStorage.setItem("sessionId", id);
  }
  return id;
}
const sessionId = getSessionId();

function getTurn() {
  const k = `turn:${sessionId}`;
  const v = parseInt(localStorage.getItem(k) || "0", 10);
  return isNaN(v) ? 0 : v;
}
function bumpTurn() {
  const k = `turn:${sessionId}`;
  localStorage.setItem(k, String(getTurn() + 1));
}

async function sendLatestTurn() {

  if (history.length < 2) return;

  const [m1, m2] = history.slice(-2);

  if (!(m1.role === "user" && m2.role === "ai")) {
    return;
  }

  const nowISO = new Date().toISOString();
  const payload = {
    sessionId,
    turn: getTurn() + 1, 
    messages: [
      { role: m1.role, text: m1.text, ts: nowISO },
      { role: m2.role, text: m2.text, ts: nowISO },
    ],
  };

  try {
    await fetch("/history", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      keepalive: true,
    });
    bumpTurn();
  } catch {
    
  }
}


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


function buildCombinedPrompt(newPrompt) {

  const parts = history.map(m => `${m.role === "user" ? "User:" : "AI:"} ${m.text}`);


  parts.push(`User: ${newPrompt}`);


  let combined = parts.join("\n\n");


  while (combined.length > maxChars && parts.length > 1) {

    parts.shift(); 

    if (combined.length > maxChars && parts.length > 1) parts.shift();
    combined = parts.join("\n\n");
  }


  if (combined.length > maxChars) {
    combined = combined.slice(combined.length - maxChars);
  }

  return combined;
}


function pushUserAndAi(userText, aiText) {
  history.push({ role: "user", text: userText });
  history.push({ role: "ai", text: aiText });

  while (history.length > maxMessages) history.shift();

  sendLatestTurn(); 
}


async function sendPrompt() {
  const prompt = promptInput.value.trim();
  if (!prompt) return;


  addMessage(prompt, "user");
  promptInput.value = "";


  const combinedPrompt = buildCombinedPrompt(prompt);


  const loading = addMuted("Thinking…");

  try {
    sendBtn.disabled = true;
    promptInput.disabled = true;

    const res = await fetch("/ask", {
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

    } else {
       
      let aiReply = data.output.trim(); 
      if (aiReply.startsWith("AI:")) {
        aiReply = aiReply.slice(3).trim();
      }

      addMessage(data.output, "ai");


      pushUserAndAi(prompt, data.output);

    }
  } catch (err) {
    loading.remove();
    sendBtn.disabled = false;
    promptInput.disabled = false;
    addMessage("Request failed: " + err.message, "ai");
  }
}


function pushConversation(name) {
  const div = document.createElement("div");
  div.className = "conv-item";
  div.innerText = name;
  convList.prepend(div);
  if (convList.children.length > 10) convList.removeChild(convList.lastChild);
}

newConvBtn.addEventListener("click", () => {
  chatWindow.innerHTML = "";
  history = []; 
  saveHistory();
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


function hasOauthCookie() {
  return document.cookie.split(';').some(cookie => cookie.trim().startsWith("_oauth2_proxy="));
}

function logOut() {
  if (hasOauthCookie()) {
    window.location.href = "/logout";
  } else {
    document.getElementById("mainbody").classList.add("hidden");
    document.getElementById("login").classList.remove("hidden");
  }
}

logOut();

const validUser = "Admin";
const validPass = "Pass";

function login(e) {
  if (e && e.preventDefault) e.preventDefault();
  const msg = document.getElementById("message");

  if (hasOauthCookie()) {
    document.getElementById("login").classList.add("hidden");
    document.getElementById("mainbody").classList.remove("hidden");
    msg.textContent = "";
  } else {
    const user = document.getElementById("username").value;
    const pass = document.getElementById("password").value;

    if (user === validUser && pass === validPass) {
      msg.textContent = "";
      document.getElementById("login").classList.add("hidden");
      document.getElementById("mainbody").classList.remove("hidden");
    } else {
      msg.style.color = "red";
      msg.textContent = "Invalid username or password.";
    }
  }
}