<%
String errorMessageView = (String) request.getAttribute("errorMessage");
String successMessageView = (String) request.getAttribute("successMessage");
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
                        <small>会员工作台入口</small>
                    </span>
                </div>
                <a class="link-btn link-ghost" href="index.jsp">返回官网</a>
            </div>

            <div class="eyebrow">Member Access</div>
            <h1>登录后，进入你的个人疗愈工作台。</h1>
            <p>
                这一版已经把账号能力切到数据库。登录之后，工作台数据和 AI 会话都会继续走后端持久化。
            </p>

            <ul class="support-list">
                <li>支持真实注册与登录</li>
                <li>未登录不能直接进入工作台</li>
                <li>默认演示账号会自动初始化</li>
            </ul>
        </section>

        <section class="auth-card">
            <div class="section-label">Secure Login</div>
            <h1>欢迎回来</h1>
            <p>输入账号密码，继续你的疗愈计划。</p>

            <div class="auth-note">
                默认账号：<strong>demo</strong> / <strong>demo123</strong><br>
                管理账号：<strong>admin</strong> / <strong>123456</strong>
            </div>

            <% if (successMessageView != null) { %>
            <div class="message-box success"><%= successMessageView %></div>
            <% } %>

            <% if (errorMessageView != null) { %>
            <div class="message-box error"><%= errorMessageView %></div>
            <% } %>

            <form method="post" action="login.jsp" class="form-stack">
                <label class="field">
                    <span>用户名</span>
                    <input type="text" name="username" value="<%= usernameValueView == null ? "" : usernameValueView %>" placeholder="请输入用户名" required>
                </label>

                <label class="field">
                    <span>密码</span>
                    <input type="password" name="password" placeholder="请输入密码" required>
                </label>

                <button class="btn btn-primary" type="submit">登录进入</button>
                <a class="link-btn link-ghost" href="register.jsp">还没有账号？去注册</a>
            </form>
        </section>
    </div>
</div>
