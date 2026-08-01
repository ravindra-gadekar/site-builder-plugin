import { useEffect } from 'react';
import { initAnimations } from './animation-controller';

export function AnimationProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    initAnimations();
  }, []);

  return <>{children}</>;
}
