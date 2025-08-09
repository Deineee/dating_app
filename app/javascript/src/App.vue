<template>
  <div id="app" class="min-h-screen flex flex-col">
    <Header />
    <main class="flex-grow p-4 overflow-y-auto min-h-[80vh]">
      <router-view />
    </main>
    <Footer />
  </div>
</template>

<script setup>
import Header from '../components/shared/Header.vue'
import Footer from '../components/shared/Footer.vue'
</script>