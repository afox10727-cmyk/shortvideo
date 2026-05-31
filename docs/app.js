// ═══════════════════════════════════════
// ShortVideo PWA - Application Logic
// ═══════════════════════════════════════

// ── State ──
let authMode = 'login';
let feedPage = 0;
let currentVideoIndex = 0;
let isRecording = false;
let mediaRecorder = null;
let recordedChunks = [];
let cameraStream = null;
let facingMode = 'environment';
let recordStartTime = 0;
let recordTimerInterval = null;

// ── Navigation ──
function navigate(screen) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const el = document.getElementById(screen + 'Screen');
  if (el) el.classList.add('active');

  // Update tab bar
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  const tabMap = { feed: 0, discover: 1, notify: 3, profile: 4 };
  if (tabMap[screen] !== undefined) {
    const bars = document.querySelectorAll('.tab-bar');
    bars.forEach(bar => {
      const btns = bar.querySelectorAll('.tab-btn');
      if (btns[tabMap[screen]]) btns[tabMap[screen]].classList.add('active');
    });
  }

  // Screen-specific init
  if (screen === 'feed') loadFeed();
  if (screen === 'profile') loadProfile();
  if (screen === 'notify') loadNotifications();
  if (screen === 'record') startCamera();
}

// ── Auth ──
function switchAuth(mode) {
  authMode = mode;
  document.querySelectorAll('.auth-tab').forEach((t, i) => {
    t.classList.toggle('active', (mode === 'login' && i === 0) || (mode === 'signup' && i === 1));
  });
  document.getElementById('signupFields').style.display = mode === 'signup' ? 'flex' : 'none';
  document.getElementById('authBtn').textContent = mode === 'login' ? '登录' : '注册';
  document.getElementById('authError').style.display = 'none';
}

async function doAuth() {
  if (window.isDemoMode) { quickDemo(); return; }

  const email = document.getElementById('emailInput').value.trim();
  const pass = document.getElementById('passInput').value.trim();
  const errEl = document.getElementById('authError');

  if (!email || !pass) { errEl.textContent = '请填写邮箱和密码'; errEl.style.display = 'block'; return; }

  try {
    if (authMode === 'login') {
      await signInWithEmailAndPassword(window.auth, email, pass);
    } else {
      const name = document.getElementById('signupName').value.trim();
      const username = document.getElementById('signupUsername').value.trim();
      if (!name || !username) { errEl.textContent = '请填写昵称和用户名'; errEl.style.display = 'block'; return; }
      const cred = await createUserWithEmailAndPassword(window.auth, email, pass);
      await setDoc(doc(window.db, 'users', cred.user.uid), {
        username, displayName: name, bio: '', email,
        followerCount: 0, followingCount: 0, videoCount: 0,
        createdAt: serverTimestamp(), updatedAt: serverTimestamp()
      });
      await setDoc(doc(window.db, 'usernames', username.toLowerCase()), { uid: cred.user.uid });
    }
  } catch(e) {
    errEl.textContent = '错误：' + (e.message || e);
    errEl.style.display = 'block';
  }
}

function quickDemo() {
  window.currentUser = { id: 'demo', username: 'demo_user', displayName: '体验用户', bio: '这是演示模式', followerCount: 0, followingCount: 0, videoCount: 0 };
  navigate('feed');
  showToast('⚡ 演示模式 - 可浏览界面，上传需配置 Firebase');
}

// Listen to auth state
if (!window.isDemoMode) {
  onAuthStateChanged(window.auth, async (user) => {
    if (user) {
      const snap = await getDoc(doc(window.db, 'users', user.uid));
      window.currentUser = { id: user.uid, ...snap.data() };
      window.currentUser = window.currentUser;
      navigate('feed');
    } else {
      window.currentUser = null;
      navigate('auth');
    }
  });
}

// ── Feed ──
async function loadFeed() {
  const container = document.getElementById('feedContainer');
  if (!container) return;

  if (window.isDemoMode) {
    container.innerHTML = generateDemoVideos();
    return;
  }

  try {
    const q = query(
      collection(window.db, 'videos'),
      where('processingStatus', '==', 'ready'),
      orderBy('createdAt', 'desc'),
      limit(10)
    );
    const snap = await getDocs(q);
    const videos = [];
    snap.forEach(doc => videos.push({ id: doc.id, ...doc.data() }));
    if (videos.length === 0) {
      container.innerHTML = generateDemoVideos();
      return;
    }
    container.innerHTML = videos.map((v, i) => createFeedItem(v, i)).join('');
  } catch(e) {
    console.error('Feed load error:', e);
    container.innerHTML = generateDemoVideos();
  }
}

