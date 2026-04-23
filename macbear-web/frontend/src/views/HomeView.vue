<script setup lang="ts">
import { onMounted, ref } from "vue";

const health = ref<string>("…");
const greeting = ref<string>("");

async function load() {
  try {
    const h = await fetch("/api/health");
    const hj = await h.json();
    health.value = hj.db ? "DB 연결됨" : "DB 없음/미연결";
  } catch {
    health.value = "API 연결 실패";
  }
  try {
    const g = await fetch("/api/hello");
    const gj = await g.json();
    if (gj.message) greeting.value = gj.message;
  } catch {
    greeting.value = "";
  }
}

onMounted(load);
</script>

<template>
  <section class="home">
    <h1>맥베어 홈페이지</h1>
    <p class="lede">Vue 3 + Vite · Node API · MariaDB</p>
    <p v-if="greeting" class="greeting">{{ greeting }}</p>
    <p class="meta">API 상태: {{ health }}</p>
  </section>
</template>

<style scoped>
.home h1 {
  font-size: 1.75rem;
  margin: 0 0 0.5rem;
}
.lede {
  color: #555;
  margin: 0 0 1.25rem;
}
.greeting {
  font-size: 1.125rem;
  margin: 0 0 0.5rem;
}
.meta {
  font-size: 0.9rem;
  color: #666;
  margin: 0;
}
</style>
