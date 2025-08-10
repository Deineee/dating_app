<template>
  <div>
    <Header />
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import Header from '../components/shared/Header.vue'
</script>

