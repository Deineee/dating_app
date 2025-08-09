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