function createFeedItem(video, index) {
  const capt = (video.caption || '').replace(/</g,'&lt;');
  const tags = (video.tags || []).map(t => `<span class="feed-tag">${t.replace(/</g,'&lt;')}</span>`).join('');
  const likes = formatCount(video.likeCount || 0);
  const comments = formatCount(video.commentCount || 0);
  const shares = formatCount(video.shareCount || 0);
  const username = video.userId ? '@user' : '@demo';

  return `
    <div class="feed-video" id="vid-${index}">
      ${video.thumbnailUrl
        ? `<img class="feed-video-inner" src="https://firebasestorage.googleapis.com/v0/b/${video.thumbnailUrl}?alt=media" loading="lazy">`
        : `<div class="feed-video-inner" style="background:linear-gradient(135deg,#${randomHex()},#${randomHex()});display:flex;align-items:center;justify-content:center"><span style="font-size:64px">🎬</span></div>`
      }
      <div class="feed-actions">
        <button class="feed-action" onclick="showToast('点赞')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"/></svg>
          <span>${likes}</span>
        </button>
        <button class="feed-action" onclick="showToast('评论')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
          <span>${comments}</span>
        </button>
        <button class="feed-action" onclick="shareVideo()">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.59 13.51l6.83 3.98M15.41 6.51l-6.82 3.98"/></svg>
          <span>${shares}</span>
        </button>
      </div>
      <div class="feed-info">
        <div class="feed-username">${username}</div>
        <div class="feed-caption">${capt || '无描述'}</div>
        <div class="feed-tags">${tags}</div>
      </div>
    </div>`;
}

function generateDemoVideos() {
  const demos = [
    { capt: '欢迎使用 ShortVideo！#短视频 #社交', tags: ['#短视频','#社交'], likes: 1234, comments: 56, shares: 7, color1: '1a1a3e', color2: '3e1a4a' },
    { capt: '这是一个演示视频 🎬', tags: ['#演示','#测试'], likes: 896, comments: 32, shares: 3, color1: '1a3e2a', color2: '2a3e5a' },
    { capt: '滑动查看更多内容 ↓', tags: ['#滑动','#浏览'], likes: 2456, comments: 128, shares: 15, color1: '3e1a1a', color2: '4a3e1a' },
    { capt: '配置 Firebase 后即可发布真实视频', tags: ['#Firebase','#PWA'], likes: 5678, comments: 234, shares: 42, color1: '1a2a3e', color2: '2a1a3e' },
  ];
  return demos.map((v, i) => `
    <div class="feed-video" id="vid-${i}">
      <div class="feed-video-inner" style="background:linear-gradient(135deg,#${v.color1},#${v.color2});display:flex;align-items:center;justify-content:center;flex-direction:column;gap:16px">
        <span style="font-size:80px">🎬</span>
        <span style="font-size:18px;color:rgba(255,255,255,.8)">${v.capt}</span>
      </div>
      ${createFeedActions(v.likes, v.comments, v.shares)}
      <div class="feed-info">
        <div class="feed-username">@demo_user</div>
        <div class="feed-caption">${v.capt}</div>
        <div class="feed-tags">${v.tags.map(t => `<span class="feed-tag">${t}</span>`).join('')}</div>
      </div>
    </div>`).join('');
}

function createFeedActions(likes, comments, shares) {
  return `<div class="feed-actions">
    <button class="feed-action" onclick="event.target.closest('.feed-action').classList.toggle('liked');showToast('点赞')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"/></svg>
      <span>${formatCount(likes)}</span>
    </button>
    <button class="feed-action" onclick="showToast('评论')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
      <span>${formatCount(comments)}</span>
    </button>
    <button class="feed-action" onclick="shareVideo()">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="M8.59 13.51l6.83 3.98M15.41 6.51l-6.82 3.98"/></svg>
      <span>${formatCount(shares)}</span>
    </button>
  </div>`;
}

function shareVideo() {
  if (navigator.share) {
    navigator.share({ title: 'ShortVideo', text: '来看这个视频！', url: window.location.href });
  } else {
    showToast('已复制链接');
  }
}

function switchFeedTab(btn, mode) {
  btn.parentElement.querySelectorAll('.feed-tab').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  showToast('切换到: ' + mode);
}

function onFeedScroll() {
  // Lazy loading logic
}

// ── Record ──
async function startCamera() {
  const video = document.getElementById('cameraPreview');
  if (!video) return;
  try {
    if (cameraStream) { stopCamera(); }
    cameraStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode, width: { ideal: 1080 }, height: { ideal: 1920 } },
      audio: true
    });
    video.srcObject = cameraStream;
    video.play();
  } catch(e) {
    console.error('Camera error:', e);
    showToast('无法访问相机，请在设置中允许');
  }
}

