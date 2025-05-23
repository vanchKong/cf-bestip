<script setup>
import { ref, onMounted } from 'vue'

const loading = ref(false)
const addResult = ref([])
const delResult = ref([])
const updateResult = ref([])
const addError = ref('')
const delError = ref('')
const updateError = ref('')
const listError = ref('')
const domainList = ref([])
const newDomains = ref('')
const delDomains = ref('')
const activeTab = ref('add') // 'test', 'add', 'del', 'list'
const updatingDomains = ref(new Set()) // 记录正在更新的域名

// 获取域名列表
const fetchDomainList = async () => {
  loading.value = true
  listError.value = ''
  try {
    const response = await fetch('/api/list')
    const data = await response.json()
    if (data.code === 0) {
      domainList.value = data.data
      if (data.data.length === 0) {
        listError.value = '暂无已优选域名'
      }
    } else {
      listError.value = data.message || '获取域名列表失败'
    }
  } catch (err) {
    listError.value = '获取域名列表失败'
  } finally {
    loading.value = false
  }
}

// 添加域名
const addDomains = async () => {
  if (!newDomains.value.trim()) {
    addError.value = '请输入域名'
    return
  }

  loading.value = true
  addError.value = ''
  addResult.value = []

  try {
    // 处理域名输入，支持逗号、空格和换行分隔
    const domains = newDomains.value
      .split(/[,\s\n]+/)  // 使用正则表达式分割多种分隔符
      .map(domain => domain.trim())  // 去除每个域名的首尾空格
      .filter(domain => domain)  // 过滤掉空字符串

    const response = await fetch('/api/add', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ domain: domains.join(' ') }),  // 用空格重新连接域名
    })
    const data = await response.json()
    if (data.code === 0) {
      addResult.value = data.data
      newDomains.value = ''
      await fetchDomainList()
    }
  } catch (err) {
    addError.value = '添加域名失败'
  } finally {
    loading.value = false
  }
}

// 删除域名
const deleteDomains = async () => {
  if (!delDomains.value.trim()) {
    delError.value = '请输入要删除的域名'
    return
  }

  loading.value = true
  delError.value = ''
  delResult.value = []

  try {
    // 处理域名输入，支持逗号、空格和换行分隔
    const domains = delDomains.value
      .split(/[,\s\n]+/)  // 使用正则表达式分割多种分隔符
      .map(domain => domain.trim())  // 去除每个域名的首尾空格
      .filter(domain => domain)  // 过滤掉空字符串

    const response = await fetch('/api/del', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ domain: domains.join(' ') }),  // 用空格重新连接域名
    })
    const data = await response.json()
    if (data.code === 0) {
      delResult.value = data.data
      delDomains.value = ''
      await fetchDomainList()
    }
  } catch (err) {
    delError.value = '删除域名失败'
  } finally {
    loading.value = false
  }
}

// 更新单个域名
const updateSingleDomain = async (domain) => {
  if (updatingDomains.value.has(domain)) return

  updatingDomains.value.add(domain)
  try {
    const response = await fetch(`/api/update/${domain}`)
    const data = await response.json()
    if (data.code === 0) {
      updateResult.value = data.data
      await fetchDomainList()
    }
  } catch (err) {
    updateError.value = '更新域名失败'
  } finally {
    updatingDomains.value.delete(domain)
  }
}

// 更新所有域名
const updateAllDomains = async () => {
  loading.value = true
  updateError.value = ''
  updateResult.value = []

  try {
    const response = await fetch('/api/update')
    const data = await response.json()
    if (data.code === 0) {
      updateResult.value = data.data
      await fetchDomainList()
    }
  } catch (err) {
    updateError.value = '更新域名失败'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchDomainList()
})
</script>

