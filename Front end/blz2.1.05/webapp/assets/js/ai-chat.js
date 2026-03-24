(() => {
    const MAX = 1000;
    const CHAT_URL = "api/ai-chat.jsp?action=chat";
    const LIST_URL = "api/ai-chat.jsp?action=list";
    const HISTORY_URL = "api/ai-chat.jsp?action=history";
    const DELETE_URL = "api/ai-chat.jsp?action=delete";

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
        conversationId: null,
        messages: [],
        conversations: [],
        controller: null,
        streaming: false
    };

    function esc(value) {
        return String(value || "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
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

    function renderConversationList() {
        if (!elements.conversationList) {
            return;
        }

        if (!state.conversations.length) {
            elements.conversationList.innerHTML = '<div class="soft-label">还没有保存过会话</div>';
            return;
        }

        elements.conversationList.innerHTML = state.conversations.map(item => `
            <div class="conversation-item ${state.conversationId === item.id ? "active" : ""}" data-id="${item.id}">
                <span class="conversation-title">${esc(item.title)}</span>
                <span class="conversation-time">${esc(item.updatedAt || "")}</span>
            </div>
        `).join("");

        elements.conversationList.querySelectorAll(".conversation-item").forEach(node => {
            node.addEventListener("click", () => {
                const id = Number(node.dataset.id);
                loadHistory(id);
            });
            node.addEventListener("contextmenu", async event => {
                event.preventDefault();
                const id = Number(node.dataset.id);
                if (!window.confirm("确定要删除这个会话吗？")) {
                    return;
                }
                await fetch(DELETE_URL, {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
                    body: new URLSearchParams({ conversationId: String(id) })
                });
                if (state.conversationId === id) {
                    state.conversationId = null;
                    state.messages = [];
                    renderMessages();
                }
                await loadConversationList();
            });
        });
    }

    async function loadConversationList() {
        try {
            const response = await fetch(LIST_URL, { cache: "no-store" });
            if (!response.ok) {
                return;
            }
            const data = await response.json();
            state.conversations = Array.isArray(data.conversations) ? data.conversations : [];
            renderConversationList();
        } catch (error) {
        }
    }

    async function loadHistory(conversationId) {
        const query = conversationId ? `${HISTORY_URL}&conversationId=${conversationId}` : HISTORY_URL;
        try {
            const response = await fetch(query, { cache: "no-store" });
            if (!response.ok) {
                return;
            }
            const data = await response.json();
            state.conversationId = data.conversationId || null;
            state.messages = Array.isArray(data.messages) ? data.messages : [];
            renderMessages();
            renderConversationList();
        } catch (error) {
        }
    }

    function setStreaming(streaming) {
        state.streaming = streaming;
        elements.sendBtn.disabled = streaming;
        elements.stopBtn.classList.toggle("hidden", !streaming);
    }

    async function sendMessage() {
        const content = (elements.messageInput.value || "").trim();
        if (!content || state.streaming) {
            return;
        }

        state.messages.push({ role: "user", content });
        state.messages.push({ role: "assistant", content: "" });
        elements.messageInput.value = "";
        renderMessages();
        setStreaming(true);

        const assistantMessage = state.messages[state.messages.length - 1];
        const controller = new AbortController();
        state.controller = controller;

        try {
            const response = await fetch(CHAT_URL, {
                method: "POST",
                headers: {
                    "Accept": "text/event-stream",
                    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
                },
                body: new URLSearchParams({
                    messages: JSON.stringify(state.messages.map(item => ({ role: item.role, content: item.content }))),
                    prompt: content,
                    conversationId: state.conversationId ? String(state.conversationId) : ""
                }),
                signal: controller.signal
            });

            const conversationHeader = response.headers.get("X-Conversation-Id");
            if (conversationHeader) {
                state.conversationId = Number(conversationHeader);
            }

            const reader = response.body.getReader();
            const decoder = new TextDecoder("utf-8");
            let buffer = "";
            let done = false;

            while (!done) {
                const part = await reader.read();
                done = part.done;
                buffer += decoder.decode(part.value || new Uint8Array(), { stream: !done });
                const lines = buffer.split(/\r?\n/);
                buffer = lines.pop() || "";

                for (const line of lines) {
                    const trimmed = line.trim();
                    if (!trimmed.startsWith("data:")) {
                        continue;
                    }
                    const data = trimmed.slice(5).trim();
                    if (!data || data === "[DONE]") {
                        continue;
                    }
                    try {
                        const json = JSON.parse(data);
                        const delta = json.choices && json.choices[0] && json.choices[0].delta && json.choices[0].delta.content
                            ? json.choices[0].delta.content
                            : "";
                        if (delta) {
                            assistantMessage.content += delta;
                            renderMessages();
                        }
                    } catch (error) {
                    }
                }
            }

            await loadConversationList();
        } catch (error) {
            assistantMessage.content = assistantMessage.content || "当前回复失败，请稍后再试。";
            renderMessages();
        } finally {
            state.controller = null;
            setStreaming(false);
        }
    }

    function newConversation() {
        state.conversationId = null;
        state.messages = [];
        renderMessages();
        renderConversationList();
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
    elements.stopBtn.addEventListener("click", () => {
        if (state.controller) {
            state.controller.abort();
        }
        setStreaming(false);
    });

    (async function init() {
        updateCounters();
        toggleEmpty();
        await loadConversationList();
        await loadHistory();
    })();
})();
