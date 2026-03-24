# JSPDemo2.0

## 当前架构

这次重构后，项目已经从“JSP 页面里混合 UI、脚本、数据库和 AI 调用”整理成了更容易协作的结构：

- `webapp/*.jsp`
  - 只保留页面级入口、登录校验和少量控制逻辑
- `webapp/api/*.jsp`
  - 放后端接口
  - 目前包含工作台数据接口和 AI 对话接口
- `webapp/WEB-INF/views/`
  - 放纯 UI 视图片段，方便前端同学直接改页面
- `webapp/WEB-INF/jspf/layout/`
  - 放通用布局模板
- `webapp/assets/css/`
  - 放页面样式
- `webapp/assets/js/`
  - 放页面交互脚本
- `sql/schema.sql`
  - 放数据库结构

## 目录说明

### 页面入口

- `webapp/index.jsp`
- `webapp/about.jsp`
- `webapp/programs.jsp`
- `webapp/resources.jsp`
- `webapp/contact.jsp`
- `webapp/login.jsp`
- `webapp/register.jsp`
- `webapp/dashboard.jsp`
- `webapp/blz.jsp`

### 后端接口

- `webapp/api/workspace-data.jsp`
  - 工作台数据读写接口
- `webapp/api/ai-chat.jsp`
  - AI 对话历史和流式聊天接口

### 纯 UI 片段

- `webapp/WEB-INF/views/public/`
  - 官网公开页面内容
- `webapp/WEB-INF/views/auth/`
  - 登录和注册界面
- `webapp/WEB-INF/views/workspace/`
  - 工作台界面
- `webapp/WEB-INF/views/ai/`
  - AI 聊天界面

### 通用布局

- `webapp/WEB-INF/jspf/layout/public-page.jspf`
- `webapp/WEB-INF/jspf/layout/auth-page.jspf`
- `webapp/WEB-INF/jspf/layout/workspace-page.jspf`

### 前端静态资源

- `webapp/assets/css/site.css`
- `webapp/assets/css/ai-chat.css`
- `webapp/assets/js/site.js`
- `webapp/assets/js/dashboard-db.js`
- `webapp/assets/js/ai-chat.js`

## 已清理的旧文件

下面这些旧文件已经不再需要，已从主结构中清理：

- 旧的静态提示页
- 旧的测试页
- 旧的本地文件用户存储
- 旧的工作台本地脚本副本

## 数据库

执行：

```sql
CREATE DATABASE jspdemo
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
```

然后导入：

```powershell
mysql -u root -p jspdemo < sql/schema.sql
```

当前数据库表：

- `users`
- `conversations`
- `messages`
- `model_call_logs`
- `workspace_state`

## 本地启动

### 推荐方式

直接双击：

- `start-jspdemo.bat`

停止时双击：

- `stop-jspdemo.bat`

### 启动脚本会做什么

- 启动 `MYSQL80`
- 注入数据库和 AI 环境变量
- 启动 Tomcat
- 自动打开登录页

## 你需要改的地方

启动脚本里请改成你自己的真实配置：

- `APP_DB_PASSWORD`
- `APP_AI_KEY`

文件位置：

- `start-jspdemo.bat`

## Tomcat 说明

当前项目运行在：

- `C:\Program Files\Apache Software Foundation\Tomcat 9.0`

Tomcat 的 MySQL 驱动位置：

- `C:\Program Files\Apache Software Foundation\Tomcat 9.0\lib\mysql-connector-j-9.5.0.jar`

## 现在的协作方式

如果后续有人要改页面：

- 先改 `WEB-INF/views/` 里的 UI 片段
- 再改 `assets/css/` 和 `assets/js/`
- 尽量不要直接把业务逻辑重新塞回 JSP 页面

如果后续有人要接 AI：

- 改 `webapp/api/ai-chat.jsp`
- 页面只改 `webapp/blz.jsp`、`webapp/WEB-INF/views/ai/chat-ui.jspf`、`webapp/assets/js/ai-chat.js`

如果后续有人要改工作台：

- 改 `webapp/api/workspace-data.jsp`
- 页面只改 `webapp/dashboard.jsp`、`webapp/WEB-INF/views/workspace/dashboard.jspf`、`webapp/assets/js/dashboard-db.js`
