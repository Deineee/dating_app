<template>
  <div class="loading-spinner">
    <div class="spinner"></div>
    <p>Loading profiles...</p>
  </div>
</template>

<script setup>
// no props needed for now
</script>

<style scoped>
.loading-spinner {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 6px solid rgba(0,0,0,0.1);
  border-top-color: #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

p {
  font-size: 1rem;
  color: #555;
}
</style>
