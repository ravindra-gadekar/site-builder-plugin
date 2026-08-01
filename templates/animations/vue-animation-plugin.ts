import { initAnimations } from './animation-controller';

export default defineNuxtPlugin(() => {
  if (import.meta.client) {
    onNuxtReady(() => {
      initAnimations();
    });
  }
});
