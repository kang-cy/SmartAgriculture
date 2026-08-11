<template>
  <div class="ai-chat">
    <!-- 助手头部 -->
    <div class="chat-header">
      <el-avatar :size="42" class="assistant-avatar">
        <el-icon :size="22"><ChatDotRound /></el-icon>
      </el-avatar>
      <div class="assistant-info">
        <div class="assistant-name">智慧农业助手</div>
        <div class="assistant-status">
          <span class="status-dot"></span>
          在线 · 随时为您服务
        </div>
      </div>
    </div>

    <!-- 消息区域 -->
    <div class="chat-messages" ref="messagesRef">
      <div
        v-for="(msg, i) in messages"
        :key="i"
        class="msg-row"
        :class="msg.role"
      >
        <el-avatar :size="38" class="msg-avatar" :class="msg.role">
          <el-icon v-if="msg.role === 'ai'"><ChatDotRound /></el-icon>
          <span v-else>{{ userInitial }}</span>
        </el-avatar>
        <div class="msg-body">
          <div class="msg-meta">
            <span class="msg-name">{{ msg.role === 'ai' ? '智慧农业助手' : (userStore.username || '我') }}</span>
            <span class="msg-time">{{ msg.time }}</span>
          </div>
          <div class="msg-bubble">{{ msg.content }}</div>
        </div>
      </div>

      <!-- 打字指示器 -->
      <div v-if="loading" class="msg-row ai">
        <el-avatar :size="38" class="msg-avatar ai">
          <el-icon><ChatDotRound /></el-icon>
        </el-avatar>
        <div class="msg-body">
          <div class="msg-meta">
            <span class="msg-name">智慧农业助手</span>
          </div>
          <div class="typing-indicator">
            <span class="dot"></span>
            <span class="dot"></span>
            <span class="dot"></span>
          </div>
        </div>
      </div>
    </div>

    <!-- 快捷建议 -->
    <div class="suggestions">
      <span class="suggestions-label">快捷提问</span>
      <div
        v-for="s in suggestions"
        :key="s"
        class="suggestion-chip"
        @click="handleSend(s)"
      >
        <el-icon><ChatLineRound /></el-icon>
        {{ s }}
      </div>
    </div>

    <!-- 输入区域 -->
    <div class="input-area">
      <div class="input-wrapper">
        <el-input
          v-model="inputText"
          type="textarea"
          :autosize="{ minRows: 1, maxRows: 4 }"
          placeholder="输入您的问题，按 Enter 发送，Shift+Enter 换行..."
          resize="none"
          @keydown.enter="handleEnter"
        />
      </div>
      <el-button
        type="primary"
        :loading="loading"
        :disabled="!inputText.trim()"
        class="send-btn"
        @click="handleSend()"
      >
        <el-icon v-if="!loading"><Promotion /></el-icon>
        <span>发送</span>
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { ChatDotRound, ChatLineRound, Promotion } from '@element-plus/icons-vue'
import { api } from '@/api'
import { useUserStore } from '@/store/user'

const userStore = useUserStore()

const messagesRef = ref(null)
const inputText = ref('')
const loading = ref(false)

const userInitial = computed(() => {
  const name = userStore.username || '我'
  return name.charAt(0).toUpperCase()
})

const suggestions = [
  '当前土壤湿度如何？',
  '灌溉建议',
  '番茄种植注意事项',
  '何时浇水最佳？',
]

const messages = ref([])

function formatTime(date = new Date()) {
  const h = String(date.getHours()).padStart(2, '0')
  const m = String(date.getMinutes()).padStart(2, '0')
  return `${h}:${m}`
}

function scrollToBottom() {
  nextTick(() => {
    if (messagesRef.value) {
      messagesRef.value.scrollTop = messagesRef.value.scrollHeight
    }
  })
}

function handleEnter(e) {
  // Shift+Enter 换行，Enter 发送
  if (e.shiftKey) return
  e.preventDefault()
  handleSend()
}

async function handleSend(text) {
  const content = (text ?? inputText.value).trim()
  if (!content || loading.value) return

  // 添加用户消息
  messages.value.push({
    role: 'user',
    content,
    time: formatTime(),
  })
  inputText.value = ''
  loading.value = true
  scrollToBottom()

  try {
    const res = await api.aiChat(content)
    if (res.code === 200) {
      messages.value.push({
        role: 'ai',
        content: res.data.reply,
        time: formatTime(),
      })
    } else {
      messages.value.push({
        role: 'ai',
        content: '抱歉，服务暂时不可用，请稍后重试。',
        time: formatTime(),
      })
    }
  } catch {
    messages.value.push({
      role: 'ai',
      content: '抱歉，网络异常，请检查网络后重试。',
      time: formatTime(),
    })
  } finally {
    loading.value = false
    scrollToBottom()
  }
}

