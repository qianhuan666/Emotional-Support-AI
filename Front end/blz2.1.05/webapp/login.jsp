<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="WEB-INF/jspf/user-store.jspf" %>
<%
request.setCharacterEncoding("UTF-8");

if (Boolean.TRUE.equals(session.getAttribute("loggedIn"))) {
    response.sendRedirect("dashboard.jsp");
    return;
}

String errorMessage = null;
String successMessage = request.getParameter("registered") != null ? "注册成功，请使用新账号登录。" : null;
String usernameValue = "";

if ("POST".equalsIgnoreCase(request.getMethod())) {
    usernameValue = request.getParameter("username") == null ? "" : request.getParameter("username").trim();
    String passwordValue = request.getParameter("password") == null ? "" : request.getParameter("password").trim();

    if (usernameValue.isEmpty() || passwordValue.isEmpty()) {
        errorMessage = "请输入用户名和密码。";
    } else {
        try {
            if (verifyUser(application, usernameValue, passwordValue)) {
                session.setAttribute("loggedIn", Boolean.TRUE);
                session.setAttribute("username", usernameValue);
                response.sendRedirect("dashboard.jsp");
                return;
            }

            errorMessage = "用户名或密码不正确，请重试。";
        } catch (Exception ex) {
            application.log("Login failed while connecting to MySQL.", ex);
            errorMessage = "登录失败：请先配置 MySQL 和 JDBC 驱动。";
        }
    }
}

request.setAttribute("errorMessage", errorMessage);
request.setAttribute("successMessage", successMessage);
request.setAttribute("usernameValue", usernameValue);
request.setAttribute("pageTitle", "心晴疗愈 | 登录");
request.setAttribute("pageContent", "/WEB-INF/views/auth/login.jsp");
request.setAttribute("pageBodyClass", "auth-page");
%>
<%@ include file="WEB-INF/jspf/layout/auth-page.jspf" %>
