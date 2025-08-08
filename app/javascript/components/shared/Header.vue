<template>
  <header class="header">
    <nav>
      <ul>
        <li><router-link to="/">Home</router-link></li>
        <li><router-link to="/signin">Sign In</router-link></li>
        <li><router-link to="/signup">Sign Up</router-link></li>
      </ul>
    </nav>
  </header>
</template>

<script setup>
import '../../stylesheets/header.css'
</script>