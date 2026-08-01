'use client';

import { useRef, useState, useCallback } from 'react';

interface VideoPlayerProps {
  src: string;
  poster: string;
  title: string;
  aspectRatio?: string;
  autoplay?: boolean;
}

export function VideoPlayer({
  src,
  poster,
  title,
  aspectRatio = '16/9',
  autoplay = false,
}: VideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [playing, setPlaying] = useState(false);

  const handlePointerOver = useCallback(() => {
    if (videoRef.current && videoRef.current.preload === 'none') {
      videoRef.current.preload = 'metadata';
    }
  }, []);

  const handlePlay = useCallback(() => {
    if (videoRef.current) {
      videoRef.current.preload = 'auto';
      videoRef.current.controls = true;
      videoRef.current.play();
      setPlaying(true);
    }
  }, []);

  const containerStyle: React.CSSProperties = {
    position: 'relative', width: '100%', overflow: 'hidden',
    aspectRatio, borderRadius: 'var(--video-border-radius, 0.5rem)', background: '#000',
  };

  if (autoplay) {
    return (
      <div style={containerStyle}>
        <video
          src={src}
          poster={poster}
          autoPlay
          muted
          loop
          playsInline
          preload="auto"
          aria-label={title}
          style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
        />
      </div>
    );
  }

  return (
    <div style={containerStyle} onPointerOver={handlePointerOver}>
      <video
        ref={videoRef}
        src={src}
        poster={poster}
        playsInline
        preload="none"
        aria-label={title}
        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
      />
      {!playing && (
        <button
          onClick={handlePlay}
          aria-label={`Play video: ${title}`}
          type="button"
          style={{
            position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
            padding: 0, border: 'none', background: 'transparent', cursor: 'pointer',
          }}
        >
          <span aria-hidden="true" style={{ filter: 'drop-shadow(0 2px 8px rgba(0,0,0,0.3))' }}>
            <svg viewBox="0 0 68 48" width="68" height="48">
              <path d="M66.52 7.74c-.78-2.93-2.49-5.41-5.42-6.19C55.79.13 34 0 34 0S12.21.13 6.9 1.55C3.97 2.33 2.27 4.81 1.48 7.74.06 13.05 0 24 0 24s.06 10.95 1.48 16.26c.78 2.93 2.49 5.41 5.42 6.19C12.21 47.87 34 48 34 48s21.79-.13 27.1-1.55c2.93-.78 4.64-3.26 5.42-6.19C67.94 34.95 68 24 68 24s-.06-10.95-1.48-16.26z" fill="var(--play-btn-bg, #f97316)"/>
              <path d="M45 24L27 14v20" fill="#fff"/>
            </svg>
          </span>
        </button>
      )}
    </div>
  );
}
