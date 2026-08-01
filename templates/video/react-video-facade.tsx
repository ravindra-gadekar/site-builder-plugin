import { useState, useCallback } from 'react';

interface VideoFacadeProps {
  src: string;
  poster: string;
  title: string;
  aspectRatio?: string;
}

function getEmbedUrl(url: string): string {
  const ytMatch = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
  if (ytMatch) return `https://www.youtube-nocookie.com/embed/${ytMatch[1]}?autoplay=1`;
  const vimeoMatch = url.match(/vimeo\.com\/(\d+)/);
  if (vimeoMatch) return `https://player.vimeo.com/video/${vimeoMatch[1]}?autoplay=1`;
  return url;
}

function getPreconnectUrl(url: string): string {
  if (url.includes('youtube') || url.includes('youtu.be')) return 'https://www.youtube-nocookie.com';
  if (url.includes('vimeo')) return 'https://player.vimeo.com';
  return '';
}

export function VideoFacade({
  src,
  poster,
  title,
  aspectRatio = '16/9',
}: VideoFacadeProps) {
  const [playing, setPlaying] = useState(false);
  const [preconnected, setPreconnected] = useState(false);
  const embedUrl = getEmbedUrl(src);
  const preconnectUrl = getPreconnectUrl(src);

  const handlePointerOver = useCallback(() => {
    if (!preconnected && preconnectUrl) {
      const link = document.createElement('link');
      link.rel = 'preconnect';
      link.href = preconnectUrl;
      document.head.appendChild(link);
      setPreconnected(true);
    }
  }, [preconnected, preconnectUrl]);

  return (
    <div
      className="video-facade"
      style={{ aspectRatio, position: 'relative', overflow: 'hidden', borderRadius: 'var(--video-border-radius, 0.5rem)', background: '#000' }}
      onPointerOver={handlePointerOver}
    >
      {playing ? (
        <iframe
          src={embedUrl}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
          style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', border: 'none' }}
        />
      ) : (
        <button
          onClick={() => setPlaying(true)}
          aria-label={`Play video: ${title}`}
          type="button"
          style={{ display: 'block', width: '100%', height: '100%', padding: 0, border: 'none', cursor: 'pointer', position: 'relative' }}
        >
          <img
            src={poster}
            alt={`Video thumbnail: ${title}`}
            style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
            loading="lazy"
            decoding="async"
          />
          <span
            aria-hidden="true"
            style={{
              position: 'absolute', top: '50%', left: '50%',
              transform: 'translate(-50%, -50%)',
              width: 'var(--play-btn-size, 4rem)',
              filter: 'drop-shadow(0 2px 8px rgba(0,0,0,0.3))',
            }}
          >
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
