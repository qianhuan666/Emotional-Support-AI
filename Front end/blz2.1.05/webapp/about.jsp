<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
String currentPage = "about";
request.setAttribute("pageTitle", "心晴疗愈 | 平台介绍");
request.setAttribute("pageContent", "/WEB-INF/views/public/about.jspf");
%>
<%@ include file="WEB-INF/jspf/layout/public-page.jspf" %>
