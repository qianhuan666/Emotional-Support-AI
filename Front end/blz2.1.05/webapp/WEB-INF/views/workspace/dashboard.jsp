<%
String workspaceUsername = (String) request.getAttribute("workspaceUsername");
%>
<div class="workspace-shell">
    <section class="workspace-hero">
        <div class="workspace-topbar">
            <div>
                <div class="eyebrow">Healing Workspace</div>
                <h1>欢迎回来，<%= workspaceUsername %></h1>
                <p>这里是你的个人疗愈工作台：情绪签到、呼吸练习、记录和计划都会在这里持续沉淀。</p>
            </div>
            <div class="section-actions">
                <a class="link-btn link-ghost" href="index.jsp">返回官网</a>
                <a class="link-btn link-ghost" href="resources.jsp">资源中心</a>
                <a class="link-btn link-ghost" href="blz.jsp">AI 陪伴</a>
                <% if ("admin".equals(workspaceUsername)) { %>
                <a class="link-btn link-ghost" href="admin.jsp">管理页</a>
                <% } %>
                <a class="link-btn link-primary" href="logout.jsp">退出登录</a>
            </div>
        </div>

        <div class="workspace-stats">
            <div class="metric-card warm">
                <span>已完成计划</span>
                <strong data-completed-count>0</strong>
                <p>把恢复拆成可以完成的小动作。</p>
            </div>
            <div class="metric-card cool">
                <span>情绪签到次数</span>
                <strong data-mood-count>0</strong>
                <p>不是为了打卡，而是为了更了解自己。</p>
            </div>
            <div class="metric-card purple">
                <span>记录状态</span>
                <strong data-journal-state>尚未保存记录</strong>
                <p>一段文字，也可以成为照顾自己的开始。</p>
            </div>
        </div>
    </section>

    <main class="workspace-main">
        <div class="workspace-grid">
            <section class="workspace-card">
                <header>
                    <div>
                        <div class="section-label">Step 01</div>
                        <h3>今日情绪签到</h3>
                    </div>
                </header>
                <p data-mood-status>今天还没有签到，先选一个最接近你状态的词。</p>
                <div class="mood-grid">
                    <button class="mood-btn" type="button" data-mood="calm" data-label="平静">平静</button>
                    <button class="mood-btn" type="button" data-mood="tired" data-label="疲惫">疲惫</button>
                    <button class="mood-btn" type="button" data-mood="anxious" data-label="焦虑">焦虑</button>
                    <button class="mood-btn" type="button" data-mood="low" data-label="低落">低落</button>
                    <button class="mood-btn" type="button" data-mood="hopeful" data-label="有希望">有希望</button>
                </div>
            </section>

            <section class="workspace-card">
                <header>
                    <div>
                        <div class="section-label">Step 02</div>
                        <h3>1 分钟呼吸练习</h3>
                    </div>
                </header>
                <div class="breathing-box">
                    <div class="breathing-ring" data-breathing-time>60</div>
                    <div>
                        <p data-breathing-hint>吸气 4 秒、停住 2 秒、呼气 4 秒，跟着节奏慢下来。</p>
                        <button class="btn btn-primary" type="button" data-breathing-start>开始练习</button>
                    </div>
                </div>
            </section>

            <section class="workspace-card">
                <header>
                    <div>
                        <div class="section-label">Step 03</div>
                        <h3>疗愈记录</h3>
                    </div>
                </header>
                <label class="field">
                    <span>今天最需要被照顾的一件事</span>
                    <textarea data-journal-input placeholder="例如：我今天很累，但我愿意先让自己休息 15 分钟。"></textarea>
                </label>
                <div class="journal-meta">
                    <span data-journal-time>还没有保存记录</span>
                    <button class="btn btn-secondary" type="button" data-journal-save>保存记录</button>
                </div>
            </section>

            <section class="workspace-card">
                <header>
                    <div>
                        <div class="section-label">Step 04</div>
                        <h3>今日支持计划</h3>
                    </div>
                </header>
                <div class="plan-input-row">
                    <input type="text" data-plan-input placeholder="添加一个今天能做到的小计划">
                    <button class="btn btn-primary" type="button" data-plan-add>添加</button>
                </div>
                <ul class="plan-list" data-plan-list></ul>
            </section>

            <section class="workspace-card">
                <header>
                    <div>
                        <div class="section-label">支持提示</div>
                        <h3>给自己的提醒</h3>
                    </div>
                </header>
                <div class="support-note">
                    疗愈更像节奏调整和持续照顾，而不是一次性完成所有任务。你不需要一口气做很多，只需要今天愿意开始一点点。
                </div>
            </section>

            <section class="workspace-card">
                <header>
                    <div>
                        <div class="section-label">快捷入口</div>
                        <h3>继续浏览其他模块</h3>
                    </div>
                </header>
                <div class="resource-list">
                    <a class="resource-chip" href="programs.jsp">
                        <span>查看疗愈方案</span>
                        <span class="soft-label">功能模块说明</span>
                    </a>
                    <a class="resource-chip" href="resources.jsp">
                        <span>查看资源中心</span>
                        <span class="soft-label">FAQ 与危机支持</span>
                    </a>
                    <a class="resource-chip" href="blz.jsp">
                        <span>打开 AI 陪伴</span>
                        <span class="soft-label">会话可继续保存</span>
                    </a>
                </div>
            </section>
        </div>
    </main>
</div>
