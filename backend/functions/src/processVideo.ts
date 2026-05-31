/**
 * processVideoOnUpload
 *
 * Trigger: Firestore onDocumentCreated on videos/{videoId}
 * Downloads raw MP4, transcodes to HLS (3 bitrates), extracts thumbnail,
 * uploads outputs, updates Firestore with metadata.
 */
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { videosRef, storage } from './utils/firebase.js';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs/promises';
import { spawn } from 'child_process';

// HLS output resolutions: name, width, height, bitrate
const RESOLUTIONS = [
  { name: 'v0', width: 426, height: 854, bitrate: '800k' },
  { name: 'v1', width: 720, height: 1280, bitrate: '2000k' },
  { name: 'v2', width: 1080, height: 1920, bitrate: '4000k' },
];

export const processVideoOnUpload = onDocumentCreated(
  {
    document: 'videos/{videoId}',
    region: 'us-central1',
    memory: '2GiB',
    timeoutSeconds: 540, // 9 minutes
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const videoData = snapshot.data();
    const videoId = event.params.videoId;

    if (videoData.processingStatus !== 'processing') {
      console.log(`Video ${videoId} not in processing state, skipping`);
      return;
    }

    const tmpDir = path.join(os.tmpdir(), videoId);
    const rawPath = path.join(tmpDir, 'input.mp4');
    const outputDir = path.join(tmpDir, 'output');

    try {
      console.log(`Starting HLS transcode for video ${videoId}`);

      // 1. Create temp directories
      await fs.mkdir(tmpDir, { recursive: true });
      await fs.mkdir(outputDir, { recursive: true });

      // 2. Download raw video from Storage
      const rawVideoPath = videoData.videoUrl;
      if (!rawVideoPath) throw new Error('No video URL in document');

      const bucket = storage.bucket();
      console.log(`Downloading from: ${rawVideoPath}`);
      await bucket.file(rawVideoPath).download({ destination: rawPath });
      console.log('Download complete');

      // 3. Get video metadata via ffprobe
      const metadata = await getVideoMetadata(rawPath);
      console.log('Video metadata:', metadata);

      // 4. Extract thumbnail frame at 1s
      const thumbnailPath = path.join(tmpDir, 'thumbnail.jpg');
      await runFFmpeg([
        '-ss', '00:00:01',
        '-i', rawPath,
        '-vframes', '1',
        '-q:v', '2',
        '-y',
        thumbnailPath,
      ]);

      // 5. Transcode to HLS with 3 quality levels
      // Build filter_complex for splitting video into 3 resolutions
      const filterParts = RESOLUTIONS.map((r, i) =>
        `[v:0]scale=w=${r.width}:h=${r.height}[v${i}out]`
      );

      const args = [
        '-i', rawPath,
        '-filter_complex',
        `[0:v]split=3[v0][v1][v2];` +
        `[v0]scale=w=426:h=854[v0out];` +
        `[v1]scale=w=720:h=1280[v1out];` +
        `[v2]scale=w=1080:h=1920[v2out]`,
        '-map', '[v0out]', '-c:v:0', 'libx264', '-b:v:0', '800k',
        '-maxrate:v:0', '856k', '-bufsize:v:0', '1200k',
        '-map', '[v1out]', '-c:v:1', 'libx264', '-b:v:1', '2000k',
        '-maxrate:v:1', '2140k', '-bufsize:v:1', '3000k',
        '-map', '[v2out]', '-c:v:2', 'libx264', '-b:v:2', '4000k',
        '-maxrate:v:2', '4280k', '-bufsize:v:2', '6000k',
        '-map', 'a:0', '-c:a', 'aac', '-b:a', '128k', '-ac', '2',
        '-f', 'hls',
        '-hls_time', '6',
        '-hls_list_size', '0',
        '-hls_segment_filename', path.join(outputDir, 'v%v', 'segment_%03d.ts'),
        '-master_pl_name', 'master.m3u8',
        '-var_stream_map', 'v:0,a:0 v:1,a:0 v:2,a:0',
        '-hls_flags', 'independent_segments',
        '-y',
        path.join(outputDir, 'v%v', 'playlist.m3u8'),
      ];

      console.log('Running ffmpeg transcode...');
      await runFFmpeg(args);
      console.log('Transcoding complete');

      // 6. Upload outputs to Storage
      const processedPrefix = `videos/processed/${videoId}`;

      // Upload thumbnail
      await bucket.upload(thumbnailPath, {
        destination: `thumbnails/${videoId}.jpg`,
        metadata: { contentType: 'image/jpeg' },
      });
      console.log('Thumbnail uploaded');

      // Upload master playlist
      const masterPath = path.join(outputDir, 'master.m3u8');
      await bucket.upload(masterPath, {
        destination: `${processedPrefix}/master.m3u8`,
        metadata: { contentType: 'application/vnd.apple.mpegurl' },
      });

      // Upload all variant playlists and segments
      for (const res of RESOLUTIONS) {
        const variantDir = path.join(outputDir, res.name);
        const files = await fs.readdir(variantDir, { recursive: true });
        for (const file of files) {
          const localPath = path.join(variantDir, file);
          const remotePath = `${processedPrefix}/${res.name}/${file}`;
          const ext = path.extname(file).toLowerCase();
          await bucket.upload(localPath, {
            destination: remotePath,
            metadata: {
              contentType: ext === '.m3u8'
                ? 'application/vnd.apple.mpegurl'
                : 'video/mp2t',
            },
          });
        }
      }
      console.log('All HLS segments uploaded');

      // 7. Update Firestore
      await videosRef.doc(videoId).update({
        processingStatus: 'ready',
        videoUrl: `${processedPrefix}/master.m3u8`,
        thumbnailUrl: `thumbnails/${videoId}.jpg`,
        duration: metadata.duration,
        width: metadata.width,
        height: metadata.height,
        aspectRatio: metadata.width / metadata.height,
        updatedAt: new Date(),
      });

      console.log(`Video ${videoId} processed successfully`);

      // 8. Clean up raw file and temp dir
      try { await bucket.file(rawVideoPath).delete(); } catch { /* ok */ }
      await fs.rm(tmpDir, { recursive: true, force: true });

    } catch (error) {
      console.error(`Failed to process video ${videoId}:`, error);

      await videosRef.doc(videoId).update({
        processingStatus: 'failed',
        updatedAt: new Date(),
      });
    }
  }
);