function stopCamera() {
  if (cameraStream) {
    cameraStream.getTracks().forEach(t => t.stop());
    cameraStream = null;
  }
  if (recordTimerInterval) { clearInterval(recordTimerInterval); recordTimerInterval = null; }
}

function flipCamera() {
  facingMode = facingMode === 'user' ? 'environment' : 'user';
  stopCamera();
  startCamera();
}

function toggleRecording() {
  if (isRecording) {
    stopRecording();
  } else {
    startRecording();
  }
}

function startRecording() {
  if (!cameraStream) return;
  recordedChunks = [];
  try {
    mediaRecorder = new MediaRecorder(cameraStream, { mimeType: 'video/mp4' });
  } catch(e) {
    // Fallback for browsers that don't support mp4
    mediaRecorder = new MediaRecorder(cameraStream);
  }

  mediaRecorder.ondataavailable = e => { if (e.data.size > 0) recordedChunks.push(e.data); };
  mediaRecorder.onstop = () => {
    const blob = new Blob(recordedChunks, { type: 'video/mp4' });
    window.recordedBlob = blob;
    document.getElementById('uploadModal').classList.add('active');
  };

  mediaRecorder.start();
  isRecording = true;
  recordStartTime = Date.now();
  document.getElementById('recordBtn').classList.add('recording');
  document.getElementById('recordTimer').style.display = 'flex';

  recordTimerInterval = setInterval(() => {
    const elapsed = Math.floor((Date.now() - recordStartTime) / 1000);
    if (elapsed >= 180) { stopRecording(); return; }
    document.getElementById('timerText').textContent =
      `${String(Math.floor(elapsed/60)).padStart(2,'0')}:${String(elapsed%60).padStart(2,'0')}`;
  }, 200);
}

function stopRecording() {
  if (!mediaRecorder || mediaRecorder.state === 'inactive') return;
  mediaRecorder.stop();
  isRecording = false;
  document.getElementById('recordBtn').classList.remove('recording');
  document.getElementById('recordTimer').style.display = 'none';
  if (recordTimerInterval) { clearInterval(recordTimerInterval); recordTimerInterval = null; }
}

async function publishVideo() {
  if (window.isDemoMode) {
    showToast('演示模式不支持上传，请先配置 Firebase');
    document.getElementById('uploadModal').classList.remove('active');
    return;
  }

  const blob = window.recordedBlob;
  if (!blob) { showToast('没有可上传的视频'); return; }

  const caption = document.getElementById('uploadCaption').value.trim();
  const tags = document.getElementById('uploadTags').value.split(/\\s+/).filter(Boolean).map(t => t.startsWith('#') ? t : '#' + t);

  const btn = document.getElementById('publishBtn');
  btn.disabled = true; btn.textContent = '上传中...';

  const progressBar = document.getElementById('progressBar');
  const progressFill = document.getElementById('progressFill');
  progressBar.style.display = 'block'; progressFill.style.width = '0%';

  try {
    const user = window.currentUser;
    // Create video doc
    const docRef = await addDoc(collection(window.db, 'videos'), {
      userId: user.id, caption, tags,
      videoUrl: null, thumbnailUrl: null,
      duration: 0, width: 0, height: 0,
      likeCount: 0, commentCount: 0, shareCount: 0, viewCount: 0,
      processingStatus: 'uploading', isPrivate: false,
      createdAt: serverTimestamp(), updatedAt: serverTimestamp()
    });
    const videoId = docRef.id;

    // Upload
    const storagePath = `videos/raw/${user.id}/${videoId}.mp4`;
    const storageRef = ref(window.storage, storagePath);
    const uploadTask = uploadBytesResumable(storageRef, blob);

    uploadTask.on('state_changed',
      (snap) => {
        const pct = Math.round((snap.bytesTransferred / snap.totalBytes) * 100);
        progressFill.style.width = pct + '%';
      },
      (err) => { showToast('上传失败: ' + err.message); btn.disabled = false; btn.textContent = '发布'; },
      async () => {
        await updateDoc(docRef, {
          videoUrl: storagePath,
          processingStatus: 'processing',
          updatedAt: serverTimestamp()
        });
        showToast('发布成功！视频正在处理中');
        document.getElementById('uploadModal').classList.remove('active');
        progressBar.style.display = 'none';
        btn.disabled = false; btn.textContent = '发布';
        document.getElementById('uploadCaption').value = '';
        document.getElementById('uploadTags').value = '';
        navigate('feed');
      }
    );
  } catch(e) {
    showToast('发布失败: ' + e.message);
    btn.disabled = false; btn.textContent = '发布';
  }
}

