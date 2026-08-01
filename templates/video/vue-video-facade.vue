<script setup lang="ts">
import { ref, computed } from 'vue';

const props = withDefaults(defineProps<{
  src: string;
  poster: string;
  title: string;
  aspectRatio?: string;
}>(), {
  aspectRatio: '16/9',
});

const playing = ref(false);
const preconnected = ref(false);

const embedUrl = computed(() => {
  const ytMatch = props.src.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
  if (ytMatch) return `https://www.youtube-nocookie.com/embed/${ytMatch[1]}?autoplay=1`;
  const vimeoMatch = props.src.match(/vimeo\.com\/(\d+)/);
  if (vimeoMatch) return `https://player.vimeo.com/video/${vimeoMatch[1]}?autoplay=1`;
  return props.src;
});

const preconnectUrl = computed(() => {
  if (props.src.includes('youtube') || props.src.includes('youtu.be')) return 'https://www.youtube-nocookie.com';
  if (props.src.includes('vimeo')) return 'https://player.vimeo.com';
  return '';
});

function handlePointerOver() {
  if (!preconnected.value && preconnectUrl.value) {
    const link = document.createElement('link');
    link.rel = 'preconnect';
    link.href = preconnectUrl.value;
    document.head.appendChild(link);
    preconnected.value = true;
  }
}

function play() {
  playing.value = true;
}
</script>

<template>
  <div
    class="video-facade"
    :style="{ aspectRatio }"
    @pointerover="handlePointerOver"
  >
    <iframe
      v-if="playing"
      :src="embedUrl"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen
      class="video-facade__iframe"
    />
    <button
      v-else
      class="video-facade__trigger"
      :aria-label="`Play video: ${title}`"
      type="button"
      @click="play"
    >
      <img
        :src="poster"
        :alt="`Video thumbnail: ${title}`"
        class="video-facade__poster"
        loading="lazy"
        decoding="async"
      />
      <span class="video-facade__play" aria-hidden="true">
        <svg viewBox="0 0 68 48" width="68" height="48">
          <path d="M66.52 7.74c-.78-2.93-2.49-5.41-5.42-6.19C55.79.13 34 0 34 0S12.21.13 6.9 1.55C3.97 2.33 2.27 4.81 1.48 7.74.06 13.05 0 24 0 24s.06 10.95 1.48 16.26c.78 2.93 2.49 5.41 5.42 6.19C12.21 47.87 34 48 34 48s21.79-.13 27.1-1.55c2.93-.78 4.64-3.26 5.42-6.19C67.94 34.95 68 24 68 24s-.06-10.95-1.48-16.26z" fill="var(--play-btn-bg, #f97316)"/>
          <path d="M45 24L27 14v20" fill="#fff"/>
        </svg>
      </span>
    </button>
  </div>
</template>

<style scoped>
.video-facade {
  position: relative;
  width: 100%;
  overflow: hidden;
  border-radius: var(--video-border-radius, 0.5rem);
  background: #000;
}
.video-facade__trigger {
  display: block;
  width: 100%;
  height: 100%;
  padding: 0;
  border: none;
  cursor: pointer;
  position: relative;
}
.video-facade__poster {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.video-facade__play {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: var(--play-btn-size, 4rem);
  height: auto;
  filter: drop-shadow(0 2px 8px rgba(0,0,0,0.3));
  transition: transform 150ms ease-out;
}
.video-facade__trigger:hover .video-facade__play {
  transform: translate(-50%, -50%) scale(1.1);
}
.video-facade__iframe {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  border: none;
}
</style>
