<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="WEB-INF/jspf/user-store.jspf" %>
<%
request.setCharacterEncoding("UTF-8");

if (Boolean.TRUE.equals(session.getAttribute("loggedIn"))) {
    response.sendRedirect("dashboard.jsp");
    return;
}

String errorMessage = null;
String usernameValue = "";

if ("POST".equalsIgnoreCase(request.getMethod())) {
    usernameValue = request.getParameter("username") == null ? "" : request.getParameter("username").trim();
    String passwordValue = request.getParameter("password") == null ? "" : request.getParameter("password").trim();
    String confirmPassword = request.getParameter("confirmPassword") == null ? "" : request.getParameter("confirmPassword").trim();

    if (usernameValue.length() < 3) {
        errorMessage = "用户名至少需要 3 个字符。";
    } else if (!usernameValue.matches("[A-Za-z0-9_]+")) {
        errorMessage = "用户名只能包含字母、数字和下划线。";
    } else if (passwordValue.length() < 6) {
        errorMessage = "密码至少需要 6 个字符。";
    } else if (!passwordValue.equals(confirmPassword)) {
        errorMessage = "两次输入的密码不一致。";
    } else {
        try {
            if (userExists(application, usernameValue)) {
                errorMessage = "该用户名已存在，请更换一个。";
            } else {
                registerUser(application, usernameValue, passwordValue);
                response.sendRedirect("login.jsp?registered=1");
                return;
            }
        } catch (Exception ex) {
            application.log("Register failed while connecting to MySQL.", ex);
            errorMessage = "注册失败：请先配置 MySQL 和 JDBC 驱动。";
        }
    }
}

request.setAttribute("errorMessage", errorMessage);
request.setAttribute("usernameValue", usernameValue);
request.setAttribute("pageTitle", "心晴疗愈 | 注册");
request.setAttribute("pageContent", "/WEB-INF/views/auth/register.jsp");
request.setAttribute("pageBodyClass", "auth-page");
%>
<%@ include file="WEB-INF/jspf/layout/auth-page.jspf" %>
