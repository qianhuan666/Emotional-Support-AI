<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"
    import="java.sql.*,java.util.*" %>
<%@ include file="../WEB-INF/jspf/user-store.jspf" %>
<%!
    private static String escapeJson(String value) {
        if (value == null) {
            return "";
        }

        StringBuilder builder = new StringBuilder(value.length() + 16);
        for (int i = 0; i < value.length(); i += 1) {
            char ch = value.charAt(i);
            switch (ch) {
                case '\\': builder.append("\\\\"); break;
                case '"': builder.append("\\\""); break;
                case '\b': builder.append("\\b"); break;
                case '\f': builder.append("\\f"); break;
                case '\n': builder.append("\\n"); break;
                case '\r': builder.append("\\r"); break;
                case '\t': builder.append("\\t"); break;
                default:
                    if (ch < 32) {
                        builder.append(String.format("\\u%04x", (int) ch));
                    } else {
                        builder.append(ch);
                    }
            }
        }
        return builder.toString();
    }

    private void ensureWorkspaceStateTable(Connection connection) throws SQLException {
        Statement statement = null;
        try {
            statement = connection.createStatement();
            statement.execute(
                "CREATE TABLE IF NOT EXISTS workspace_state (" +
                " user_id BIGINT PRIMARY KEY," +
                " mood_value VARCHAR(32) NULL," +
                " mood_label VARCHAR(64) NULL," +
                " mood_count INT NOT NULL DEFAULT 0," +
                " journal_content MEDIUMTEXT NULL," +
                " journal_saved_at VARCHAR(64) NULL," +
                " plan_json LONGTEXT NULL," +
                " updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
                " CONSTRAINT fk_workspace_state_user_id FOREIGN KEY (user_id) REFERENCES users(id)" +
                ")"
            );
        } finally {
            if (statement != null) {
                statement.close();
            }
        }
    }

    private Long findUserId(ServletContext application, String username) throws SQLException, ClassNotFoundException {
        ensureDatabaseReady(application);

        Connection connection = null;
        PreparedStatement statement = null;
        ResultSet resultSet = null;

        try {
            connection = openConnection(application);
            statement = connection.prepareStatement("SELECT id FROM users WHERE username = ?");
            statement.setString(1, username);
            resultSet = statement.executeQuery();
            return resultSet.next() ? Long.valueOf(resultSet.getLong("id")) : null;
        } finally {
            if (resultSet != null) {
                resultSet.close();
            }
            if (statement != null) {
                statement.close();
            }
            if (connection != null) {
                connection.close();
            }
        }
    }

    private String buildWorkspaceStateJson(
        String moodValue,
        String moodLabel,
        int moodCount,
        String journalContent,
        String journalSavedAt,
        String planJson
    ) {
        String safePlanJson = (planJson != null && planJson.trim().startsWith("[")) ? planJson.trim() : "[]";
        return "{"
            + "\"moodValue\":\"" + escapeJson(moodValue) + "\","
            + "\"moodLabel\":\"" + escapeJson(moodLabel) + "\","
            + "\"moodCount\":" + moodCount + ","
            + "\"journalContent\":\"" + escapeJson(journalContent) + "\","
            + "\"journalSavedAt\":\"" + escapeJson(journalSavedAt) + "\","
            + "\"planItems\":" + safePlanJson
            + "}";
    }
%>
<%
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");
response.setContentType("application/json; charset=UTF-8");

if (!Boolean.TRUE.equals(session.getAttribute("loggedIn"))) {
    response.setStatus(401);
    response.getWriter().write("{\"error\":\"unauthorized\"}");
    return;
}

String username = String.valueOf(session.getAttribute("username"));
Long userId = null;

try {
    userId = findUserId(application, username);
} catch (Exception ex) {
    application.log("Failed to resolve workspace user.", ex);
}

if (userId == null) {
    response.setStatus(404);
    response.getWriter().write("{\"error\":\"user_not_found\"}");
    return;
}

if ("POST".equalsIgnoreCase(request.getMethod())) {
    String moodValue = request.getParameter("moodValue");
    String moodLabel = request.getParameter("moodLabel");
    String journalContent = request.getParameter("journalContent");
    String journalSavedAt = request.getParameter("journalSavedAt");
    String planJson = request.getParameter("planItemsJson");
    String moodCountRaw = request.getParameter("moodCount");
    int moodCountValue = 0;

    try {
        moodCountValue = Integer.parseInt(moodCountRaw == null ? "0" : moodCountRaw.trim());
    } catch (NumberFormatException ignore) {
        moodCountValue = 0;
    }

    Connection connection = null;
    PreparedStatement statement = null;

    try {
        connection = openConnection(application);
        ensureWorkspaceStateTable(connection);
        statement = connection.prepareStatement(
            "INSERT INTO workspace_state (user_id, mood_value, mood_label, mood_count, journal_content, journal_saved_at, plan_json) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?) " +
            "ON DUPLICATE KEY UPDATE " +
            "mood_value = VALUES(mood_value), " +
            "mood_label = VALUES(mood_label), " +
            "mood_count = VALUES(mood_count), " +
            "journal_content = VALUES(journal_content), " +
            "journal_saved_at = VALUES(journal_saved_at), " +
            "plan_json = VALUES(plan_json)"
        );
        statement.setLong(1, userId.longValue());
        statement.setString(2, moodValue);
        statement.setString(3, moodLabel);
        statement.setInt(4, moodCountValue);
        statement.setString(5, journalContent);
        statement.setString(6, journalSavedAt);
        statement.setString(7, planJson == null ? "[]" : planJson);
        statement.executeUpdate();
        response.getWriter().write("{\"ok\":true}");
    } catch (Exception ex) {
        application.log("Failed to save workspace state.", ex);
        response.setStatus(500);
        response.getWriter().write("{\"error\":\"save_failed\"}");
    } finally {
        if (statement != null) {
            statement.close();
        }
        if (connection != null) {
            connection.close();
        }
    }

    return;
}

Connection connection = null;
PreparedStatement statement = null;
ResultSet resultSet = null;

try {
    connection = openConnection(application);
    ensureWorkspaceStateTable(connection);
    statement = connection.prepareStatement(
        "SELECT mood_value, mood_label, mood_count, journal_content, journal_saved_at, plan_json " +
        "FROM workspace_state WHERE user_id = ?"
    );
    statement.setLong(1, userId.longValue());
    resultSet = statement.executeQuery();

    if (resultSet.next()) {
        response.getWriter().write(
            buildWorkspaceStateJson(
                resultSet.getString("mood_value"),
                resultSet.getString("mood_label"),
                resultSet.getInt("mood_count"),
                resultSet.getString("journal_content"),
                resultSet.getString("journal_saved_at"),
                resultSet.getString("plan_json")
            )
        );
    } else {
        response.getWriter().write(buildWorkspaceStateJson("", "", 0, "", "", "[]"));
    }
} catch (Exception ex) {
    application.log("Failed to load workspace state.", ex);
    response.setStatus(500);
    response.getWriter().write("{\"error\":\"load_failed\"}");
} finally {
    if (resultSet != null) {
        resultSet.close();
    }
    if (statement != null) {
        statement.close();
    }
    if (connection != null) {
        connection.close();
    }
}
%>
