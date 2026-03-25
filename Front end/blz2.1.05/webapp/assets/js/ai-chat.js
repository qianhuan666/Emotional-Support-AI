(() => {
    const MAX = 1000;
    const WSTOKEN_URL = "api/ai-chat.jsp?action=wstoken";

    const elements = {
        messageList: document.getElementById("messageList"),
        emptyState: document.getElementById("emptyState"),
        messagesScroll: document.getElementById("messagesScroll"),
        messageInput: document.getElementById("messageInput"),
        sendBtn: document.getElementById("sendBtn"),
        stopBtn: document.getElementById("stopBtn"),
        charCounter: document.getElementById("charCounter"),
        messageCount: document.getElementById("messageCount"),
        conversationList: document.getElementById("conversationList"),
        newChatBtn: document.getElementById("newChatBtn")
    };

    const state = {
        messages: [],
        ws: null,
        connected: false,
        userId: null,
        reconnectTimer: null,
        reconnectDelay: 2000
    };

    function esc(value) {
        return String(value || "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    function renderMarkdown(text) {
        const html = esc(text || "")
            .replace(/\r\n/g, "\n")
            .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
            .replace(/`([^`]+)`/g, "<code>$1</code>")
            .split(/\n{2,}/)
            .map(block => `<p>${block.replace(/\n/g, "<br>")}</p>`)
            .join("");
        return window.DOMPurify ? window.DOMPurify.sanitize(html) : html;
    }

    function scrollToBottom() {
        requestAnimationFrame(() => {
            elements.messagesScroll.scrollTop = elements.messagesScroll.scrollHeight;
        });
    }

    function updateCounters() {
        elements.messageCount.textContent = String(state.messages.length);
        const current = elements.messageInput.value || "";
        elements.charCounter.textContent = `${current.length} / ${MAX}`;
    }

    function toggleEmpty() {
        const hasMessages = state.messages.length > 0;
        elements.emptyState.classList.toggle("hidden", hasMessages);
        elements.messageList.classList.toggle("hidden", !hasMessages);
    }

    function renderMessages() {
        elements.messageList.innerHTML = state.messages.map(message => `
            <article class="row ${message.role}">
                <div class="avatar">${message.role === "assistant" ? "AI" : "你"}</div>
                <div class="bubble">
                    <div class="meta">${message.role === "assistant" ? "AI 陪伴" : "当前输入"}</div>
                    <div class="content">${renderMarkdown(message.content || "")}</div>
                </div>
            </article>
        `).join("");
        toggleEmpty();
        updateCounters();
        scrollToBottom();
    }

    function setConnected(connected) {
        state.connected = connected;
        elements.sendBtn.disabled = !connected;
        elements.stopBtn.classList.add("hidden");
        if (elements.conversationList) {
            elements.conversationList.innerHTML = connected
                ? '<div class="soft-label">已连接到 MaiBot</div>'
                : '<div class="soft-label">正在连接 MaiBot...</div>';
        }
    }

    function addMessage(role, content) {
        state.messages.push({ role, content });
        renderMessages();
    }

    function handleBotMessage(data) {
        // data.content is the full message text
        const content = data.content || "";
        if (!content) return;
        addMessage("assistant", content);
    }

    function handleHistory(data) {
        const msgs = Array.isArray(data.messages) ? data.messages : [];
        state.messages = msgs.map(m => ({
            role: m.is_bot ? "assistant" : "user",
            content: m.content || ""
        }));
        renderMessages();
    }

    function connect(wsEndpoint, token, userId) {
        if (state.ws) {
            state.ws.onclose = null;
            state.ws.close();
            state.ws = null;
        }

        state.userId = userId;
        const url = `${wsEndpoint}?token=${encodeURIComponent(token)}&user_id=${encodeURIComponent(userId)}&user_name=用户`;

        const ws = new WebSocket(url);
        state.ws = ws;

        ws.onopen = () => {
            state.reconnectDelay = 2000;
            setConnected(true);
        };

        ws.onmessage = event => {
            let data;
            try {
                data = JSON.parse(event.data);
            } catch (e) {
                return;
            }

            switch (data.type) {
                case "bot_message":
                    handleBotMessage(data);
                    break;
                case "history":
                    handleHistory(data);
                    break;
                case "user_message":
                    if (data.sender && data.sender.user_id !== state.userId) {
                        addMessage("user", data.content);
                    }
                    break;
                case "typing":
                    // could show a typing indicator; skip for now
                    break;
                case "system":
                    // system messages — ignore silently
                    break;
                case "session_info":
                    if (data.user_id) state.userId = data.user_id;
                    break;
                case "error":
                    addMessage("assistant", data.content || "发生错误，请稍后再试。");
                    break;
            }
        };

        ws.onerror = () => {
            setConnected(false);
        };

        ws.onclose = () => {
            setConnected(false);
            // auto-reconnect with fresh token
            state.reconnectTimer = setTimeout(() => init(), state.reconnectDelay);
            state.reconnectDelay = Math.min(state.reconnectDelay * 2, 30000);
        };
    }

    function sendMessage() {
        const content = (elements.messageInput.value || "").trim();
        if (!content || !state.connected || !state.ws) return;

        // optimistic render
        addMessage("user", content);
        elements.messageInput.value = "";
        updateCounters();

        state.ws.send(JSON.stringify({ type: "message", content }));
    }

    function newConversation() {
        state.messages = [];
        renderMessages();
        elements.messageInput.focus();
    }

    elements.messageInput.addEventListener("input", updateCounters);
    elements.messageInput.addEventListener("keydown", event => {
        if (event.key === "Enter" && !event.shiftKey) {
            event.preventDefault();
            sendMessage();
        }
    });
    elements.sendBtn.addEventListener("click", sendMessage);
    elements.newChatBtn.addEventListener("click", newConversation);

    async function init() {
        setConnected(false);
        updateCounters();
        toggleEmpty();

        try {
            const res = await fetch(WSTOKEN_URL, { cache: "no-store" });
            if (!res.ok) return;
            const data = await res.json();
            if (!data.success || !data.token || !data.wsEndpoint) return;
            connect(data.wsEndpoint, data.token, data.userId || "webui_user_anon");
        } catch (e) {
            // retry handled by reconnect logic
        }
    }

    init();
})();
