<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
request.setCharacterEncoding("UTF-8");

if (!Boolean.TRUE.equals(session.getAttribute("loggedIn"))) {
    response.sendRedirect("login.jsp");
    return;
}

String username = String.valueOf(session.getAttribute("username"));
request.setAttribute("workspaceUsername", username);
request.setAttribute("pageTitle", "心晴疗愈 | 会员工作台");
request.setAttribute("pageContent", "/WEB-INF/views/workspace/dashboard.jsp");
request.setAttribute("pageBodyAttributes", "data-username=\"" + username.replace("\"", "&quot;") + "\"");
%>
<%@ include file="WEB-INF/jspf/layout/workspace-page.jspf" %>
