<%
String errorMessageView = (String) request.getAttribute("errorMessage");
String usernameValueView = (String) request.getAttribute("usernameValue");
%>
<div class="auth-shell">
    <div class="auth-grid">
        <section class="auth-panel">
            <div class="auth-topbar">
                <div class="brand">
                    <span class="brand-mark">心</span>
                    <span class="brand-copy">
                        <span>心晴疗愈</span>
                        <small>创建你的疗愈空间</small>
                    </span>
                </div>
                <a class="link-btn link-ghost" href="index.jsp">返回官网</a>
            </div>

            <div class="eyebrow">Create Account</div>
            <h1>从注册开始，给自己一个可持续回来的地方。</h1>
            <p>
                注册后，你就能进入工作台、保存个人记录，并继续使用后续接入的大模型陪伴能力。
            </p>

            <ul class="support-list">
                <li>用户名支持字母、数字和下划线</li>
                <li>密码至少 6 位</li>
                <li>注册成功后即可直接登录</li>
            </ul>
        </section>

        <section class="auth-card">
            <div class="section-label">Register</div>
            <h1>创建账号</h1>
            <p>填写基础信息，生成你的专属入口。</p>

            <% if (errorMessageView != null) { %>
            <div class="message-box error"><%= errorMessageView %></div>
            <% } %>

            <form method="post" action="register.jsp" class="form-stack">
                <label class="field">
                    <span>用户名</span>
                    <input type="text" name="username" value="<%= usernameValueView == null ? "" : usernameValueView %>" placeholder="例如：mood_user" required>
                </label>

                <label class="field">
                    <span>密码</span>
                    <input type="password" name="password" placeholder="至少 6 个字符" required>
                </label>

                <label class="field">
                    <span>确认密码</span>
                    <input type="password" name="confirmPassword" placeholder="再次输入密码" required>
                </label>

                <button class="btn btn-primary" type="submit">完成注册</button>
                <a class="link-btn link-ghost" href="login.jsp">已有账号？返回登录</a>
            </form>
        </section>
    </div>
</div>
