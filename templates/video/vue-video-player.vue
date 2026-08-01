<script setup lang="ts">
import { ref } from 'vue';

const props = withDefaults(defineProps<{
  src: string;
  poster: string;
  title: string;
  aspectRatio?: string;
  autoplay?: boolean;
}>(), {
  aspectRatio: '16/9',
  autoplay: false,
});

const videoEl = ref<HTMLVideoElement | null>(null);
const playing = ref(false);

function handlePointerOver() {
  if (videoEl.value && videoEl.value.preload === 'none') {
    videoEl.value.preload = 'metadata';
  }
}

function handlePlay() {
  if (videoEl.value) {
    videoEl.value.preload = 'auto';
    videoEl.value.controls = true;
    videoEl.value.play();
    playing.value = true;
  }
}
</script>

<template>
  <div
    class="video-player"
    :class="{ 'video-player--autoplay': autoplay }"
    :style="{ aspectRatio }"
    @pointerover="handlePointerOver"
  >
    <template v-if="autoplay">
      <video
        :src="src"
        :poster="poster"
        autoplay
        muted
        loop
        playsinline
        preload="auto"
        :aria-label="title"
        class="video-player__video"
      />
    </template>
    <template v-else>
      <video
        ref="videoEl"
        :src="src"
        :poster="poster"
        playsinline
        preload="none"
        :aria-label="title"
        class="video-player__video"
      />
      <button
        v-if="!playing"
        class="video-player__trigger"
        :aria-label="`Play video: ${title}`"
        type="button"
        @click="handlePlay"
      >
        <span class="video-player__play" aria-hidden="true">
          <svg viewBox="0 0 68 48" width="68" height="48">
            <path d="M66.52 7.74c-.78-2.93-2.49-5.41-5.42-6.19C55.79.13 34 0 34 0S12.21.13 6.9 1.55C3.97 2.33 2.27 4.81 1.48 7.74.06 13.05 0 24 0 24s.06 10.95 1.48 16.26c.78 2.93 2.49 5.41 5.42 6.19C12.21 47.87 34 48 34 48s21.79-.13 27.1-1.55c2.93-.78 4.64-3.26 5.42-6.19C67.94 34.95 68 24 68 24s-.06-10.95-1.48-16.26z" fill="var(--play-btn-bg, #f97316)"/>
            <path d="M45 24L27 14v20" fill="#fff"/>
          </svg>
        </span>
      </button>
    </template>
  </div>
</template>

<style scoped>
.video-player {
  position: relative;
  width: 100%;
  overflow: hidden;
  border-radius: var(--video-border-radius, 0.5rem);
  background: #000;
}
.video-player__video {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.video-player__trigger {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  border: none;
  background: transparent;
  cursor: pointer;
}
.video-player__play {
  filter: drop-shadow(0 2px 8px rgba(0,0,0,0.3));
  transition: transform 150ms ease-out;
}
.video-player__trigger:hover .video-player__play {
  transform: scale(1.1);
}
</style>