// ── Profile ──
function loadProfile() {
  if (!window.currentUser) return;
  document.getElementById('profileName').textContent = window.currentUser.username || 'demo_user';
  document.getElementById('profileBio').textContent = window.currentUser.bio || '这个人很懒，什么都没写';
  document.getElementById('profileVideos').textContent = formatCount(window.currentUser.videoCount || 0);
  document.getElementById('profileFollowers').textContent = formatCount(window.currentUser.followerCount || 0);
  document.getElementById('profileFollowing').textContent = formatCount(window.currentUser.followingCount || 0);
}

// ── Notifications ──
async function loadNotifications() {
  if (window.isDemoMode || !window.currentUser) return;
  try {
    const q = query(
      collection(window.db, 'notifications'),
      where('recipientId', '==', window.currentUser.id),
      orderBy('createdAt', 'desc'),
      limit(30)
    );
    const snap = await getDocs(q);
    const container = document.getElementById('notifyList');
    if (!container) return;
    if (snap.empty) {
      container.innerHTML = '<div style="text-align:center;padding:40px;color:var(--text2)">暂无通知</div>';
      return;
    }
    container.innerHTML = '';
    snap.forEach(doc => {
      const n = doc.data();
      const icons = { like: '❤️', comment: '💬', follow: '👤', video_processed: '✅' };
      const bg = { like: 'rgba(255,59,48,.2)', comment: 'rgba(0,122,255,.2)', follow: 'rgba(52,199,89,.2)', video_processed: 'rgba(175,82,222,.2)' };
      const div = document.createElement('div');
      div.className = 'notify-item';
      div.innerHTML = `
        <div class="notify-icon" style="background:${bg[n.type]||'rgba(255,255,255,.1)'}">${icons[n.type]||'🔔'}</div>
        <div class="notify-text"><div class="title">${n.message||''}</div><div class="time">刚刚</div></div>
        ${n.isRead?'':'<div class="notify-dot"></div>'}
      `;
      container.appendChild(div);
    });
  } catch(e) { console.error('Notification load error:', e); }
}

// ── Utilities ──
function formatCount(n) {
  if (n >= 1e6) return (n/1e6).toFixed(1) + 'M';
  if (n >= 1e3) return (n/1e3).toFixed(1) + 'K';
  return String(n);
}

function randomHex() { return Math.floor(Math.random()*16777215).toString(16).padStart(6,'0'); }

function showToast(msg) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = msg;
  toast.classList.add('show');
  clearTimeout(window._toastTimer);
  window._toastTimer = setTimeout(() => toast.classList.remove('show'), 2000);
}

// ── Service Worker ──
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(() => {});
}

// ── Offline detection ──
window.addEventListener('online', () => document.getElementById('offlineBar')?.classList.add('hidden'));
window.addEventListener('offline', () => document.getElementById('offlineBar')?.classList.remove('hidden'));

// ── Sign Out ──
function signOutUser() {
  if (!window.isDemoMode && window.auth) {
    signOut(window.auth);
  }
  window.currentUser = null;
  navigate('auth');
  showToast('已退出登录');
}

// ── Search ──
async function searchUsers(query) {
  if (window.isDemoMode || !query.trim() || !window.db) return;
  try {
    const q = query(
      collection(window.db, 'users'),
      where('username', '>=', query.toLowerCase()),
      where('username', '<', query.toLowerCase() + ''),
      limit(10)
    );
    const snap = await getDocs(q);
    const container = document.getElementById('searchResults');
    if (!container) return;
    if (snap.empty) {
      container.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text2)">未找到用户</div>';
      return;
    }
    container.innerHTML = snap.docs.map(d => {
      const u = d.data();
      return `<div style="display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid rgba(255,255,255,.04)">
        <div style="width:44px;height:44px;border-radius:50%;background:linear-gradient(135deg,#FF2D55,#8B5CF6);display:flex;align-items:center;justify-content:center;font-size:20px">${(u.username||'?')[0].toUpperCase()}</div>
        <div><div style="font-size:15px">${u.displayName||''}</div><div style="color:var(--text2);font-size:13px">@${u.username||''}</div></div>
      </div>`;
    }).join('');
  } catch(e) { console.error('Search error:', e); }
}

// ── Init ──
document.addEventListener('DOMContentLoaded', () => {
  if (window.currentUser) {
    navigate('feed');
  } else {
    navigate('auth');
  }
});