onMounted(() => {
  // 显示欢迎消息
  messages.value.push({
    role: 'ai',
    content: '您好！我是智慧农业助手，可以为您提供灌溉建议和农事指导。请问有什么可以帮您的？',
    time: formatTime(),
  })
  scrollToBottom()
})
</script>

<style scoped>
.ai-chat {
  height: 100%;
  display: flex;
  flex-direction: column;
  background: var(--bg-page);
  overflow: hidden;
}

/* ===== 助手头部 ===== */
.chat-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 24px;
  background: var(--bg-card);
  border-bottom: 1px solid var(--border-color);
}

.assistant-avatar {
  background: linear-gradient(135deg, var(--primary-light), var(--primary-dark));
  color: #fff;
  flex-shrink: 0;
}

.assistant-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.assistant-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.assistant-status {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
  color: var(--text-secondary);
}

.status-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--success);
  box-shadow: 0 0 6px rgba(34, 197, 94, 0.5);
}

/* ===== 消息区域 ===== */
.chat-messages {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 24px;
}

.msg-row {
  display: flex;
  gap: 10px;
  margin-bottom: 22px;
  max-width: 100%;
}

.msg-row.user {
  flex-direction: row-reverse;
}

.msg-avatar {
  flex-shrink: 0;
  font-size: 16px;
  font-weight: 600;
}

.msg-avatar.ai {
  background: linear-gradient(135deg, var(--primary-light), var(--primary-dark));
  color: #fff;
}

.msg-avatar.user {
  background: var(--primary);
  color: #fff;
}

.msg-body {
  display: flex;
  flex-direction: column;
  max-width: 70%;
}

.msg-row.user .msg-body {
  align-items: flex-end;
}

.msg-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 5px;
  font-size: 12px;
}

.msg-row.user .msg-meta {
  flex-direction: row-reverse;
}

.msg-name {
  font-weight: 500;
  color: var(--text-secondary);
}

.msg-time {
  color: var(--text-tertiary);
}

.msg-bubble {
  padding: 12px 16px;
  border-radius: 14px;
  font-size: 14px;
  line-height: 1.7;
  word-break: break-word;
  white-space: pre-wrap;
}

.msg-row.ai .msg-bubble {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  color: var(--text-primary);
  border-top-left-radius: 4px;
  box-shadow: var(--shadow-sm);
}

.msg-row.user .msg-bubble {
  background: var(--primary);
  color: #fff;
  border-top-right-radius: 4px;
  box-shadow: 0 2px 8px rgba(22, 163, 74, 0.25);
}

/* ===== 打字指示器 ===== */
.typing-indicator {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 14px 18px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: 14px;
  border-top-left-radius: 4px;
  box-shadow: var(--shadow-sm);
}

.typing-indicator .dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--text-tertiary);
  animation: typing 1.4s infinite ease-in-out;
}

.typing-indicator .dot:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator .dot:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%, 60%, 100% {
    transform: translateY(0);
    opacity: 0.4;
  }
  30% {
    transform: translateY(-6px);
    opacity: 1;
  }
}

/* ===== 快捷建议 ===== */
.suggestions {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  padding: 12px 24px;
  background: var(--bg-card);
  border-top: 1px solid var(--border-color);
}

.suggestions-label {
  font-size: 12px;
  color: var(--text-tertiary);
  margin-right: 4px;
}

.suggestion-chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 6px 14px;
  background: var(--primary-bg);
  border: 1px solid #bbf7d0;
  border-radius: 20px;
  font-size: 13px;
  color: var(--primary-dark);
  cursor: pointer;
  transition: all 0.2s ease;
  user-select: none;
}

.suggestion-chip:hover {
  background: var(--primary);
  border-color: var(--primary);
  color: #fff;
  transform: translateY(-1px);
}

.suggestion-chip .el-icon {
  font-size: 13px;
}

/* ===== 输入区域 ===== */
.input-area {
  flex-shrink: 0;
  display: flex;
  align-items: flex-end;
  gap: 12px;
  padding: 16px 24px;
  background: var(--bg-card);
  border-top: 1px solid var(--border-color);
}

.input-wrapper {
  flex: 1;
}

.input-wrapper :deep(.el-textarea__inner) {
  border-radius: 12px;
  padding: 10px 14px;
  font-size: 14px;
  line-height: 1.6;
  box-shadow: none;
  border: 1px solid var(--border-color);
  transition: border-color 0.2s ease;
}

.input-wrapper :deep(.el-textarea__inner:focus) {
  border-color: var(--primary);
}

.send-btn {
  height: 42px;
  padding: 0 22px;
  font-size: 14px;
  font-weight: 500;
  border-radius: 12px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 6px;
}
</style>
