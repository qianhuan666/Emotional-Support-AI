document.addEventListener("DOMContentLoaded", () => {
    const moodButtons = Array.from(document.querySelectorAll("[data-mood]"));
    const moodStatus = document.querySelector("[data-mood-status]");
    const timerText = document.querySelector("[data-breathing-time]");
    const breathingHint = document.querySelector("[data-breathing-hint]");
    const breathingButton = document.querySelector("[data-breathing-start]");
    const journalInput = document.querySelector("[data-journal-input]");
    const journalSave = document.querySelector("[data-journal-save]");
    const journalTime = document.querySelector("[data-journal-time]");
    const planInput = document.querySelector("[data-plan-input]");
    const planAdd = document.querySelector("[data-plan-add]");
    const planList = document.querySelector("[data-plan-list]");
    const completedCount = document.querySelector("[data-completed-count]");
    const moodCount = document.querySelector("[data-mood-count]");
    const journalState = document.querySelector("[data-journal-state]");
    const apiUrl = "api/workspace-data.jsp";

    const defaultPlans = () => [
        { id: Date.now(), text: "完成一次情绪签到", done: false },
        { id: Date.now() + 1, text: "做 1 分钟呼吸练习", done: false },
        { id: Date.now() + 2, text: "写下今天最需要被照顾的一件事", done: false }
    ];

    let timerId = null;
    let remainingSeconds = 60;
    let saveTimerId = null;
    let state = {
        moodValue: "",
        moodLabel: "",
        moodCount: 0,
        journalContent: "",
        journalSavedAt: "",
        planItems: defaultPlans()
    };

    function scheduleSave() {
        if (saveTimerId) {
            window.clearTimeout(saveTimerId);
        }

        saveTimerId = window.setTimeout(saveState, 250);
    }

    async function loadState() {
        try {
            const response = await fetch(apiUrl, { cache: "no-store" });
            if (!response.ok) {
                return;
            }

            const data = await response.json();
            state = {
                moodValue: data.moodValue || "",
                moodLabel: data.moodLabel || "",
                moodCount: Number(data.moodCount || 0),
                journalContent: data.journalContent || "",
                journalSavedAt: data.journalSavedAt || "",
                planItems: Array.isArray(data.planItems) && data.planItems.length ? data.planItems : defaultPlans()
            };
        } catch (error) {
        }
    }

    async function saveState() {
        saveTimerId = null;

        try {
            await fetch(apiUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
                },
                body: new URLSearchParams({
                    moodValue: state.moodValue,
                    moodLabel: state.moodLabel,
                    moodCount: String(state.moodCount),
                    journalContent: state.journalContent,
                    journalSavedAt: state.journalSavedAt,
                    planItemsJson: JSON.stringify(state.planItems)
                })
            });
        } catch (error) {
        }
    }

    function renderPlan() {
        planList.innerHTML = "";
        let doneCount = 0;

        state.planItems.forEach(item => {
            if (item.done) {
                doneCount += 1;
            }

            const li = document.createElement("li");
            li.className = "plan-item" + (item.done ? " done" : "");
            li.innerHTML = `
                <input class="plan-check" type="checkbox" ${item.done ? "checked" : ""} aria-label="完成事项">
                <span class="plan-text"></span>
                <button class="plan-remove" type="button" aria-label="删除事项">删除</button>
            `;

            li.querySelector(".plan-text").textContent = item.text;
            li.querySelector(".plan-check").addEventListener("change", () => togglePlan(item.id));
            li.querySelector(".plan-remove").addEventListener("click", () => removePlan(item.id));
            planList.appendChild(li);
        });

        completedCount.textContent = String(doneCount);
    }

    function togglePlan(id) {
        state.planItems = state.planItems.map(item => item.id === id ? { id: item.id, text: item.text, done: !item.done } : item);
        renderPlan();
        scheduleSave();
    }

    function removePlan(id) {
        state.planItems = state.planItems.filter(item => item.id !== id);
        renderPlan();
        scheduleSave();
    }

    function addPlan() {
        const value = planInput.value.trim();
        if (!value) {
            planInput.focus();
            return;
        }

        state.planItems.unshift({
            id: Date.now(),
            text: value,
            done: false
        });

        planInput.value = "";
        renderPlan();
        scheduleSave();
        planInput.focus();
    }

    function setMood(moodValue, label) {
        state.moodValue = moodValue;
        state.moodLabel = label;
        state.moodCount += 1;
        moodCount.textContent = String(state.moodCount);
        moodStatus.textContent = `今天的状态：${label}`;
        moodButtons.forEach(button => button.classList.toggle("active", button.dataset.mood === moodValue));
        scheduleSave();
    }

    function hydrateMood() {
        moodCount.textContent = String(state.moodCount);

        if (!state.moodValue) {
            moodStatus.textContent = "今天还没有签到，先选一个最接近你状态的词。";
            return;
        }

        const activeButton = moodButtons.find(button => button.dataset.mood === state.moodValue);
        if (activeButton) {
            activeButton.classList.add("active");
        }

        moodStatus.textContent = state.moodLabel ? `今天的状态：${state.moodLabel}` : "今天已完成签到。";
    }

    function resetBreathingDisplay() {
        remainingSeconds = 60;
        timerText.textContent = "60";
        breathingHint.textContent = "吸气 4 秒、停住 2 秒、呼气 4 秒，跟着节奏慢下来。";
        breathingButton.textContent = "开始练习";
        timerId = null;
    }

    function startBreathing() {
        if (timerId) {
            window.clearInterval(timerId);
            resetBreathingDisplay();
            return;
        }

        breathingHint.textContent = "进行中：跟着你的呼吸，不需要追求完美。";
        breathingButton.textContent = "停止练习";
        timerText.textContent = String(remainingSeconds);

        timerId = window.setInterval(() => {
            remainingSeconds -= 1;
            timerText.textContent = String(remainingSeconds);

            if (remainingSeconds <= 0) {
                window.clearInterval(timerId);
                breathingHint.textContent = "练习完成，给自己一个短暂停顿。";
                breathingButton.textContent = "重新开始";
                timerId = null;
                remainingSeconds = 60;
            }
        }, 1000);
    }

    function hydrateJournal() {
        journalInput.value = state.journalContent;
        journalTime.textContent = state.journalSavedAt ? `最近保存：${state.journalSavedAt}` : "还没有保存记录";
        journalState.textContent = state.journalContent ? "已保存一段疗愈记录" : "尚未保存记录";
    }

    function saveJournal() {
        state.journalContent = journalInput.value.trim();
        state.journalSavedAt = new Date().toLocaleString("zh-CN", { hour12: false });
        journalTime.textContent = `最近保存：${state.journalSavedAt}`;
        journalState.textContent = state.journalContent ? "已保存一段疗愈记录" : "已清空本次记录";
        scheduleSave();
    }

    moodButtons.forEach(button => {
        button.addEventListener("click", () => {
            setMood(button.dataset.mood, button.dataset.label);
        });
    });

    if (breathingButton) {
        breathingButton.addEventListener("click", startBreathing);
    }

    if (journalSave) {
        journalSave.addEventListener("click", saveJournal);
    }

    if (planAdd) {
        planAdd.addEventListener("click", addPlan);
    }

    if (planInput) {
        planInput.addEventListener("keydown", event => {
            if (event.key === "Enter") {
                addPlan();
            }
        });
    }

    (async function init() {
        await loadState();
        hydrateMood();
        hydrateJournal();
        renderPlan();
        resetBreathingDisplay();
    })();
});