// ── Helpers ──

interface VideoMetadata {
  duration: number;
  width: number;
  height: number;
}

function getVideoMetadata(filePath: string): Promise<VideoMetadata> {
  return new Promise((resolve, reject) => {
    const proc = spawn('ffprobe', [
      '-v', 'quiet',
      '-print_format', 'json',
      '-show_format',
      '-show_streams',
      filePath,
    ]);

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data: Buffer) => { stdout += data.toString(); });
    proc.stderr.on('data', (data: Buffer) => { stderr += data.toString(); });

    proc.on('close', (code: number) => {
      if (code !== 0) {
        reject(new Error(`ffprobe exited with code ${code}: ${stderr}`));
        return;
      }

      try {
        const parsed = JSON.parse(stdout);
        const videoStream = parsed.streams.find(
          (s: any) => s.codec_type === 'video'
        );

        resolve({
          duration: parseFloat(parsed.format?.duration ?? '0'),
          width: videoStream?.width ?? 1080,
          height: videoStream?.height ?? 1920,
        });
      } catch (e) {
        reject(new Error(`Failed to parse ffprobe output: ${e}`));
      }
    });

    proc.on('error', reject);
  });
}

function runFFmpeg(args: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn('ffmpeg', args);

    proc.stderr.on('data', (data: Buffer) => {
      // ffmpeg logs to stderr by default
      const msg = data.toString();
      if (msg.includes('frame=') || msg.includes('error', msg.includes('Error'))) {
        console.log(msg.trim());
      }
    });

    proc.on('close', (code: number) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`ffmpeg exited with code ${code}`));
      }
    });

    proc.on('error', reject);
  });
}
