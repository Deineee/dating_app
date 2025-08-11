<template>
  <div class="landing-page">
    <h1>Dating App</h1>
    <p>Find your perfect match by signing up or signing in.</p>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;700&display=swap');

.landing-page {
  max-width: 720px;
  margin: 6rem auto;
  padding: 0 1rem;
  text-align: center;
  font-family: 'Poppins', sans-serif;
  color: #4a2c3a;
  background: #ffe4e9; /* soft light pink background */
  border-radius: 20px;
  box-shadow: 0 8px 30px rgba(255, 182, 193, 0.3);
  padding: 4rem 2rem;
  position: relative;
  overflow: hidden;
}

/* Big app name */
.landing-page h1 {
  font-size: 3.6rem;
  font-weight: 700;
  margin-bottom: 1rem;
  letter-spacing: 3px;
  text-transform: uppercase;
}

/* Subtitle */
.landing-page p {
  font-size: 1.4rem;
  max-width: 420px;
  margin: 0 auto;
  color: #6a4654;
}

/* Add subtle decorative hearts in background */
.landing-page::before,
.landing-page::after {
  content: "♥";
  position: absolute;
  font-size: 6rem;
  color: rgba(255, 182, 193, 0.3);
  user-select: none;
  animation: floatUpDown 6s ease-in-out infinite;
  font-weight: 900;
}

.landing-page::before {
  top: 10%;
  left: 8%;
  animation-delay: 0s;
}

.landing-page::after {
  bottom: 12%;
  right: 10%;
  font-size: 5rem;
  animation-delay: 3s;
}

@keyframes floatUpDown {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-20px); }
}
</style>
