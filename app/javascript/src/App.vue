<template>
  <div>
    <Header />
    <main class="main-content">
      <router-view />
    </main>
    <Footer />
  </div>
</template>

<script setup>
import Header from '../components/shared/Header.vue'
import Footer from '../components/shared/Footer.vue'
</script>

<style scoped>
.main-content {
  padding: 2rem;
  min-height: 70vh;
}
</style>
