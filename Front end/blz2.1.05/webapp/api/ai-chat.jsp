<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"
         import="java.io.InputStream,java.io.OutputStream,java.io.IOException,java.net.HttpURLConnection,java.net.URL,java.nio.charset.StandardCharsets"%>
<%@ include file="../WEB-INF/jspf/user-store.jspf" %>
<%!
    private static final int API_TIMEOUT = 60000;

    private static String readConfig(ServletContext application, String envKey, String initParamKey) {
        String value = System.getenv(envKey);
        if (value != null && !value.trim().isEmpty()) {
            return value.trim();
        }

        value = application.getInitParameter(initParamKey);
        if (value != null && !value.trim().isEmpty()) {
            return value.trim();
        }

        return null;
    }

    private static String jsonEscape(String value) {
        if (value == null) return "";
        StringBuilder sb = new StringBuilder(value.length() + 16);
        for (int i = 0; i < value.length(); i += 1) {
            char ch = value.charAt(i);
            switch (ch) {
                case '\\': sb.append("\\\\"); break;
                case '"': sb.append("\\\""); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (ch < 32) {
                        sb.append(String.format("\\u%04x", (int) ch));
                    } else {
                        sb.append(ch);
                    }
            }
        }
        return sb.toString();
    }

    private static String pipeAndCollect(InputStream input, OutputStream output) throws IOException {
        byte[] buffer = new byte[8192];
        int len;
        java.io.ByteArrayOutputStream copy = new java.io.ByteArrayOutputStream();
        while ((len = input.read(buffer)) != -1) {
            output.write(buffer, 0, len);
            output.flush();
            copy.write(buffer, 0, len);
        }
        return copy.toString("UTF-8");
    }

    private static String decodeJsonString(String value) {
        if (value == null) {
            return "";
        }

        StringBuilder builder = new StringBuilder(value.length());
        boolean escaping = false;

        for (int i = 0; i < value.length(); i += 1) {
            char ch = value.charAt(i);

            if (!escaping) {
                if (ch == '\\') {
                    escaping = true;
                } else {
                    builder.append(ch);
                }
                continue;
            }

            switch (ch) {
                case '"': builder.append('"'); break;
                case '\\': builder.append('\\'); break;
                case '/': builder.append('/'); break;
                case 'b': builder.append('\b'); break;
                case 'f': builder.append('\f'); break;
                case 'n': builder.append('\n'); break;
                case 'r': builder.append('\r'); break;
                case 't': builder.append('\t'); break;
                case 'u':
                    if (i + 4 < value.length()) {
                        String hex = value.substring(i + 1, i + 5);
                        builder.append((char) Integer.parseInt(hex, 16));
                        i += 4;
                    }
                    break;
                default:
                    builder.append(ch);
            }

            escaping = false;
        }

        return builder.toString();
    }

    private static String extractAssistantContent(String ssePayload) {
        if (ssePayload == null || ssePayload.trim().isEmpty()) {
            return "";
        }

        StringBuilder builder = new StringBuilder();
        String[] lines = ssePayload.split("\\r?\\n");

        for (int i = 0; i < lines.length; i += 1) {
            String line = lines[i] == null ? "" : lines[i].trim();
            if (!line.startsWith("data:")) {
                continue;
            }

            String data = line.substring(5).trim();
            if (data.isEmpty() || "[DONE]".equals(data)) {
                continue;
            }

            int index = 0;
            while (index >= 0 && index < data.length()) {
                index = data.indexOf("\"content\":\"", index);
                if (index < 0) {
                    break;
                }

                index += 11;
                StringBuilder token = new StringBuilder();
                boolean escaping = false;

                while (index < data.length()) {
                    char ch = data.charAt(index);
                    if (!escaping && ch == '"') {
                        break;
                    }
                    if (ch == '\\' && !escaping) {
                        escaping = true;
                        token.append(ch);
                    } else {
                        escaping = false;
                        token.append(ch);
                    }
                    index += 1;
                }

                builder.append(decodeJsonString(token.toString()));
                index += 1;
            }
        }

        return builder.toString().trim();
    }

    private Long findChatUserId(ServletContext application, String username) throws SQLException, ClassNotFoundException {
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
            if (resultSet != null) resultSet.close();
            if (statement != null) statement.close();
            if (connection != null) connection.close();
        }
    }

    private void ensureChatTables(Connection connection) throws SQLException {
        Statement statement = null;
        try {
            statement = connection.createStatement();
            statement.execute(
                "CREATE TABLE IF NOT EXISTS conversations (" +
                " id BIGINT PRIMARY KEY AUTO_INCREMENT," +
                " user_id BIGINT NOT NULL," +
                " title VARCHAR(200) NOT NULL," +
                " conversation_type VARCHAR(32) NOT NULL DEFAULT 'AI_CHAT'," +
                " status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE'," +
                " created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                " updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
                " CONSTRAINT fk_conversations_user_id FOREIGN KEY (user_id) REFERENCES users(id)" +
                ")"
            );
            statement.execute(
                "CREATE TABLE IF NOT EXISTS messages (" +
                " id BIGINT PRIMARY KEY AUTO_INCREMENT," +
                " conversation_id BIGINT NOT NULL," +
                " user_id BIGINT NULL," +
                " role VARCHAR(16) NOT NULL," +
                " content MEDIUMTEXT NOT NULL," +
                " content_type VARCHAR(32) NOT NULL DEFAULT 'TEXT'," +
                " provider_message_id VARCHAR(128) NULL," +
                " created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                " CONSTRAINT fk_messages_conversation_id FOREIGN KEY (conversation_id) REFERENCES conversations(id)," +
                " CONSTRAINT fk_messages_user_id FOREIGN KEY (user_id) REFERENCES users(id)" +
                ")"
            );
            statement.execute(
                "CREATE TABLE IF NOT EXISTS model_call_logs (" +
                " id BIGINT PRIMARY KEY AUTO_INCREMENT," +
                " conversation_id BIGINT NULL," +
                " message_id BIGINT NULL," +
                " provider VARCHAR(32) NOT NULL," +
                " model VARCHAR(64) NOT NULL," +
                " request_status VARCHAR(16) NOT NULL," +
                " request_latency_ms INT NULL," +
                " prompt_tokens INT NULL," +
                " completion_tokens INT NULL," +
                " error_message VARCHAR(500) NULL," +
                " created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                " CONSTRAINT fk_model_logs_conversation_id FOREIGN KEY (conversation_id) REFERENCES conversations(id)," +
                " CONSTRAINT fk_model_logs_message_id FOREIGN KEY (message_id) REFERENCES messages(id)" +
                ")"
            );
        } finally {
            if (statement != null) statement.close();
        }
    }

    private Long parseConversationId(String value) {
        try {
            return (value == null || value.trim().isEmpty()) ? null : Long.valueOf(Long.parseLong(value.trim()));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private Long findOwnedConversation(Connection connection, long userId, Long conversationId) throws SQLException {
        if (conversationId == null) {
            return null;
        }

        PreparedStatement statement = null;
        ResultSet resultSet = null;

        try {
            statement = connection.prepareStatement(
                "SELECT id FROM conversations WHERE id = ? AND user_id = ? AND status = 'ACTIVE'"
            );
            statement.setLong(1, conversationId.longValue());
            statement.setLong(2, userId);
            resultSet = statement.executeQuery();
            return resultSet.next() ? Long.valueOf(resultSet.getLong("id")) : null;
        } finally {
            if (resultSet != null) resultSet.close();
            if (statement != null) statement.close();
        }
    }

    private Long createConversation(Connection connection, long userId, String prompt) throws SQLException {
        PreparedStatement statement = null;
        ResultSet keys = null;

        try {
            statement = connection.prepareStatement(
                "INSERT INTO conversations (user_id, title, conversation_type, status) VALUES (?, ?, 'AI_CHAT', 'ACTIVE')",
                Statement.RETURN_GENERATED_KEYS
            );
            String title = (prompt == null || prompt.trim().isEmpty()) ? "新的 AI 对话" : prompt.trim();
            if (title.length() > 60) {
                title = title.substring(0, 60);
            }
            statement.setLong(1, userId);
            statement.setString(2, title);
            statement.executeUpdate();
            keys = statement.getGeneratedKeys();
            return keys.next() ? Long.valueOf(keys.getLong(1)) : null;
        } finally {
            if (keys != null) keys.close();
            if (statement != null) statement.close();
        }
    }

    private Long insertMessage(Connection connection, Long conversationId, Long userId, String role, String content) throws SQLException {
        PreparedStatement statement = null;
        ResultSet keys = null;

        try {
            statement = connection.prepareStatement(
                "INSERT INTO messages (conversation_id, user_id, role, content, content_type) VALUES (?, ?, ?, ?, 'TEXT')",
                Statement.RETURN_GENERATED_KEYS
            );
            statement.setLong(1, conversationId.longValue());
            if (userId == null) {
                statement.setNull(2, Types.BIGINT);
            } else {
                statement.setLong(2, userId.longValue());
            }
            statement.setString(3, role);
            statement.setString(4, content == null ? "" : content);
            statement.executeUpdate();
            keys = statement.getGeneratedKeys();
            return keys.next() ? Long.valueOf(keys.getLong(1)) : null;
        } finally {
            if (keys != null) keys.close();
            if (statement != null) statement.close();
        }
    }

    private void insertModelLog(Connection connection, Long conversationId, Long messageId, String model, String status, long latencyMs, String errorMessage) throws SQLException {
        PreparedStatement statement = null;
        try {
            statement = connection.prepareStatement(
                "INSERT INTO model_call_logs (conversation_id, message_id, provider, model, request_status, request_latency_ms, error_message) " +
                "VALUES (?, ?, 'OPENAI', ?, ?, ?, ?)"
            );
            if (conversationId == null) {
                statement.setNull(1, Types.BIGINT);
            } else {
                statement.setLong(1, conversationId.longValue());
            }
            if (messageId == null) {
                statement.setNull(2, Types.BIGINT);
            } else {
                statement.setLong(2, messageId.longValue());
            }
            statement.setString(3, model == null ? "" : model);
            statement.setString(4, status);
            statement.setInt(5, (int) latencyMs);
            statement.setString(6, errorMessage);
            statement.executeUpdate();
        } finally {
            if (statement != null) statement.close();
        }
    }

    private String buildConversationListJson(Connection connection, long userId) throws SQLException {
        PreparedStatement statement = null;
        ResultSet resultSet = null;
        StringBuilder json = new StringBuilder();

        try {
            statement = connection.prepareStatement(
                "SELECT id, title, updated_at FROM conversations WHERE user_id = ? AND status = 'ACTIVE' ORDER BY updated_at DESC, id DESC"
            );
            statement.setLong(1, userId);
            resultSet = statement.executeQuery();

            json.append("{\"conversations\":[");
            boolean first = true;
            while (resultSet.next()) {
                if (!first) {
                    json.append(',');
                }
                first = false;
                json.append("{\"id\":")
                    .append(resultSet.getLong("id"))
                    .append(",\"title\":\"")
                    .append(jsonEscape(resultSet.getString("title")))
                    .append("\",\"updatedAt\":\"")
                    .append(jsonEscape(String.valueOf(resultSet.getTimestamp("updated_at"))))
                    .append("\"}");
            }
            json.append("]}");
            return json.toString();
        } finally {
            if (resultSet != null) resultSet.close();
            if (statement != null) statement.close();
        }
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    String apiEndpoint = readConfig(application, "APP_AI_ENDPOINT", "app.ai.endpoint");
    String apiModel = readConfig(application, "APP_AI_MODEL", "app.ai.model");
    String apiKey = readConfig(application, "APP_AI_KEY", "app.ai.key");
    String currentUsername = Boolean.TRUE.equals(session.getAttribute("loggedIn")) ? String.valueOf(session.getAttribute("username")) : null;

    if ("GET".equalsIgnoreCase(request.getMethod()) && "list".equals(request.getParameter("action"))) {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");

        if (currentUsername == null) {
            response.setStatus(401);
            response.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        Connection connection = null;
        try {
            Long chatUserId = findChatUserId(application, currentUsername);
            if (chatUserId == null) {
                response.getWriter().write("{\"conversations\":[]}");
                return;
            }

            connection = openConnection(application);
            ensureChatTables(connection);
            response.getWriter().write(buildConversationListJson(connection, chatUserId.longValue()));
        } catch (Exception ex) {
            application.log("Failed to list conversations.", ex);
            response.setStatus(500);
            response.getWriter().write("{\"error\":\"list_failed\"}");
        } finally {
            if (connection != null) try { connection.close(); } catch (SQLException ignore) {}
        }
        return;
    }

    if ("GET".equalsIgnoreCase(request.getMethod()) && "history".equals(request.getParameter("action"))) {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");

        if (currentUsername == null) {
            response.setStatus(401);
            response.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        Connection historyConnection = null;
        PreparedStatement conversationStatement = null;
        PreparedStatement messagesStatement = null;
        ResultSet conversationResult = null;
        ResultSet messagesResult = null;
        Long requestedConversationId = parseConversationId(request.getParameter("conversationId"));

        try {
            Long chatUserId = findChatUserId(application, currentUsername);
            if (chatUserId == null) {
                response.getWriter().write("{\"conversationId\":null,\"messages\":[]}");
                return;
            }

            historyConnection = openConnection(application);
            ensureChatTables(historyConnection);
            if (requestedConversationId != null) {
                conversationStatement = historyConnection.prepareStatement(
                    "SELECT id FROM conversations WHERE id = ? AND user_id = ? AND status = 'ACTIVE'"
                );
                conversationStatement.setLong(1, requestedConversationId.longValue());
                conversationStatement.setLong(2, chatUserId.longValue());
            } else {
                conversationStatement = historyConnection.prepareStatement(
                    "SELECT id FROM conversations WHERE user_id = ? AND status = 'ACTIVE' ORDER BY updated_at DESC, id DESC LIMIT 1"
                );
                conversationStatement.setLong(1, chatUserId.longValue());
            }
            conversationResult = conversationStatement.executeQuery();

            if (!conversationResult.next()) {
                response.getWriter().write("{\"conversationId\":null,\"messages\":[]}");
                return;
            }

            long conversationId = conversationResult.getLong("id");
            messagesStatement = historyConnection.prepareStatement(
                "SELECT role, content FROM messages WHERE conversation_id = ? ORDER BY id ASC"
            );
            messagesStatement.setLong(1, conversationId);
            messagesResult = messagesStatement.executeQuery();

            StringBuilder json = new StringBuilder();
            json.append("{\"conversationId\":").append(conversationId).append(",\"messages\":[");
            boolean firstMessage = true;
            while (messagesResult.next()) {
                if (!firstMessage) {
                    json.append(',');
                }
                firstMessage = false;
                json.append("{\"role\":\"")
                    .append(jsonEscape(messagesResult.getString("role")))
                    .append("\",\"content\":\"")
                    .append(jsonEscape(messagesResult.getString("content")))
                    .append("\"}");
            }
            json.append("]}");
            response.getWriter().write(json.toString());
        } catch (Exception ex) {
            application.log("Failed to load AI chat history.", ex);
            response.setStatus(500);
            response.getWriter().write("{\"error\":\"history_failed\"}");
        } finally {
            if (messagesResult != null) try { messagesResult.close(); } catch (SQLException ignore) {}
            if (conversationResult != null) try { conversationResult.close(); } catch (SQLException ignore) {}
            if (messagesStatement != null) try { messagesStatement.close(); } catch (SQLException ignore) {}
            if (conversationStatement != null) try { conversationStatement.close(); } catch (SQLException ignore) {}
            if (historyConnection != null) try { historyConnection.close(); } catch (SQLException ignore) {}
        }
        return;
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "delete".equals(request.getParameter("action"))) {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");

        if (currentUsername == null) {
            response.setStatus(401);
            response.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        Connection connection = null;
        PreparedStatement statement = null;

        try {
            Long chatUserId = findChatUserId(application, currentUsername);
            Long conversationId = parseConversationId(request.getParameter("conversationId"));
            if (chatUserId == null || conversationId == null) {
                response.setStatus(400);
                response.getWriter().write("{\"error\":\"bad_request\"}");
                return;
            }

            connection = openConnection(application);
            ensureChatTables(connection);
            statement = connection.prepareStatement(
                "UPDATE conversations SET status = 'ARCHIVED' WHERE id = ? AND user_id = ?"
            );
            statement.setLong(1, conversationId.longValue());
            statement.setLong(2, chatUserId.longValue());
            statement.executeUpdate();
            response.getWriter().write("{\"ok\":true}");
        } catch (Exception ex) {
            application.log("Failed to delete conversation.", ex);
            response.setStatus(500);
            response.getWriter().write("{\"error\":\"delete_failed\"}");
        } finally {
            if (statement != null) try { statement.close(); } catch (SQLException ignore) {}
            if (connection != null) try { connection.close(); } catch (SQLException ignore) {}
        }
        return;
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "chat".equals(request.getParameter("action"))) {
        String messagesJson = request.getParameter("messages");
        String prompt = request.getParameter("prompt");
        Long requestedConversationId = parseConversationId(request.getParameter("conversationId"));
        if (messagesJson == null || messagesJson.trim().isEmpty()) {
            response.setStatus(400);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("messages is required");
            return;
        }
        if (apiEndpoint == null || apiModel == null || apiKey == null) {
            response.setStatus(500);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("AI configuration missing. Set APP_AI_ENDPOINT, APP_AI_MODEL and APP_AI_KEY first.");
            return;
        }

        if (currentUsername == null) {
            response.setStatus(401);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("login required");
            return;
        }

        HttpURLConnection connection = null;
        InputStream upstream = null;
        Connection dbConnection = null;
        Long conversationId = null;
        Long userMessageId = null;
        long startedAt = System.currentTimeMillis();
        try {
            Long chatUserId = findChatUserId(application, currentUsername);
            if (chatUserId == null) {
                response.setStatus(404);
                response.setContentType("text/plain; charset=UTF-8");
                response.getWriter().write("user not found");
                return;
            }

            dbConnection = openConnection(application);
            ensureChatTables(dbConnection);
            conversationId = findOwnedConversation(dbConnection, chatUserId.longValue(), requestedConversationId);
            if (conversationId == null) {
                conversationId = createConversation(dbConnection, chatUserId.longValue(), prompt);
            }
            if (conversationId != null) {
                userMessageId = insertMessage(dbConnection, conversationId, chatUserId, "user", prompt);
            }

            connection = (HttpURLConnection) new URL(apiEndpoint).openConnection();
            connection.setRequestMethod("POST");
            connection.setConnectTimeout(API_TIMEOUT);
            connection.setReadTimeout(API_TIMEOUT);
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            connection.setRequestProperty("Accept", "text/event-stream");
            connection.setRequestProperty("Authorization", "Bearer " + apiKey);

            String payload = "{\"model\":\"" + jsonEscape(apiModel) + "\",\"stream\":true,\"messages\":" + messagesJson + ",\"temperature\":0.7}";
            try (OutputStream requestStream = connection.getOutputStream()) {
                requestStream.write(payload.getBytes(StandardCharsets.UTF_8));
                requestStream.flush();
            }

            int status = connection.getResponseCode();
            upstream = status >= 200 && status < 300 ? connection.getInputStream() : connection.getErrorStream();

            response.setStatus(status);
            response.setCharacterEncoding("UTF-8");
            response.setHeader("Cache-Control", "no-cache");
            response.setHeader("X-Accel-Buffering", "no");
            if (conversationId != null) {
                response.setHeader("X-Conversation-Id", String.valueOf(conversationId.longValue()));
            }
            String upstreamType = connection.getContentType();
            response.setContentType((upstreamType != null && !upstreamType.isEmpty()) ? upstreamType : "text/event-stream; charset=UTF-8");

            if (upstream != null) {
                String rawPayload = pipeAndCollect(upstream, response.getOutputStream());
                if (status >= 200 && status < 300 && conversationId != null) {
                    String assistantContent = extractAssistantContent(rawPayload);
                    Long assistantMessageId = null;
                    if (!assistantContent.isEmpty()) {
                        assistantMessageId = insertMessage(dbConnection, conversationId, null, "assistant", assistantContent);
                    }
                    insertModelLog(
                        dbConnection,
                        conversationId,
                        assistantMessageId,
                        apiModel,
                        "SUCCESS",
                        System.currentTimeMillis() - startedAt,
                        null
                    );
                }
            }
        } catch (Exception ex) {
            application.log("AI chat request failed.", ex);
            if (dbConnection != null && conversationId != null) {
                try {
                    insertModelLog(
                        dbConnection,
                        conversationId,
                        userMessageId,
                        apiModel,
                        "FAILED",
                        System.currentTimeMillis() - startedAt,
                        ex.getMessage()
                    );
                } catch (SQLException ignore) {
                }
            }
            if (!response.isCommitted()) {
                response.reset();
                response.setStatus(502);
                response.setContentType("text/plain; charset=UTF-8");
                response.getWriter().write("API request failed: " + ex.getMessage());
            }
        } finally {
            if (upstream != null) {
                try { upstream.close(); } catch (IOException ignore) {}
            }
            if (connection != null) {
                connection.disconnect();
            }
            if (dbConnection != null) {
                try { dbConnection.close(); } catch (SQLException ignore) {}
            }
        }
        return;
    }
%>
