import React, { useEffect, useState } from 'react';
import { AppLayout } from '../components/layout/AppLayout';
import { Volume2, Play, Pause, Download, Calendar, FileAudio } from 'lucide-react';
import { apiClient } from '../api/client';
import { useToastStore } from '../store/toastStore';
import type { AudioOutput } from '../api/types';

export const AudioPage: React.FC = () => {
  const [audioFiles, setAudioFiles] = useState<AudioOutput[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [playingId, setPlayingId] = useState<string | null>(null);
  const [currentAudio, setCurrentAudio] = useState<HTMLAudioElement | null>(null);
  const toastStore = useToastStore();

  useEffect(() => {
    fetchAudioFiles();
  }, []);

  const fetchAudioFiles = async () => {
    try {
      setIsLoading(true);
      const files = await apiClient.getAudioFiles();
      setAudioFiles(files);
    } catch (error) {
      console.error('Failed to fetch audio files:', error);
      toastStore.addToast('Failed to load audio files', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePlay = (audio: AudioOutput) => {
    // Stop any currently playing audio
    if (currentAudio) {
      currentAudio.pause();
      currentAudio.currentTime = 0;
    }

    if (playingId === audio.id) {
      // Toggle pause
      setPlayingId(null);
      setCurrentAudio(null);
    } else {
      // Play new audio
      const audioElement = new Audio(apiClient.getAudioFileUrl(audio.id));
      audioElement.play();
      audioElement.onended = () => {
        setPlayingId(null);
        setCurrentAudio(null);
      };
      setPlayingId(audio.id);
      setCurrentAudio(audioElement);
    }
  };

  const handleDownload = (audio: AudioOutput) => {
    const url = apiClient.getAudioFileUrl(audio.id);
    const a = document.createElement('a');
    a.href = url;
    a.download = `audio_${audio.id}.mp3`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    toastStore.addToast('Audio download started', 'success');
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - date.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return `Today at ${date.toLocaleTimeString()}`;
    if (diffDays === 1) return `Yesterday at ${date.toLocaleTimeString()}`;
    if (diffDays < 7) return `${diffDays} days ago`;
    return date.toLocaleString();
  };

  const formatFileSize = (bytes?: number) => {
    if (!bytes) return 'Unknown size';
    const mb = bytes / (1024 * 1024);
    return `${mb.toFixed(2)} MB`;
  };

  if (isLoading) {
    return (
      <AppLayout headerTitle="Audio Files">
        <div className="flex items-center justify-center h-full">
          <p className="text-text-tertiary">Loading audio files...</p>
        </div>
      </AppLayout>
    );
  }

  if (audioFiles.length === 0) {
    return (
      <AppLayout headerTitle="Audio Files">
        <div className="flex flex-col items-center justify-center h-full text-center p-6">
          <Volume2 className="h-12 w-12 text-text-tertiary mb-4" />
          <p className="text-text-secondary mb-2">No audio files yet</p>
          <p className="text-sm text-text-tertiary">
            Generate audio from your chats using the TTS button
          </p>
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout headerTitle="Audio Files">
      <div className="space-y-3">
        {audioFiles.map((audio) => {
          const isPlaying = playingId === audio.id;
          
          return (
            <div
              key={audio.id}
              className="bg-bg-card rounded-lg border border-bg-muted p-3"
            >
              <div className="flex items-center justify-between gap-3">
                <div className="flex items-center gap-3 flex-1 min-w-0">
                  <button
                    onClick={() => handlePlay(audio)}
                    className="flex-shrink-0 w-10 h-10 rounded-full bg-primary hover:bg-primary-accent flex items-center justify-center transition-colors"
                  >
                    {isPlaying ? (
                      <Pause className="h-4 w-4 text-white" />
                    ) : (
                      <Play className="h-4 w-4 text-white ml-0.5" />
                    )}
                  </button>
                  
                  <div className="flex-1 min-w-0">
                    <h3 className="text-sm font-medium text-text-primary truncate">
                      {audio.description || 'Chat Audio'}
                    </h3>
                    <div className="flex items-center gap-3 text-xs text-text-tertiary mt-0.5">
                      <div className="flex items-center gap-1">
                        <Calendar className="h-3 w-3" />
                        {formatDate(audio.created_at)}
                      </div>
                      {audio.file_size && (
                        <div className="flex items-center gap-1">
                          <FileAudio className="h-3 w-3" />
                          {formatFileSize(audio.file_size)}
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-1">
                  <button
                    onClick={() => handleDownload(audio)}
                    className="p-2 rounded-lg hover:bg-primary/10 text-primary transition-colors"
                    aria-label="Download audio"
                    title="Download audio file"
                  >
                    <Download className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </AppLayout>
  );
};

