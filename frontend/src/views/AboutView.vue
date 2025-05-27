<template>
  <div class="container">
    <div class="header">
      <h1>关于 Cloudflare IP 优选工具</h1>
      <p class="subtitle">了解工具的功能和使用方法</p>
    </div>

    <main class="main-content">
      <div class="card">
        <div class="card-header">
          <h2>功能介绍</h2>
        </div>
        <div class="card-body">
          <div class="feature-section">
            <h3>什么是 Cloudflare IP 优选？</h3>
            <p>
              Cloudflare IP 优选是一个帮助您找到最快 Cloudflare CDN 节点的工具。通过测试不同 IP
              的延迟和速度，为您选择最优的连接节点。
            </p>
          </div>

          <div class="feature-section">
            <h3>主要功能</h3>
            <img class="workflow-img"      src="../assets/workflow.png" alt="" />
            <!-- <ul class="feature-list">
              <li>
                <span class="feature-icon">🚀</span>
                <div class="feature-content">
                  <h4>自动优选</h4>
                  <p>一键测试并选择最快的 Cloudflare IP</p>
                </div>
              </li>
              <li>
                <span class="feature-icon">📊</span>
                <div class="feature-content">
                  <h4>性能测试</h4>
                  <p>测试延迟、下载速度等关键指标</p>
                </div>
              </li>
              <li>
                <span class="feature-icon">🔄</span>
                <div class="feature-content">
                  <h4>自动更新</h4>
                  <p>自动更新 hosts 文件，无需手动操作</p>
                </div>
              </li>
            </ul> -->
          </div>

          <div class="feature-section">
            <h3>使用说明</h3>
            <p>1️⃣ 添加域名和删除域名一般很快，优选测试需要等待 4-5 分钟，优选测试完成后，会自动更新 hosts 文件</p>
            <p>2️⃣ 如果你不放心，或者觉得卡了，请使用<code> docker logs container_name </code> 或者你的可视化界面查看日志。当年进行一个操作时，请不要进行其他操作，否则可能会导致操作失败</p>
            <p>3️⃣ 优选已经包含绝大部分域名，请低调使用，如果没有，可以手动输入并添加</p>
            <p>4️⃣ 优选完重启相关容器优选才会生效</p>
            <p>5️⃣ 我也没有做定时优选的功能，相信我，你不需要频繁的进行优选，优选完，就忘掉我吧</p>
            <p>6️⃣ 感谢 windfree、tianting 帮助完善站点数据</p>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style scoped lang="scss">
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.header {
  text-align: center;
  margin-bottom: 3rem;
}

.header h1 {
  font-size: 2.5rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.subtitle {
  font-size: 1.2rem;
  color: #666;
}

.main-content {
  display: flex;
  justify-content: center;
}

.card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 800px;
  overflow: hidden;
}

.card-header {
  padding: 2rem;
  background: #f8f9fa;
  border-bottom: 1px solid #eee;
}

.card-header h2 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.5rem;
}

.card-body {
  padding: 2rem;
}

.feature-section {
  margin-bottom: 2.5rem;
  .workflow-img {
    width: 100%;
  }
  p{
    font-size: 16px;
    line-height: 1.6;
  }
}

.feature-section:last-child {
  margin-bottom: 0;
}

.feature-section h3 {
  color: #2c3e50;
  font-size: 1.3rem;
  margin-bottom: 1rem;
}

.feature-section p {
  color: #666;
  line-height: 1.6;
}

.feature-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.feature-list li {
  display: flex;
  align-items: flex-start;
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
}

.feature-list li:last-child {
  margin-bottom: 0;
}

.feature-icon {
  font-size: 1.5rem;
  margin-right: 1rem;
  flex-shrink: 0;
}

.feature-content h4 {
  margin: 0 0 0.5rem;
  color: #2c3e50;
}

.feature-content p {
  margin: 0;
  color: #666;
}

.instruction-list {
  padding-left: 1.5rem;
  color: #666;
}

.instruction-list li {
  margin-bottom: 0.8rem;
  line-height: 1.6;
}

.instruction-list li:last-child {
  margin-bottom: 0;
}
</style>