<template>
  <div class="container">
    <header class="header">
      <h1>Cloudflare IP 优选工具</h1>
      <!-- <p class="subtitle">一键优化您的网络连接速度</p> -->
      <h3>请先到 <span style="color: hsla(160, 100%, 37%, 1);">关于</span> 界面 查看使用说明</h3>
    </header>

    <main class="main-content">
      <div class="tabs">
        <button :class="['tab-button', { active: activeTab === 'add' }]" @click="activeTab = 'add'">
          添加域名
        </button>
        <button :class="['tab-button', { active: activeTab === 'del' }]" @click="activeTab = 'del'">
          删除域名
        </button>
        <button
          :class="['tab-button', { active: activeTab === 'test' }]"
          @click="activeTab = 'test'"
        >
          优选测试
        </button>
        <button
          :class="['tab-button', { active: activeTab === 'list' }]"
          @click="activeTab = 'list'"
        >
          已优选域名
        </button>
      </div>

      <div class="card">
        <!-- 优选测试面板 -->
        <div v-if="activeTab === 'test'" class="card-body">
          <button @click="updateAllDomains" :disabled="loading" class="primary-button">
            <span v-if="loading" class="loading-spinner"></span>
            {{ loading ? '优选中...' : '开始优选' }}
          </button>

          <div v-if="updateError" class="error-message">
            <i class="error-icon">⚠️</i>
            {{ updateError }}
          </div>

          <div v-if="updateResult.length" class="result-container">
            <h3>优选结果</h3>
            <div class="result-content">
              <div v-for="item in updateResult" :key="item.domain" class="result-item">
                <span class="domain">{{ item.domain }}</span>
                <span class="ip">{{ item.ip }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 已优选域名列表 -->
        <div v-if="activeTab === 'list'" class="card-body">
          <div v-if="loading" class="loading-container">
            <el-icon class="is-loading"><Loading /></el-icon>
            <span>正在获取已优选域名列表...</span>
          </div>
          <template v-else>
            <div v-if="listError" class="error-message">
              <i class="error-icon">⚠️</i>
              {{ listError }}
            </div>
            <div v-else class="domain-list">
              <div v-for="item in domainList" :key="item.domain" class="domain-item">
                <span class="domain">{{ item.domain }}</span>
                <span class="ip">{{ item.ip }}</span>
              </div>
            </div>
          </template>
        </div>

        <!-- 添加域名面板 -->
        <div v-if="activeTab === 'add'" class="card-body">
          <div class="card-header">
            <h2>添加域名</h2>
            <p>支持批量添加域名，多个域名请用逗号、空格或换行分隔</p>
          </div>

          <div class="domain-form">
            <textarea
              v-model="newDomains"
              placeholder="输入域名，多个域名请用逗号、空格或换行分隔&#10;例如：&#10;example1.com&#10;example2.com, example3.com"
              class="domain-textarea"
              rows="5"
            ></textarea>
            <button @click="addDomains" :disabled="loading || !newDomains" class="secondary-button">
              添加域名
            </button>
          </div>

          <div v-if="addError" class="error-message">
            <i class="error-icon">⚠️</i>
            {{ addError }}
          </div>

          <div v-if="addResult.length" class="result-container">
            <h3>添加结果</h3>
            <div class="result-content">
              <div v-for="item in addResult" :key="item.domain" class="result-item">
                <span class="domain">{{ item.domain }}</span>
                <span
                  class="status"
                  :class="{
                    'status-success': item.status === '添加成功',
                    'status-warning': item.status === '已存在',
                    'status-error': item.status === '未添加',
                  }"
                  >{{ item.status }}</span
                >
                <span v-if="item.ip" class="ip">(IP: {{ item.ip }})</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 删除域名面板 -->
        <div v-if="activeTab === 'del'" class="card-body">
          <div class="card-header">
            <h2>删除域名</h2>
            <p>支持批量删除域名，多个域名请用逗号、空格或换行分隔</p>
          </div>

          <div class="domain-form">
            <textarea
              v-model="delDomains"
              placeholder="输入要删除的域名，多个域名请用逗号、空格或换行分隔&#10;例如：&#10;example1.com&#10;example2.com, example3.com"
              class="domain-textarea"
              rows="5"
            ></textarea>
            <button @click="deleteDomains" :disabled="loading || !delDomains" class="danger-button">
              删除域名
            </button>
          </div>

          <div v-if="delError" class="error-message">
            <i class="error-icon">⚠️</i>
            {{ delError }}
          </div>

          <div v-if="delResult.length" class="result-container">
            <h3>删除结果</h3>
            <div class="result-content">
              <div v-for="item in delResult" :key="item.domain" class="result-item">
                <span class="domain">{{ item.domain }}</span>
                <span
                  class="status"
                  :class="{
                    'status-success': item.status === '删除成功',
                    'status-warning': item.status === '不存在',
                  }"
                  >{{ item.status }}</span
                >
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style scoped>
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
  flex-direction: column;
  align-items: center;
}

.tabs {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
  justify-content: center;
}

.tab-button {
  padding: 0.75rem 1.5rem;
  border: none;
  background: #f8f9fa;
  color: #666;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s;
}

.tab-button.active {
  background: #3498db;
  color: white;
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
  margin-bottom: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  border-bottom: 1px solid #eee;
}

.card-header h2 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.5rem;
}

.card-header p {
  margin: 0.5rem 0 0;
  color: #666;
}

.card-body {
  padding: 2rem;
}

.primary-button {
  background: #3498db;
  color: white;
  border: none;
  padding: 1rem 2rem;
  font-size: 1.1rem;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  width: 100%;
  max-width: 300px;
  margin: 0 auto;
}

.primary-button:hover {
  background: #2980b9;
}

.primary-button:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.secondary-button {
  background: #2ecc71;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.secondary-button:hover {
  background: #27ae60;
}

.secondary-button:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.danger-button {
  background: #e74c3c;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.danger-button:hover {
  background: #c0392b;
}

.danger-button:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.loading-spinner {
  width: 20px;
  height: 20px;
  border: 3px solid #ffffff;
  border-radius: 50%;
  border-top-color: transparent;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-message {
  margin-top: 1rem;
  padding: 1rem;
  background: #fee2e2;
  border-radius: 6px;
  color: #dc2626;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.error-icon {
  font-size: 1.2rem;
}

.result-container {
  margin-top: 2rem;
}

.result-container h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

.result-content {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 6px;
  overflow-x: auto;
}

.result-content pre {
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.9rem;
  line-height: 1.5;
}

.domain-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 2rem;
}

.domain-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  resize: vertical;
}

.domain-textarea:focus {
  outline: none;
  border-color: #3498db;
}

.domain-list {
  margin-bottom: 2rem;
}

.empty-list {
  text-align: center;
  color: #666;
  padding: 2rem;
  background: #f8f9fa;
  border-radius: 6px;
}

.domain-items {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.domain-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 6px;
  gap: 1rem;
}

.domain-text {
  color: #2c3e50;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  flex: 1;
  word-break: break-all;
}

.update-button {
  background: #3498db;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.update-button:hover {
  background: #2980b9;
}

.update-button:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.loading-container {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  color: #909399;
}

.loading-container .el-icon {
  margin-right: 8px;
  font-size: 20px;
}

.result-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.5rem;
  border-bottom: 1px solid #eee;
}

.result-item:last-child {
  border-bottom: none;
}

.domain {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  color: #2c3e50;
}

.status {
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.9rem;
}

.status-success {
  background: #d4edda;
  color: #155724;
}

.status-warning {
  background: #fff3cd;
  color: #856404;
}

.status-error {
  background: #f8d7da;
  color: #721c24;
}

.ip {
  color: #666;
  font-size: 0.9rem;
}
</style>
