<main>
    <section class="page-hero">
        <div class="container">
            <div class="page-hero-card compact">
                <div class="section-label">Contact Us</div>
                <h1>把官网最后一块补齐：联系方式、合作场景和演示留言。</h1>
                <p>这里先保留一个轻量版联系页面，后续可以继续接入真实邮箱、工单系统或后台数据库。</p>
            </div>
        </div>
    </section>

    <section class="section">
        <div class="container contact-grid">
            <article class="contact-card">
                <span class="card-tag">服务咨询</span>
                <h3>面向个人用户</h3>
                <p>如果你想了解平台定位、试用方式或后续功能路线，可以先通过下面的演示留言入口联系我们。</p>
            </article>
            <article class="contact-card">
                <span class="card-tag">合作方向</span>
                <h3>面向学校 / 机构 / 企业</h3>
                <p>后续这一页也可以扩展成机构合作入口，承接课程、员工关怀或心理支持项目对接。</p>
            </article>
        </div>
    </section>

    <section class="section">
        <div class="container grid-2">
            <article class="panel-card">
                <div class="section-label">联系信息</div>
                <h2>演示联系卡</h2>
                <ul class="support-list">
                    <li>演示邮箱：support@xinqing-demo.local</li>
                    <li>接待时间：周一到周五 10:00 - 18:00</li>
                    <li>后续可扩展为：客服、合作咨询、预约入口</li>
                </ul>
            </article>

            <article class="panel-card">
                <div class="section-label">演示留言</div>
                <h2>提交一条站内咨询</h2>
                <% if (contactSuccessView != null) { %>
                <div class="message-box success"><%= contactSuccessView %></div>
                <% } %>
                <form method="post" action="contact.jsp" class="form-stack">
                    <label class="field">
                        <span>姓名</span>
                        <input type="text" name="name" value="<%= nameValueView == null ? "" : nameValueView %>" placeholder="请输入你的姓名" required>
                    </label>
                    <label class="field">
                        <span>邮箱</span>
                        <input type="email" name="email" value="<%= emailValueView == null ? "" : emailValueView %>" placeholder="请输入邮箱" required>
                    </label>
                    <label class="field">
                        <span>内容</span>
                        <textarea name="message" placeholder="你希望了解哪些功能？" required><%= messageValueView == null ? "" : messageValueView %></textarea>
                    </label>
                    <button class="btn btn-primary" type="submit">提交演示留言</button>
                </form>
            </article>
        </div>
    </section>
</main>
