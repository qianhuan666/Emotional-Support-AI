<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
request.setCharacterEncoding("UTF-8");
String currentPage = "contact";
String contactSuccess = null;
String nameValue = "";
String emailValue = "";
String messageValue = "";

if ("POST".equalsIgnoreCase(request.getMethod())) {
    nameValue = request.getParameter("name") == null ? "" : request.getParameter("name").trim();
    emailValue = request.getParameter("email") == null ? "" : request.getParameter("email").trim();
    messageValue = request.getParameter("message") == null ? "" : request.getParameter("message").trim();

    if (!nameValue.isEmpty() && !emailValue.isEmpty() && !messageValue.isEmpty()) {
        contactSuccess = "演示留言已收到。后续你可以把这里接到真实邮箱、工单系统或后台数据库。";
        messageValue = "";
    }
}

request.setAttribute("contactSuccess", contactSuccess);
request.setAttribute("nameValue", nameValue);
request.setAttribute("emailValue", emailValue);
request.setAttribute("messageValue", messageValue);
request.setAttribute("pageTitle", "心晴疗愈 | 联系我们");
request.setAttribute("pageContent", "/WEB-INF/views/public/contact.jsp");
%>
<%@ include file="WEB-INF/jspf/layout/public-page.jspf" %>
