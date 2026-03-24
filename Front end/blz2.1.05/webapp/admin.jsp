<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
    import="java.sql.*" %>
<%@ include file="WEB-INF/jspf/user-store.jspf" %>
<%
request.setCharacterEncoding("UTF-8");

if (!Boolean.TRUE.equals(session.getAttribute("loggedIn"))) {
    response.sendRedirect("login.jsp");
    return;
}

String username = String.valueOf(session.getAttribute("username"));
if (!"admin".equals(username)) {
    response.sendRedirect("dashboard.jsp");
    return;
}

String currentPage = "";
Connection connection = null;
Statement statement = null;
ResultSet usersResult = null;
ResultSet workspaceResult = null;
ResultSet conversationsResult = null;
long userCount = 0L;
long conversationCount = 0L;
long messageCount = 0L;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>心晴疗愈 | 管理页</title>
    <link rel="stylesheet" href="assets/css/site.css">
</head>
<body>
    <div class="page-shell">
        <%@ include file="WEB-INF/jspf/public-nav.jspf" %>
        <main class="section">
            <div class="container">
                <div class="section-head">
                    <div class="section-label">Admin</div>
                    <h1>数据查看页</h1>
                    <p class="section-subtitle">这个页面用于快速查看当前项目里的用户、工作台和 AI 会话数据。</p>
                </div>

                <%
                try {
                    connection = openConnection(application);
                    statement = connection.createStatement();

                    ResultSet countResult = statement.executeQuery("SELECT COUNT(*) AS total FROM users");
                    if (countResult.next()) {
                        userCount = countResult.getLong("total");
                    }
                    countResult.close();

                    countResult = statement.executeQuery("SELECT COUNT(*) AS total FROM conversations");
                    if (countResult.next()) {
                        conversationCount = countResult.getLong("total");
                    }
                    countResult.close();

                    countResult = statement.executeQuery("SELECT COUNT(*) AS total FROM messages");
                    if (countResult.next()) {
                        messageCount = countResult.getLong("total");
                    }
                    countResult.close();
                %>

                <div class="grid-3">
                    <article class="metric-card warm">
                        <span>用户数</span>
                        <strong><%= userCount %></strong>
                        <p>当前注册用户总数</p>
                    </article>
                    <article class="metric-card cool">
                        <span>会话数</span>
                        <strong><%= conversationCount %></strong>
                        <p>AI 会话总数</p>
                    </article>
                    <article class="metric-card purple">
                        <span>消息数</span>
                        <strong><%= messageCount %></strong>
                        <p>消息记录总数</p>
                    </article>
                </div>

                <section class="section">
                    <div class="panel-card">
                        <div class="section-label">Users</div>
                        <h2>最近用户</h2>
                        <div class="table-shell">
                            <table class="admin-table">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>用户名</th>
                                        <th>展示名</th>
                                        <th>状态</th>
                                        <th>创建时间</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                    usersResult = statement.executeQuery("SELECT id, username, display_name, status, created_at FROM users ORDER BY id DESC LIMIT 20");
                                    while (usersResult.next()) {
                                    %>
                                    <tr>
                                        <td><%= usersResult.getLong("id") %></td>
                                        <td><%= usersResult.getString("username") %></td>
                                        <td><%= usersResult.getString("display_name") %></td>
                                        <td><%= usersResult.getString("status") %></td>
                                        <td><%= usersResult.getTimestamp("created_at") %></td>
                                    </tr>
                                    <%
                                    }
                                    usersResult.close();
                                    usersResult = null;
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </section>

                <section class="section">
                    <div class="panel-card">
                        <div class="section-label">Workspace</div>
                        <h2>最近工作台数据</h2>
                        <div class="table-shell">
                            <table class="admin-table">
                                <thead>
                                    <tr>
                                        <th>User ID</th>
                                        <th>情绪</th>
                                        <th>签到次数</th>
                                        <th>最近保存</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                    workspaceResult = statement.executeQuery("SELECT user_id, mood_label, mood_count, journal_saved_at FROM workspace_state ORDER BY updated_at DESC LIMIT 20");
                                    while (workspaceResult.next()) {
                                    %>
                                    <tr>
                                        <td><%= workspaceResult.getLong("user_id") %></td>
                                        <td><%= workspaceResult.getString("mood_label") %></td>
                                        <td><%= workspaceResult.getInt("mood_count") %></td>
                                        <td><%= workspaceResult.getString("journal_saved_at") %></td>
                                    </tr>
                                    <%
                                    }
                                    workspaceResult.close();
                                    workspaceResult = null;
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </section>

                <section class="section">
                    <div class="panel-card">
                        <div class="section-label">AI</div>
                        <h2>最近会话</h2>
                        <div class="table-shell">
                            <table class="admin-table">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>User ID</th>
                                        <th>标题</th>
                                        <th>状态</th>
                                        <th>更新时间</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                    conversationsResult = statement.executeQuery("SELECT id, user_id, title, status, updated_at FROM conversations ORDER BY updated_at DESC LIMIT 20");
                                    while (conversationsResult.next()) {
                                    %>
                                    <tr>
                                        <td><%= conversationsResult.getLong("id") %></td>
                                        <td><%= conversationsResult.getLong("user_id") %></td>
                                        <td><%= conversationsResult.getString("title") %></td>
                                        <td><%= conversationsResult.getString("status") %></td>
                                        <td><%= conversationsResult.getTimestamp("updated_at") %></td>
                                    </tr>
                                    <%
                                    }
                                    conversationsResult.close();
                                    conversationsResult = null;
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </section>

                <%
                } catch (Exception ex) {
                    application.log("Failed to render admin dashboard.", ex);
                %>
                <div class="message-box error">管理页加载失败，请检查数据库连接。</div>
                <%
                } finally {
                    if (usersResult != null) try { usersResult.close(); } catch (SQLException ignore) {}
                    if (workspaceResult != null) try { workspaceResult.close(); } catch (SQLException ignore) {}
                    if (conversationsResult != null) try { conversationsResult.close(); } catch (SQLException ignore) {}
                    if (statement != null) try { statement.close(); } catch (SQLException ignore) {}
                    if (connection != null) try { connection.close(); } catch (SQLException ignore) {}
                }
                %>
            </div>
        </main>
        <%@ include file="WEB-INF/jspf/public-footer.jspf" %>
    </div>
</body>
</html>
