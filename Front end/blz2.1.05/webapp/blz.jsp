<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
if (!Boolean.TRUE.equals(session.getAttribute("loggedIn"))) {
    response.sendRedirect("login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>心晴疗愈 | AI 陪伴</title>
    <script src="https://cdn.jsdelivr.net/npm/dompurify@latest/dist/purify.min.js"></script>
    <link rel="stylesheet" href="assets/css/ai-chat.css">
</head>
<body>
<%
pageContext.include("/WEB-INF/views/ai/chat-ui.jspf");
%>
<script src="assets/js/ai-chat.js"></script>
</body>
</html>

