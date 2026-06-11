import ketai.net.bluetooth.*;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.app.Activity;
import android.content.pm.PackageManager;
import java.util.Set;
import java.util.ArrayList;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.media.MediaPlayer;
import android.content.res.AssetFileDescriptor;
import android.os.Vibrator;
import android.os.VibrationEffect;

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREENS
// ═══════════════════════════════════════════════════════════════════════════════
final int SCREEN_START     = 0;
final int SCREEN_MODE      = 1;
final int SCREEN_PLAYER    = 2;
final int SCREEN_PLAYER_P2 = 3;
final int SCREEN_READY     = 4;
final int SCREEN_COUNTDOWN = 5;
final int SCREEN_GAME      = 6;
final int SCREEN_END       = 7;
int currentScreen = SCREEN_START;
boolean imagesPrerendered = false;

// ═══════════════════════════════════════════════════════════════════════════════
//  MODE
// ═══════════════════════════════════════════════════════════════════════════════
final int MODE_SINGLE = 0;
final int MODE_MULTI  = 1;
int gameMode = MODE_SINGLE;

// ═══════════════════════════════════════════════════════════════════════════════
//  PLAYER
// ═══════════════════════════════════════════════════════════════════════════════
final int MESSI   = 0;
final int RONALDO = 1;
int chosenPlayer  = -1;

// ═══════════════════════════════════════════════════════════════════════════════
//  LOCK-IN ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════
boolean lockInActive  = false;
long    lockInStartMs = 0;
final int LOCK_IN_DUR = 2200;

// ═══════════════════════════════════════════════════════════════════════════════
//  VS ANIMATION (multi)
// ═══════════════════════════════════════════════════════════════════════════════
boolean vsAnimActive  = false;
long    vsAnimStartMs = 0;
final int VS_ANIM_DUR = 2800;

// ═══════════════════════════════════════════════════════════════════════════════
//  IMAGES
// ═══════════════════════════════════════════════════════════════════════════════
PImage bgImage;
PImage messiPhoto,         ronaldoPhoto;
PImage messiPhotoRounded,  ronaldoPhotoRounded;
PImage messiPhotoCircle,   ronaldoPhotoCircle;
PImage messiPhotoCircleSm, ronaldoPhotoCircleSm;
PImage messiCardTex,       ronaldoCardTex;

// Per-event title card photos
// Add messi_celeb.png / messi_sad.png / ronaldo_celeb.png / ronaldo_sad.png
// to your sketch data folder. Falls back to default photo if missing.
PImage messiCelebPhoto,   ronaldoCelebPhoto;
PImage messiSadPhoto,     ronaldoSadPhoto;

// ═══════════════════════════════════════════════════════════════════════════════
//  SOUND
// ═══════════════════════════════════════════════════════════════════════════════
SoundPool soundPool;
MediaPlayer bgPlayer;
int sndStartId, sndScoreId, sndMissId, sndNegId, sndStopId, sndCountId;
boolean soundReady = false;

String[] bgTrackFiles = {"bg_music.mp3", "bg_music2.mp3", "bg_music3.mp3"};
int      bgTrackIndex = 0;
boolean  bgDucked     = false;
final float BG_VOL_FULL = 1.0f;
final float BG_VOL_DUCK = 0.25f;

// ═══════════════════════════════════════════════════════════════════════════════
//  VIBRATION
// ═══════════════════════════════════════════════════════════════════════════════
Vibrator vibrator;

// ═══════════════════════════════════════════════════════════════════════════════
//  BLUETOOTH
// ═══════════════════════════════════════════════════════════════════════════════
KetaiBluetooth bt;
boolean        btActive   = false;
String         statusMsg  = "NOT CONNECTED";
String         lineBuffer = "";
java.io.OutputStream btOut = null;
static final int BT_PERM_REQUEST = 42;
boolean permissionsGranted = false;
boolean showPicker = false;
ArrayList<BluetoothDevice> pairedDevices = new ArrayList<BluetoothDevice>();
float pickerY, pickerRowH, pickerW, pickerX;

// ═══════════════════════════════════════════════════════════════════════════════
//  GAME STATE
// ═══════════════════════════════════════════════════════════════════════════════
int     score       = 0;
int     score2      = 0;
int     highScore   = 0;
boolean gameRunning = false;
boolean stopPending = false;

float scoreColorR  = 230, scoreColorG  = 238, scoreColorB  = 245;
float score2ColorR = 230, score2ColorG = 238, score2ColorB = 245;

// ═══════════════════════════════════════════════════════════════════════════════
//  COUNTDOWN
// ═══════════════════════════════════════════════════════════════════════════════
int   countdownValue  = 3;
long  countdownLastMs = 0;
final int COUNTDOWN_INTERVAL = 1000;

// ═══════════════════════════════════════════════════════════════════════════════
//  END SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
float endCardY       = 0;
float endCardYTarget = 0;
boolean newHighScore = false;

// ═══════════════════════════════════════════════════════════════════════════════
//  ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════
final int ANIM_NONE      = 0;
final int ANIM_CELEBRATE = 1;
final int ANIM_SAD       = 2;
final int ANIM_NEGATIVE  = 3;
int  animState    = ANIM_NONE;
int  animState2   = ANIM_NONE;
long animStartMs  = 0;
long animStart2Ms = 0;
final int ANIM_DUR = 2200;

float scoreScale       = 1.0, scoreScaleTarget  = 1.0;
float score2Scale      = 1.0, score2ScaleTarget = 1.0;

// ═══════════════════════════════════════════════════════════════════════════════
//  TITLE CARDS (FIFA-style slide-in)
// ═══════════════════════════════════════════════════════════════════════════════
class BoysTitleCard {
  String mainText, subText;
  color  accentCol;
  long   startMs;
  float  ySlot;
  PImage photo;        // per-event photo shown on right side of card
  final int DUR = 3000;

  BoysTitleCard(String main, String sub, color accent, float slot, PImage img) {
    mainText  = main;
    subText   = sub;
    accentCol = accent;
    startMs   = millis();
    ySlot     = slot;
    photo     = img;
  }

  boolean isDone()   { return millis() - startMs > DUR; }
  float   progress() { return constrain((millis() - startMs) / (float)DUR, 0, 1); }
}
ArrayList<BoysTitleCard> titleCards = new ArrayList<BoysTitleCard>();

// ═══════════════════════════════════════════════════════════════════════════════
//  GOAL TITLE CARD ("Goal!" text slam)
// ═══════════════════════════════════════════════════════════════════════════════
boolean goalCardActive  = false;
long    goalCardStartMs = 0;
color   goalCardColor   = color(240, 175, 40);
final int GOAL_CARD_DUR = 2200;

// ═══════════════════════════════════════════════════════════════════════════════
//  FIRE GOAL ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════
boolean goalAnimActive  = false;
long    goalAnimStartMs = 0;
final int GOAL_ANIM_DUR = 3200;
color   goalAnimColor   = color(240, 175, 40);
float   goalBallEndX    = 0;
float   goalBallEndY    = 0;
float   goalBallEndZ    = 0;
boolean goalTitleShown  = false;

// ═══════════════════════════════════════════════════════════════════════════════
//  DEV / TEST MODE
// ═══════════════════════════════════════════════════════════════════════════════
boolean devPanelOpen       = false;
long    devBadgePressStart = 0;
boolean devBadgeHeld       = false;
final long DEV_HOLD_MS     = 700;
float   devPanelY          = 0;
float   devPanelYTarget    = 0;

// ═══════════════════════════════════════════════════════════════════════════════
//  FIRE PARTICLES (3D spheres for goal scene)
// ═══════════════════════════════════════════════════════════════════════════════
class FireParticle {
  float x, y, z, vx, vy, vz, alpha, sz, heat;
  FireParticle(float _x, float _y, float _z, float _heat) {
    x=_x; y=_y; z=_z; heat=_heat; alpha=255;
    float a = random(-PI, PI);
    float spd = random(4, 12) * _heat;
    vx=cos(a)*spd; vy=random(-2,4); vz=sin(a)*spd*0.5;
    sz=random(6,18)*_heat;
  }
  void update() {
    x+=vx; y+=vy; z+=vz;
    vy-=0.25; vx*=0.95; vz*=0.95;
    alpha-=heat*6; sz*=0.96;
  }
  void display3D() {
    float fr=255, fg=map(alpha,255,0,200,50), fb=0;
    if (alpha<80) { fg=map(alpha,80,0,100,255); fb=map(alpha,80,0,0,140); }
    pushMatrix();
    translate(x, y, z);
    noStroke();
    fill(fr, fg, fb, alpha);
    sphere(sz);
    fill(255, 240, 180, alpha*0.35);
    sphere(sz*0.45);
    popMatrix();
  }
}
ArrayList<FireParticle> fireParticles = new ArrayList<FireParticle>();

// ═══════════════════════════════════════════════════════════════════════════════
//  BUTTON PRESS ANIMATION
// 0=startGame 1=exit 2=messiCard 3=ronaldoCard 4=confirmPlayer 5=back
// 6=startStop(ready) 7=back(ready) 8=stopBack(game) 9=playAgain(end)
// 10=singleModeBtn 11=multiModeBtn
// ═══════════════════════════════════════════════════════════════════════════════
float[] btnScale    = new float[12];
float[] btnScaleTgt = new float[12];

// ═══════════════════════════════════════════════════════════════════════════════
//  PARTICLES
// ═══════════════════════════════════════════════════════════════════════════════
class Particle {
  float x, y, vx, vy, alpha, sz;
  color c;
  Particle(float _x, float _y, color _c) {
    x=_x; y=_y; c=_c; alpha=255;
    float a=random(TWO_PI), spd=random(4,14);
    vx=cos(a)*spd; vy=sin(a)*spd; sz=random(6,16);
  }
  void update()  { x+=vx; y+=vy; vy+=0.5; alpha-=5; }
  void display() {
    noStroke();
    fill(red(c), green(c), blue(c), alpha);
    ellipse(x, y, sz, sz);
    fill(255, alpha*0.6);
    ellipse(x, y, sz*0.4, sz*0.4);
  }
}
ArrayList<Particle> particles = new ArrayList<Particle>();

// ═══════════════════════════════════════════════════════════════════════════════
//  UI / COLORS
// ═══════════════════════════════════════════════════════════════════════════════
float cx, cy;

color COL_BG      = color(10,  12,  18);
color COL_BG2     = color(16,  20,  30);
color COL_PANEL   = color(22,  26,  36);
color COL_PANEL2  = color(28,  34,  46);
color COL_ACCENT  = color(0,   102, 204);
color COL_ORANGE  = color(210, 35,  42);
color COL_GOLD    = color(240, 175, 40);
color COL_RED     = color(210, 35,  42);
color COL_TEXTDIM = color(255, 255, 255);
color COL_TEXTMID = color(255, 255, 255);
color COL_TEXTBRT = color(228, 236, 248);
color COL_EDGE    = color(38,  48,  68);

PFont fontBig, fontMed, fontSm, fontTiny;
float messiCardScale = 1.0, rCardScale = 1.0;

// ═══════════════════════════════════════════════════════════════════════════════
//  IMAGE HELPERS
// ═══════════════════════════════════════════════════════════════════════════════
PImage cropImageCover(PImage img, int tw, int th) {
  return cropImageCoverBias(img, tw, th, 0.20);
}

PImage cropImageCoverBias(PImage img, int tw, int th, float bias) {
  if (img == null || tw < 1 || th < 1) return null;
  float imgAr = (float) img.width / (float) img.height;
  float boxAr = (float) tw / (float) th;
  int sw, sh, sx, sy;
  if (imgAr > boxAr) {
    sh = img.height;
    sw = max(1, round(img.height * boxAr));
    sx = (int)((img.width - sw) * 0.5);
    sy = 0;
  } else {
    sw = img.width;
    sh = max(1, round(img.width / boxAr));
    sx = 0;
    sy = (int)((img.height - sh) * bias);
  }
  sx = constrain(sx, 0, max(0, img.width - 1));
  sy = constrain(sy, 0, max(0, img.height - 1));
  sw = min(sw, img.width - sx);
  sh = min(sh, img.height - sy);
  if (img.pixels == null) img.loadPixels();
  PImage out = img.get(sx, sy, sw, sh);
  if (out == null) return null;
  if (out.pixels == null) out.loadPixels();
  out.resize(tw, th);
  return out;
}

PImage renderRoundedTopPhoto(PImage photo, int pw, int ph, float cornerR) {
  if (photo == null || pw < 1 || ph < 1) return null;
  try {
    PImage fitted = cropImageCover(photo, pw, ph);
    if (fitted == null) return null;
    PGraphics pg = createGraphics(pw, ph, P2D);
    pg.beginDraw();
    pg.smooth(8);
    pg.background(0, 0);
    pg.imageMode(CORNER);
    pg.image(fitted, 0, 0, pw, ph);
    pg.fill(red(COL_PANEL), green(COL_PANEL), blue(COL_PANEL));
    pg.noStroke();
    pg.beginShape();
    pg.vertex(-10, -10); pg.vertex(pw+10, -10);
    pg.vertex(pw+10, ph+10); pg.vertex(-10, ph+10);
    pg.beginContour();
    pg.vertex(0, ph); pg.vertex(pw, ph);
    pg.vertex(pw, cornerR);
    pg.quadraticVertex(pw, 0, pw-cornerR, 0);
    pg.vertex(cornerR, 0);
    pg.quadraticVertex(0, 0, 0, cornerR);
    pg.endContour();
    pg.endShape(CLOSE);
    pg.endDraw();
    PImage out = pg.get(0, 0, pw, ph);
    if (out != null) return out;
  } catch (Exception e) { println("renderRoundedTopPhoto: " + e.getMessage()); }
  return cropImageCover(photo, pw, ph);
}

PImage renderCircularPhoto(PImage photo, int size) {
  if (photo == null || size < 1) return null;
  try {
    PImage fitted = cropImageCover(photo, size, size);
    if (fitted == null) return null;
    PGraphics pg = createGraphics(size, size, P2D);
    pg.beginDraw();
    pg.smooth(8);
    pg.background(0, 0);
    pg.imageMode(CORNER);
    pg.image(fitted, 0, 0, size, size);
    pg.fill(red(COL_PANEL), green(COL_PANEL), blue(COL_PANEL));
    pg.noStroke();
    pg.beginShape();
    pg.vertex(-10, -10); pg.vertex(size+10, -10);
    pg.vertex(size+10, size+10); pg.vertex(-10, size+10);
    pg.beginContour();
    float hr = size * 0.5f;
    for (float a = TWO_PI+0.05f; a >= 0; a -= 0.12f)
      pg.vertex(hr + cos(a)*hr, hr + sin(a)*hr);
    pg.endContour();
    pg.endShape(CLOSE);
    pg.endDraw();
    PImage out = pg.get(0, 0, size, size);
    if (out != null) return out;
  } catch (Exception e) { println("renderCircularPhoto: " + e.getMessage()); }
  return cropImageCover(photo, size, size);
}

void prerenderImages() {
  int rcW    = (int)(width * 0.40);
  int rcH    = (int)(height * 0.52);
  int rcImgH = (int)(rcH * 0.76);

  if (messiPhoto   != null) messiPhotoRounded   = renderRoundedTopPhoto(messiPhoto,   rcW, rcImgH, 26);
  if (ronaldoPhoto != null) ronaldoPhotoRounded = renderRoundedTopPhoto(ronaldoPhoto, rcW, rcImgH, 26);
  if (messiPhoto   != null) messiPhotoCircle    = renderCircularPhoto(messiPhoto,   160);
  if (ronaldoPhoto != null) ronaldoPhotoCircle  = renderCircularPhoto(ronaldoPhoto, 160);
  if (messiPhoto   != null) messiPhotoCircleSm  = renderCircularPhoto(messiPhoto,   110);
  if (ronaldoPhoto != null) ronaldoPhotoCircleSm = renderCircularPhoto(ronaldoPhoto, 110);

  int texW = (int)(width * 0.40 * 0.92);
  int texH  = (int)(height * 0.52 * 0.70);
  if (messiPhoto   != null) messiCardTex   = cropImageCover(messiPhoto,   texW, texH);
  if (ronaldoPhoto != null) ronaldoCardTex = cropImageCover(ronaldoPhoto, texW, texH);

  // Per-event title card photos (optional — falls back to null gracefully)
  if (messiCelebPhoto   != null) messiCelebPhoto   = renderRoundedTopPhoto(messiCelebPhoto,   rcW, rcImgH, 26);
  if (ronaldoCelebPhoto != null) ronaldoCelebPhoto = renderRoundedTopPhoto(ronaldoCelebPhoto, rcW, rcImgH, 26);
  if (messiSadPhoto     != null) messiSadPhoto     = renderRoundedTopPhoto(messiSadPhoto,     rcW, rcImgH, 26);
  if (ronaldoSadPhoto   != null) ronaldoSadPhoto   = renderRoundedTopPhoto(ronaldoSadPhoto,   rcW, rcImgH, 26);

  imagesPrerendered = true;
}

void drawImageCover(PImage img, float x, float y, float w, float h) {
  if (img == null) return;
  int tw = max(1, round(w));
  int th = max(1, round(h));
  PImage c = cropImageCover(img, tw, th);
  if (c != null) image(c, x, y, w, h);
}

void drawBg() {
  if (bgImage == null) return;
  float imgAr = (float) bgImage.width / (float) bgImage.height;
  float scrAr = (float) width / (float) height;
  float dw, dh, dx, dy;
  if (imgAr > scrAr) {
    dh = height; dw = height * imgAr;
    dx = (width - dw) * 0.5f; dy = 0;
  } else {
    dw = width; dh = width / imgAr;
    dx = 0; dy = (height - dh) * 0.5f;
  }
  image(bgImage, dx, dy, dw, dh);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  P3D LAYER HELPERS
// ═══════════════════════════════════════════════════════════════════════════════
void beginUI2D() {
  hint(DISABLE_DEPTH_TEST);
  noLights();
  pushMatrix();
  camera();
  ortho();
}

void endUI2D() {
  popMatrix();
  hint(ENABLE_DEPTH_TEST);
}

void beginScene3D() {
  hint(ENABLE_DEPTH_TEST);
  lights();
  ambientLight(55, 62, 78);
  directionalLight(255, 248, 235, 0.35, 0.55, -0.85);
  pushMatrix();
  perspective(PI / 3.2, float(width) / float(height), 1, 12000);
}

void endScene3D() {
  noLights();
  popMatrix();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════════════════════════════════════
void setup() {
  fullScreen(P3D);
  orientation(PORTRAIT);
  frameRate(90);
  imageMode(CORNER);

  for (int i = 0; i < 12; i++) { btnScale[i] = 1.0; btnScaleTgt[i] = 1.0; }

  fontBig  = createFont("Oswald-Bold.ttf",    180);
  fontMed  = createFont("Oswald-Bold.ttf",     78);
  fontSm   = createFont("Oswald-Regular.ttf",  58);
  fontTiny = createFont("Oswald-Regular.ttf",  44);

  pickerRowH = 130;

  loadImages();
  initSounds();
  initVibrator();
  requestBTPermissions();
  try {
    bt = new KetaiBluetooth(this);
  } catch (Exception e) { println("BT init: " + e.getMessage()); }
}

public void onStop() {
  if (bgPlayer != null) {
    try { bgPlayer.stop(); bgPlayer.release(); bgPlayer = null; } catch (Exception e) {}
  }
  super.onStop();
}

void loadImages() {
  bgImage      = loadImage("background.jpg");
  messiPhoto   = loadImage("messi.png");
  ronaldoPhoto = loadImage("ronaldo.png");

  messiCelebPhoto   = loadImage("messi_celeb.png");
  ronaldoCelebPhoto = loadImage("ronaldo_celeb.png");
  messiSadPhoto     = loadImage("messi_sad.png");
  ronaldoSadPhoto   = loadImage("ronaldo_sad.png");

  if (bgImage      != null && bgImage.pixels      == null) bgImage.loadPixels();
  if (messiPhoto   != null && messiPhoto.pixels   == null) messiPhoto.loadPixels();
  if (ronaldoPhoto != null && ronaldoPhoto.pixels == null) ronaldoPhoto.loadPixels();
  if (messiCelebPhoto   != null && messiCelebPhoto.pixels   == null) messiCelebPhoto.loadPixels();
  if (ronaldoCelebPhoto != null && ronaldoCelebPhoto.pixels == null) ronaldoCelebPhoto.loadPixels();
  if (messiSadPhoto     != null && messiSadPhoto.pixels     == null) messiSadPhoto.loadPixels();
  if (ronaldoSadPhoto   != null && ronaldoSadPhoto.pixels   == null) ronaldoSadPhoto.loadPixels();
}

void initSounds() {
  AudioAttributes aa = new AudioAttributes.Builder()
    .setUsage(AudioAttributes.USAGE_GAME)
    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
    .build();
  soundPool = new SoundPool.Builder().setMaxStreams(6).setAudioAttributes(aa).build();
  soundPool.setOnLoadCompleteListener(new SoundPool.OnLoadCompleteListener() {
    public void onLoadComplete(SoundPool sp, int sampleId, int status) {
      if (status == 0) soundReady = true;
    }
  });
  try {
    Activity act = this.getActivity();
    sndStartId = soundPool.load(act.getAssets().openFd("start.mp3"),    1);
    sndScoreId = soundPool.load(act.getAssets().openFd("score.mp3"),    1);
    sndMissId  = soundPool.load(act.getAssets().openFd("miss.mp3"),     1);
    sndNegId   = soundPool.load(act.getAssets().openFd("negative.mp3"), 1);
    sndStopId  = soundPool.load(act.getAssets().openFd("stop.mp3"),     1);
    sndCountId = soundPool.load(act.getAssets().openFd("countdown.mp3"),1);
  } catch (Exception e) { println("Sound: " + e); }
  startBgPlaylist();
}

void startBgPlaylist() {
  try {
    if (bgPlayer != null) {
      try { bgPlayer.stop(); } catch (Exception e) {}
      bgPlayer.release(); bgPlayer = null;
    }
    Activity act = this.getActivity();
    String file = bgTrackFiles[bgTrackIndex];
    AssetFileDescriptor afd = act.getAssets().openFd(file);
    bgPlayer = new MediaPlayer();
    bgPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
    bgPlayer.setLooping(false);
    bgPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
      public void onCompletion(MediaPlayer mp) {
        bgTrackIndex = (bgTrackIndex + 1) % bgTrackFiles.length;
        startBgPlaylist();
      }
    });
    bgPlayer.prepare();
    applyBgVolume();
    bgPlayer.start();
  } catch (Exception e) {
    println("BGMusic [" + bgTrackFiles[bgTrackIndex] + "]: " + e);
    bgTrackIndex = (bgTrackIndex + 1) % bgTrackFiles.length;
    if (bgTrackIndex != 0) startBgPlaylist();
  }
}

void applyBgVolume() {
  if (bgPlayer == null) return;
  float v = bgDucked ? BG_VOL_DUCK : BG_VOL_FULL;
  bgPlayer.setVolume(v, v);
}

void duckBgMusic() { bgDucked = true; applyBgVolume(); }

void restoreBgMusic() {
  bgDucked = false; applyBgVolume();
  if (bgPlayer != null && !bgPlayer.isPlaying())
    try { bgPlayer.start(); } catch (Exception e) {}
}

void playSfx(int id) { if (soundReady) soundPool.play(id, 1, 1, 1, 0, 1); }

void initVibrator() {
  try {
    vibrator = (Vibrator) this.getActivity()
      .getSystemService(android.content.Context.VIBRATOR_SERVICE);
  } catch (Exception e) { println("Vibrator: " + e); }
}

void vibrate(int ms) {
  if (vibrator == null) return;
  try {
    if (android.os.Build.VERSION.SDK_INT >= 26)
      vibrator.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE));
    else vibrator.vibrate(ms);
  } catch (Exception e) {}
}

void vibratePattern(long[] pattern) {
  if (vibrator == null) return;
  try {
    if (android.os.Build.VERSION.SDK_INT >= 26)
      vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1));
    else vibrator.vibrate(pattern, -1);
  } catch (Exception e) {}
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PERMISSIONS
// ═══════════════════════════════════════════════════════════════════════════════
void requestBTPermissions() {
  Activity act = this.getActivity();
  String[] perms = {
    "android.permission.BLUETOOTH_CONNECT",
    "android.permission.BLUETOOTH_SCAN",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.VIBRATE"
  };
  if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M)
    act.requestPermissions(perms, BT_PERM_REQUEST);
  else permissionsGranted = true;
}

void onRequestPermissionsResult(int req, String[] perms, int[] results) {
  if (req == BT_PERM_REQUEST) {
    permissionsGranted = true;
    for (int r : results)
      if (r != PackageManager.PERMISSION_GRANTED) { permissionsGranted = false; break; }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DRAW LOOP
// ═══════════════════════════════════════════════════════════════════════════════
void draw() {
  if (!btActive && bt != null) {
  grabBTOutputStream();
  if (btOut != null) {
    btActive  = true;
    statusMsg = "CONNECTED";
    }
  }

  if (!imagesPrerendered) prerenderImages();
  cx = width / 2.0;
  cy = height / 2.0;
  pickerW = width * 0.88;
  pickerX = (width - pickerW) / 2.0;
  endCardYTarget = height * 0.18;
  if (currentScreen != SCREEN_END) endCardY = height;

  background(COL_BG);
  beginUI2D();

  scoreScale  = lerp(scoreScale,  scoreScaleTarget,  0.15);
  score2Scale = lerp(score2Scale, score2ScaleTarget, 0.15);
  if (abs(scoreScale  - scoreScaleTarget)  < 0.005) scoreScaleTarget  = 1.0;
  if (abs(score2Scale - score2ScaleTarget) < 0.005) score2ScaleTarget = 1.0;

  messiCardScale = lerp(messiCardScale, chosenPlayer==MESSI   ? 1.06 : 1.0, 0.12);
  rCardScale     = lerp(rCardScale,     chosenPlayer==RONALDO ? 1.06 : 1.0, 0.12);

  for (int i = 0; i < 12; i++) {
    btnScale[i] = lerp(btnScale[i], btnScaleTgt[i], 0.25);
    if (abs(btnScale[i] - btnScaleTgt[i]) < 0.002) btnScaleTgt[i] = 1.0;
  }

  if (currentScreen == SCREEN_END)
    endCardY = lerp(endCardY, endCardYTarget, 0.12);

  devPanelY = lerp(devPanelY, devPanelYTarget, 0.18);

  if (devBadgeHeld && !devPanelOpen) {
    if (millis() - devBadgePressStart >= DEV_HOLD_MS) {
      devPanelOpen    = true;
      devPanelYTarget = height * 0.30;
      devPanelY       = height;
      devBadgeHeld    = false;
      vibrate(60);
    }
  }

  switch (currentScreen) {
    case SCREEN_START:     drawStartScreen();     break;
    case SCREEN_MODE:      drawModeScreen();      break;
    case SCREEN_PLAYER:    drawPlayerScreen();    break;
    case SCREEN_PLAYER_P2: drawP2AssignScreen();  break;
    case SCREEN_READY:     drawReadyScreen();     break;
    case SCREEN_COUNTDOWN: drawCountdownScreen(); break;
    case SCREEN_GAME:      drawGameScreen();      break;
    case SCREEN_END:       drawEndScreen();       break;
  }

  endUI2D();

  if (goalAnimActive) {
    beginScene3D();
    drawGoalScene3D();
    endScene3D();
  }

  beginUI2D();
  drawBoysTitleCards();
  drawGoalTitleCard();
  if (showPicker)   drawDevicePicker();
  if (devPanelOpen) drawDevPanel();
  endUI2D();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 1 — START
// ═══════════════════════════════════════════════════════════════════════════════
void drawStartScreen() {
  drawBg();
  fill(20,24,28,175); noStroke(); rect(0,0,width,height);
  fill(COL_ACCENT); noStroke(); rect(0,0,width,6);

  fill(COL_ACCENT); textFont(fontTiny); textAlign(CENTER,CENTER);
  text("B A L L G A M E", cx, height*0.13);
  stroke(COL_EDGE); strokeWeight(1.5);
  line(cx-120, height*0.16, cx+120, height*0.16); noStroke();

  fill(COL_TEXTBRT); textFont(fontMed); textAlign(CENTER,CENTER);
  text("Welcome.", cx, height*0.26);
  fill(COL_TEXTDIM); textFont(fontTiny);
  text("Choose your legend. Score your glory.", cx, height*0.33);

  float bw=width*0.72, bh=108, bx=cx-bw/2;

  pushMatrix();
  translate(cx, height*0.52+bh/2); scale(btnScale[0]); translate(-cx, -(height*0.52+bh/2));
  drawGlowButton(bx, height*0.52, bw, bh, "START GAME", COL_ORANGE, COL_TEXTBRT);
  popMatrix();

  pushMatrix();
  translate(cx, height*0.67+bh/2); scale(btnScale[1]); translate(-cx, -(height*0.67+bh/2));
  drawOutlineButton(bx, height*0.67, bw, bh, "EXIT", COL_EDGE, COL_TEXTMID);
  popMatrix();

  float dotPulse = btActive ? 1.0 : (0.7 + sin(frameCount * 0.08) * 0.3);
  color dotC = btActive ? COL_ACCENT : COL_TEXTDIM;
  noStroke(); fill(red(dotC), green(dotC), blue(dotC), 255 * dotPulse);
  float dotR = btActive ? 10 : (8 + sin(frameCount * 0.08) * 3);
  ellipse(cx-62, height*0.88, dotR, dotR);
  fill(btActive ? COL_TEXTMID : COL_TEXTDIM, 255 * dotPulse);
  textFont(fontTiny); textAlign(LEFT,CENTER);
  text(btActive ? "connected" : "tap to connect bluetooth", cx-48, height*0.88);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 2 — MODE SELECT
// ═══════════════════════════════════════════════════════════════════════════════
void drawModeScreen() {
  drawBg();
  fill(20,24,28,175); noStroke(); rect(0,0,width,height);
  fill(COL_ACCENT); noStroke(); rect(0,0,width,6);

  fill(COL_ACCENT); textFont(fontTiny); textAlign(CENTER,CENTER);
  text("G A M E  M O D E", cx, height*0.10);
  stroke(COL_EDGE); strokeWeight(1.5);
  line(cx-140, height*0.13, cx+140, height*0.13); noStroke();

  fill(COL_TEXTBRT); textFont(fontMed); textAlign(CENTER,CENTER);
  text("Solo glory or head-to-head?", cx, height*0.22);

float cardW=width*0.65, cardH=height*0.20, cardX=cx-cardW/2;
  int cornerR = 40; 

  float singleY = height*0.32;
  pushMatrix();
  translate(cx, singleY+cardH/2);
  scale(btnScale[10]); translate(-cx, -(singleY+cardH/2));
  fill(0,50); noStroke(); rect(cardX+5, singleY+8, cardW, cardH, cornerR);
  fill(COL_PANEL); noStroke(); rect(cardX, singleY, cardW, cardH, cornerR);
  stroke(COL_ACCENT); strokeWeight(2); noFill();
  rect(cardX, singleY, cardW, cardH, cornerR); noStroke();
  fill(COL_ACCENT); noStroke(); rect(cardX, singleY, cardW, 5, cornerR,cornerR,0,0);
  fill(COL_TEXTBRT); textFont(fontMed); textAlign(CENTER,CENTER);
  text("Single Player", cx, singleY + cardH*0.42);
  popMatrix();

  float multiY = height*0.58;
  pushMatrix();
  translate(cx, multiY+cardH/2); scale(btnScale[11]); translate(-cx, -(multiY+cardH/2));
  fill(0,50); noStroke();
  rect(cardX+5, multiY+8, cardW, cardH, cornerR);
  fill(COL_PANEL); noStroke(); rect(cardX, multiY, cardW, cardH, cornerR);
  stroke(COL_ORANGE); strokeWeight(2); noFill(); rect(cardX, multiY, cardW, cardH, cornerR);
  noStroke();
  fill(COL_ORANGE); noStroke(); rect(cardX, multiY, cardW, 5, cornerR,cornerR,0,0);
  fill(COL_TEXTBRT); textFont(fontMed); textAlign(CENTER,CENTER);
  text("Multiplayer", cx, multiY + cardH*0.42);
  popMatrix();

  float ebw=width*0.40, ebh=72;
  pushMatrix();
  translate(cx, height*0.91+ebh/2); scale(btnScale[5]); translate(-cx, -(height*0.91+ebh/2));
  drawOutlineButton(cx-ebw/2, height*0.91, ebw, ebh, "Back", COL_EDGE, COL_TEXTMID);
  popMatrix();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 3 — PLAYER SELECT
// ═══════════════════════════════════════════════════════════════════════════════
void drawPlayerScreen() {
  drawBg();
  fill(20,24,28,175); noStroke(); rect(0,0,width,height);
  fill(COL_ACCENT); noStroke(); rect(0,0,width,6);

  if (lockInActive) { drawLockInAnimation(); return; }

  String subtitle = (gameMode==MODE_MULTI) ? "Player 1, PICK YOUR LEGEND" : "S E L E C T  P L A Y E R";
  fill(COL_TEXTDIM); textFont(fontTiny); textAlign(CENTER,CENTER);
  text(subtitle, cx, height*0.10);
  stroke(COL_EDGE); strokeWeight(1);
  line(cx-160, height*0.13, cx+160, height*0.13); noStroke();

  float cardW=width*0.40, cardH=height*0.52, gap=width*0.08;
  float startX=cx-(cardW*2+gap)/2, cardY=height*0.17;

  pushMatrix();
  translate(startX+cardW/2, cardY+cardH/2);
  scale(messiCardScale * btnScale[2]);
  drawPlayerCard(-cardW/2,-cardH/2,cardW,cardH,messiPhoto,"Messi",chosenPlayer==MESSI,COL_ACCENT);
  popMatrix();

  pushMatrix();
  translate(startX+cardW+gap+cardW/2, cardY+cardH/2);
  scale(rCardScale * btnScale[3]);
  drawPlayerCard(-cardW/2,-cardH/2,cardW,cardH,ronaldoPhoto,"Ronaldo",chosenPlayer==RONALDO,COL_ORANGE);
  popMatrix();

  float bw=width*0.72, bh=108, bx=cx-bw/2;
  if (chosenPlayer != -1) {
    String pn = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    pushMatrix();
    translate(cx, height*0.77+bh/2); scale(btnScale[4]); translate(-cx,-(height*0.77+bh/2));
    drawGlowButton(bx, height*0.77, bw, bh, "Lock in " + pn, COL_ORANGE, COL_TEXTBRT);
    popMatrix();
  } else {
    drawOutlineButton(bx, height*0.77, bw, bh, "Select a player", COL_EDGE, COL_TEXTDIM);
  }

  float ebw=width*0.40, ebh=84;
  pushMatrix();
  translate(cx, height*0.90+ebh/2); scale(btnScale[5]); translate(-cx,-(height*0.90+ebh/2));
  drawOutlineButton(cx-ebw/2, height*0.90, ebw, ebh, "Back", COL_EDGE, COL_TEXTMID);
  popMatrix();
}



void onBluetoothConnectionEvent(boolean connected) {
  if (connected) {
    btActive  = true;
    statusMsg = "CONNECTED";
    grabBTOutputStream();
  } else {
    btActive  = false;
    statusMsg = "DISCONNECTED";
    btOut     = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LOCK-IN ANIMATION (3D FIFA card flip)
// ═══════════════════════════════════════════════════════════════════════════════
void drawLockInAnimation() {
  float elapsed  = millis() - lockInStartMs;
  float progress = elapsed / (float)LOCK_IN_DUR;

  color pCol    = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
  PImage pPhoto = (chosenPlayer==MESSI) ? messiPhoto : ronaldoPhoto;
  String pName  = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
  String tagLine = (chosenPlayer==MESSI) ? "THE GOAT" : "THE LEGEND";
  int    rating  = (chosenPlayer==MESSI) ? 94 : 93;

  if (progress < 0.05) {
    background(0);
    float flashP = (progress < 0.025) ? map(progress, 0, 0.025, 0, 1) : map(progress, 0.025, 0.05, 1, 0);
    fill(255, flashP * 220); noStroke(); rect(0, 0, width, height);
    return;
  }

  background(COL_BG);
  float ambient = constrain(map(progress, 0.05, 0.35, 0, 1), 0, 1);
  fill(red(pCol), green(pCol), blue(pCol), ambient * 35);
  noStroke(); rect(0, 0, width, height);

  for (int r = 8; r >= 1; r--) {
    fill(red(pCol), green(pCol), blue(pCol), ambient * 4 / r);
    ellipse(cx, height * 0.48, width * 0.9 * r / 4, height * 0.55 * r / 4);
  }

  float cW = width * 0.78, cH = height * 0.58;
  float cY = height * 0.16;

  float flipT = constrain(map(progress, 0.05, 0.52, 0, 1), 0, 1);
  float flipEase = flipT < 0.5
    ? 4 * flipT * flipT * flipT
    : 1 - pow(-2 * flipT + 2, 3) / 2;
  float angleY = flipEase * PI;

  float floatY = sin(progress * PI * 2.2) * 6 * (1 - constrain(map(progress, 0.5, 1, 0, 1), 0, 1));
  float tiltZ  = sin(flipEase * PI) * 0.06;

  endUI2D();
  beginScene3D();
  float cardCY = cY + cH / 2 + floatY;

  float camZ = lerp(height * 1.25, height * 1.05, flipEase);
  camera(cx, cardCY, camZ, cx, cardCY, 0, 0, 1, 0);

  ambientLight(70, 75, 85);
  pointLight(255, 230, 200, cx - width/2, cardCY - height/2, 400);
  pointLight(100, 150, 255, cx + width/2, cardCY + height/2, 200);

  translate(cx, cardCY, 0);
  rotateZ(tiltZ);
  rotateY(angleY);

  float cardDepth = 26;
  if (angleY < HALF_PI) {
    drawFifaCardBack3D(cW, cH, cardDepth, pCol, rating);
  } else {
    drawFifaCardFront3D(cW, cH, cardDepth, pPhoto, pName, pCol, rating, flipEase);
  }

  endScene3D();
  beginUI2D();

  if (flipT > 0.05 && flipT < 0.92) {
    if (angleY < HALF_PI) {
      float backA = constrain(map(angleY, 0, HALF_PI, 255, 0), 0, 255);
      fill(red(pCol), green(pCol), blue(pCol), backA);
      textFont(fontBig); textAlign(CENTER, CENTER);
      text(str(rating), cx, cardCY - cH * 0.04);
      fill(120, 130, 150, backA); textFont(fontTiny);
      text("FUT", cx, cardCY + cH * 0.12);
    } else {
      float frontA = constrain(map(angleY, HALF_PI, PI, 0, 255), 0, 255);
      fill(255, frontA); textFont(fontMed); textAlign(CENTER, CENTER);
      text(pName, cx, cardCY + cH * 0.28);
      fill(160, 175, 195, frontA); textFont(fontTiny);
      text("PAC 91  SHO 94  PAS 92", cx, cardCY + cH * 0.36);
    }
  }

  if (progress > 0.54) {
    float tagP    = constrain(map(progress, 0.54, 0.68, 0, 1), 0, 1);
    float tagEase = 1 - pow(1 - tagP, 4);
    float tagY    = lerp(cY - 80, cY + 8, tagEase);
    float tagA    = constrain(map(progress, 0.54, 0.64, 0, 255), 0, 255);
    float tagW    = textWidth(tagLine) + 100;
    fill(0, tagA * 0.7); noStroke(); rect(cx - tagW/2, tagY - 28, tagW, 56, 28);
    fill(red(pCol), green(pCol), blue(pCol), tagA);
    stroke(255, tagA * 0.4); strokeWeight(1.5); noFill(); rect(cx - tagW/2, tagY - 28, tagW, 56, 28); noStroke();
    fill(255, tagA); textFont(fontSm); textAlign(CENTER, CENTER); text(tagLine, cx, tagY + 2);
  }

  if (progress > 0.70) {
    float stP     = constrain(map(progress, 0.70, 0.86, 0, 1), 0, 1);
    float stEase  = 1 - pow(1 - stP, 3) + sin(stP * PI) * 0.1;
    float stScale = lerp(2.4, 1.0, stEase);
    float stAlpha = constrain(map(progress, 0.70, 0.82, 0, 255), 0, 255);
    pushMatrix();
    translate(cx, cY + cH + 52);
    scale(stScale);
    fill(COL_GOLD, stAlpha * 0.25); noStroke(); rectMode(CENTER); rect(0, 0, width * 0.65, 86, 12); rectMode(CORNER);
    stroke(COL_GOLD, stAlpha); strokeWeight(3); noFill(); rectMode(CENTER); rect(0, 0, width * 0.65, 86, 12); rectMode(CORNER); noStroke();
    for (int g = 5; g >= 1; g--) {
      fill(red(COL_GOLD), green(COL_GOLD), blue(COL_GOLD), (stAlpha * 0.4) / g);
      textFont(fontMed); textAlign(CENTER, CENTER); text("LOCKED IN", g, g);
    }
    fill(255, stAlpha); textFont(fontMed); textAlign(CENTER, CENTER); text("LOCKED IN", 0, 0);
    popMatrix();
    if (stP < 0.06) { vibrate(100); }
  }

  if (progress > 0.90 && progress < 0.98) {
    fill(255, map(progress, 0.90, 0.98, 0, 70));
    noStroke(); rect(0, 0, width, height);
  }

  if (progress >= 1.0) {
    lockInActive = false;
    if (gameMode == MODE_MULTI) goToScreen(SCREEN_PLAYER_P2);
    else                        goToScreen(SCREEN_READY);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  3D FIFA CARD MESHES
// ═══════════════════════════════════════════════════════════════════════════════
void drawFifaCardBack3D(float w, float h, float d, color pCol, int rating) {
  float hw=w/2, hh=h/2, hd=d/2;
  pushMatrix();
  fill(16, 20, 30); noStroke(); box(w, h, d);
  pushMatrix();
  translate(0, 0, -hd - 1);
  stroke(red(pCol), green(pCol), blue(pCol), 120); strokeWeight(2);
  for (int i = -4; i <= 4; i++) {
    float off = i * w * 0.12;
    line(-hw+off, -hh, 0, hw+off, hh, 0);
    line(-hw+off, hh, 0, hw+off, -hh, 0);
  }
  strokeWeight(4); noFill(); rectMode(CENTER); rect(0, 0, w-16, h-16, 12); rectMode(CORNER);
  popMatrix();
  popMatrix();
}

void drawFifaCardFront3D(float w, float h, float d, PImage photo, String name, color pCol, int rating, float reveal) {
  float hd=d/2;
  float hh=h/2;

  fill(20, 24, 32); emissive(5, 5, 15); noStroke(); box(w, h, d);

  pushMatrix();
  translate(0, 0, hd + 1);
  stroke(red(pCol), green(pCol), blue(pCol), 220); strokeWeight(4); noFill();
  rectMode(CENTER); rect(0, 0, w-6, h-6); rectMode(CORNER);
  popMatrix();

  if (photo != null) {
    PImage tex = photo;
    if (tex != null) {
      pushMatrix();
      translate(0, -hh * 0.12, hd + 12);
      float fade = constrain(map(reveal, 0.5, 1, 0, 255), 0, 255);
      tint(255, fade); noStroke();
      float imgW = w * 0.95, imgH = h * 0.72;
      beginShape(QUADS);
      texture(tex);
      vertex(-imgW/2, -imgH/2, 0, 0, 0);
      vertex( imgW/2, -imgH/2, 0, 1, 0);
      vertex( imgW/2,  imgH/2, 0, 1, 1);
      vertex(-imgW/2,  imgH/2, 0, 0, 1);
      endShape();
      noTint();
      popMatrix();
    }
  }

  if (reveal > 0.35 && reveal < 0.85) {
    float holoP = map(reveal, 0.35, 0.85, -w, w);
    pushMatrix();
    translate(0, 0, hd + 22);
    fill(255, 255, 255, 80); noStroke();
    beginShape(QUADS);
    vertex(holoP-45, -h/2, 0); vertex(holoP+15, -h/2, 0);
    vertex(holoP+75,  h/2, 0); vertex(holoP+15,  h/2, 0);
    endShape();
    popMatrix();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 3B — P2 AUTO-ASSIGN
// ═══════════════════════════════════════════════════════════════════════════════
void drawP2AssignScreen() {
  drawBg();
  fill(20,24,28,185); noStroke(); rect(0,0,width,height);
  fill(COL_ACCENT); noStroke(); rect(0,0,width,6);
  if (vsAnimActive) { drawVsAnimation(); return; }
  goToScreen(SCREEN_READY);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  VS ANIMATION (3D FIFA Style)
// ═══════════════════════════════════════════════════════════════════════════════
void drawVsAnimation() {
  float elapsed  = millis() - vsAnimStartMs;
  float progress = elapsed / (float)VS_ANIM_DUR;

  int p2 = (chosenPlayer == MESSI) ? RONALDO : MESSI;
  color col1 = (chosenPlayer == MESSI) ? COL_ACCENT : COL_ORANGE;
  color col2 = (chosenPlayer == MESSI) ? COL_ORANGE : COL_ACCENT;
  String name1 = (chosenPlayer == MESSI) ? "Messi" : "Ronaldo";
  String name2 = (chosenPlayer == MESSI) ? "Ronaldo" : "Messi";
PImage ph1 = (chosenPlayer==MESSI) ? messiCardTex : ronaldoCardTex;
PImage ph2 = (chosenPlayer==MESSI) ? ronaldoCardTex : messiCardTex;

  background(COL_BG);

  float shake = 0;
  if (progress > 0.35 && progress < 0.55) {
    float shakeDecay = map(progress, 0.35, 0.55, 1, 0);
    shake = sin(progress * 100) * 12 * shakeDecay;
  }

  float camZ = map(progress, 0, 1, height * 1.15, height * 0.95);

  endUI2D();
  beginScene3D();

  camera(cx + shake, cy + shake, camZ, cx, cy, 0, 0, 1, 0);

  ambientLight(50, 55, 65);
  pointLight(255, 200, 150, cx, -height, 300);
  pointLight(red(col1), green(col1), blue(col1), 0, cy, 200);
  pointLight(red(col2), green(col2), blue(col2), width, cy, 200);

  translate(cx, cy, 0);

  float cW = width * 0.38, cH = height * 0.28, cD = 26;

  float flyInEase = constrain(map(progress, 0.0, 0.35, 0, 1), 0, 1);
  flyInEase = 1 - pow(1 - flyInEase, 4);

  pushMatrix();
  float p1X    = lerp(-width, -cW * 0.65, flyInEase);
  float p1RotY = lerp(-HALF_PI, radians(15), flyInEase);
  translate(p1X, 0, -100);
  rotateY(p1RotY); rotateZ(radians(-5));
  drawFifaCardFront3D(cW, cH, cD, ph1, name1, col1, 99, 1.0);
  popMatrix();

  pushMatrix();
  float p2X    = lerp(width, cW * 0.65, flyInEase);
  float p2RotY = lerp(HALF_PI, radians(-15), flyInEase);
  translate(p2X, 0, -100);
  rotateY(p2RotY); rotateZ(radians(5));
  drawFifaCardFront3D(cW, cH, cD, ph2, name2, col2, 99, 1.0);
  popMatrix();

  if (progress > 0.30) {
    float badgeDropEase = constrain(map(progress, 0.30, 0.42, 0, 1), 0, 1);
    float badgeZ    = lerp(800, 50, badgeDropEase);
    float badgeRotZ = lerp(PI, 0, badgeDropEase);
    pushMatrix();
    translate(0, 0, badgeZ);
    rotateZ(badgeRotZ);
    fill(20, 20, 25);
    stroke(255, 215, 0); strokeWeight(5);
    pushMatrix(); rotateZ(QUARTER_PI); box(cW * 0.45, cW * 0.45, 30); popMatrix();
    translate(0, 0, 16);
    textAlign(CENTER, CENTER); textFont(fontMed);
    fill(0, 150); text("VS", 2, 2, -1);
    fill(255);    text("VS", 0, -5, 0);
    popMatrix();
    if (badgeDropEase > 0.95 && badgeDropEase < 0.99) {
      vibrate(60);
    }
  }

  endScene3D();
  beginUI2D();

  // Player labels — slide up from bottom
  float labelAlpha = constrain(map(progress, 0.30, 0.50, 0, 255), 0, 255);
  float labelY     = lerp(height*0.92, height*0.84, constrain(map(progress, 0.30, 0.50, 0, 1), 0, 1));
  float pillW = width*0.38, pillH = 64;

  fill(red(col1), green(col1), blue(col1), labelAlpha * 0.9);
  noStroke(); rect(cx*0.18, labelY - pillH/2, pillW, pillH, pillH/2);
  fill(255, labelAlpha); textFont(fontTiny); textAlign(CENTER, CENTER);
  text("P1  " + name1, cx*0.18 + pillW/2, labelY);

  fill(red(col2), green(col2), blue(col2), labelAlpha * 0.9);
  noStroke(); rect(cx + cx*0.04, labelY - pillH/2, pillW, pillH, pillH/2);
  fill(255, labelAlpha); textFont(fontTiny); textAlign(CENTER, CENTER);
  text("P2  " + name2, cx + cx*0.04 + pillW/2, labelY);

  if (progress > 0.55) {
    float noteAlpha = constrain(map(progress, 0.55, 0.68, 0, 255), 0, 255);
    fill(COL_TEXTDIM, noteAlpha); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("Player 2 plays as " + name2, cx, height*0.93);
  }

  if (progress >= 1.0) {
    vsAnimActive = false;
    goToScreen(SCREEN_READY);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PLAYER CARD (selection screen)
// ═══════════════════════════════════════════════════════════════════════════════
void drawPlayerCard(float x, float y, float w, float h,
                    PImage photo, String name, boolean selected, color accent) {
  float r=26, imgH=h*0.76, nameH=h-imgH;
  noStroke();
  fill(0,50); rect(x+6, y+10, w, h, r);
  fill(0,30); rect(x+3, y+5,  w, h, r);
  fill(COL_PANEL); noStroke(); rect(x, y, w, h, r);

  if (photo != null) {
    PImage framed = (photo == messiPhoto) ? messiPhotoRounded : ronaldoPhotoRounded;
    if (framed != null) image(framed, x, y, int(w), int(imgH));
  }

  fill(COL_PANEL); noStroke(); rect(x, y+imgH, w, nameH, 0,0,r,r);
  stroke(COL_EDGE); strokeWeight(1);
  line(x+16, y+imgH, x+w-16, y+imgH); noStroke();

  float nameY = y+imgH+nameH*0.38;
  fill(selected ? accent : COL_TEXTBRT); textFont(fontSm); textAlign(CENTER,CENTER);
  text(name, x+w/2, nameY);
  if (selected) { fill(accent,200); textFont(fontTiny); text("selected", x+w/2, nameY+36); }

  stroke(255, selected?45:20); strokeWeight(1.2); noFill();
  rect(x+1.5, y+1.5, w-3, h-3, r-1);
  strokeWeight(selected?2.5:1.5);
  stroke(selected ? accent : color(52,62,75));
  noFill(); rect(x, y, w, h, r); noStroke();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 4 — READY
// ═══════════════════════════════════════════════════════════════════════════════
void drawReadyScreen() {
  drawBg();
  fill(20,24,28,175); noStroke(); rect(0,0,width,height);
  fill(COL_ACCENT); noStroke(); rect(0,0,width,6);

  fill(COL_TEXTDIM); textFont(fontTiny); textAlign(CENTER,CENTER);
  text("R E A D Y  T O  P L A Y", cx, height*0.10);
  stroke(COL_EDGE); strokeWeight(1);
  line(cx-140, height*0.13, cx+140, height*0.13); noStroke();

  if (gameMode == MODE_SINGLE) {
    color pCol  = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    String pName = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    fill(COL_TEXTMID); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("playing as", cx, height*0.19);
    fill(COL_TEXTBRT); textFont(fontMed); text(pName, cx, height*0.26);
    fill(pCol); noStroke(); rect(cx-60, height*0.305, 120, 3, 2);
    PImage ph = (chosenPlayer==MESSI) ? messiPhoto : ronaldoPhoto;
    if (ph != null) { float ps=width*0.38; drawImageCover(ph, cx-ps/2, height*0.33, ps, ps*1.1); }
  } else {
    int p2 = (chosenPlayer==MESSI) ? RONALDO : MESSI;
    color col1 = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    color col2 = (chosenPlayer==MESSI) ? COL_ORANGE : COL_ACCENT;
    String name1 = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    String name2 = (chosenPlayer==MESSI) ? "Ronaldo" : "Messi";
    PImage ph1 = (chosenPlayer==MESSI) ? messiPhoto : ronaldoPhoto;
    PImage ph2 = (chosenPlayer==MESSI) ? ronaldoPhoto : messiPhoto;
    float halfW=width*0.40, photoH=halfW*1.1, py=height*0.20;
    if (ph1 != null) drawImageCover(ph1, cx-halfW-width*0.02, py, halfW, photoH);
    if (ph2 != null) drawImageCover(ph2, cx+width*0.02, py, halfW, photoH);
    fill(col1); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("P1", cx-halfW/2-width*0.02, py+photoH+32);
    fill(col2); text("P2", cx+halfW/2+width*0.02, py+photoH+32);
    fill(COL_TEXTDIM); textFont(fontTiny); text("heads-up match", cx, py+photoH+72);
  }

  color badgeCol = btActive ? COL_ACCENT : COL_TEXTDIM;
  float badgeW=260, bh2=52;
  fill(red(COL_PANEL2),green(COL_PANEL2),blue(COL_PANEL2),200);
  noStroke(); rect(cx-badgeW/2, height*0.64, badgeW, bh2, bh2/2);
  stroke(badgeCol,120); strokeWeight(1); noFill();
  rect(cx-badgeW/2, height*0.64, badgeW, bh2, bh2/2); noStroke();
  float bdPulse = btActive ? 1.0 : (0.6+sin(frameCount*0.08)*0.4);
  fill(red(badgeCol),green(badgeCol),blue(badgeCol),255*bdPulse);
  ellipse(cx-badgeW/2+28, height*0.64+bh2/2, 12, 12);
  fill(btActive?COL_TEXTMID:COL_TEXTDIM); textFont(fontTiny); textAlign(LEFT,CENTER);
  text(btActive?"bluetooth connected":"not connected", cx-badgeW/2+46, height*0.64+bh2/2);
  fill(COL_TEXTDIM, 90); textFont(fontTiny); textAlign(RIGHT, CENTER);
  text("hold", cx+badgeW/2-14, height*0.64+bh2/2);

  if (stopPending) { fill(COL_GOLD); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("finishing current ball...", cx, height*0.72); }

  float bw=width*0.72, bh=108, bx=cx-bw/2;
  pushMatrix();
  translate(cx,height*0.75+bh/2); scale(btnScale[6]); translate(-cx,-(height*0.75+bh/2));
  drawGlowButton(bx,height*0.75,bw,bh,gameRunning?"Stop":"Start",gameRunning?COL_RED:COL_ORANGE,COL_TEXTBRT);
  popMatrix();

  pushMatrix();
  translate(cx,height*0.88+bh/2); scale(btnScale[7]); translate(-cx,-(height*0.88+bh/2));
  drawOutlineButton(bx,height*0.88,bw,bh,"Back",COL_EDGE,COL_TEXTMID);
  popMatrix();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 5 — COUNTDOWN
// ═══════════════════════════════════════════════════════════════════════════════
void drawCountdownScreen() {
  drawBg();
  fill(20,24,28,200); noStroke(); rect(0,0,width,height);

  if (millis() - countdownLastMs >= COUNTDOWN_INTERVAL) {
    countdownValue--;
    countdownLastMs = millis();
    playSfx(sndCountId);
    vibrate(60);
    if (countdownValue <= 0) {
      gameRunning = true;
      sendBT("S");
      if (bgPlayer != null) try { bgPlayer.stop(); } catch (Exception e) {}
      bgDucked = false;
      playSfx(sndStartId);
      vibrate(120);
      goToScreen(SCREEN_GAME);
      return;
    }
  }

  float progress = (millis() - countdownLastMs) / (float)COUNTDOWN_INTERVAL;
  float numScale = map(progress, 0, 1, 1.4, 0.8);
  float alpha    = map(progress, 0.7, 1.0, 255, 0);

  fill(COL_TEXTMID); textFont(fontTiny); textAlign(CENTER,CENTER);
  text("get ready", cx, height*0.38);

  pushMatrix();
  translate(cx, height*0.55); scale(numScale);
  fill(COL_TEXTBRT, alpha); textFont(fontBig);
  text(countdownValue, 0, 0);
  popMatrix();

  noFill(); stroke(COL_ORANGE, 180); strokeWeight(8);
  arc(cx, height*0.55, 260, 260, -HALF_PI, -HALF_PI + TWO_PI * progress);
  noStroke();

  if (gameMode == MODE_SINGLE) {
    color pCol = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    String pName = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    fill(pCol); textFont(fontTiny); textAlign(CENTER,CENTER);
    text(pName, cx, height*0.72);
  } else {
    String name1 = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    String name2 = (chosenPlayer==MESSI) ? "Ronaldo" : "Messi";
    color col1   = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    fill(col1); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("P1 " + name1 + "  vs  P2 " + name2, cx, height*0.72);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 6 — GAME
// ═══════════════════════════════════════════════════════════════════════════════
void drawGameScreen() {
  drawBg();
  fill(20,24,28,160); noStroke(); rect(0,0,width,height);
  fill(COL_ACCENT); noStroke(); rect(0,0,width,6);

  if (gameMode == MODE_SINGLE) {
    color pCol  = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    String pName = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    fill(pCol); textFont(fontTiny); textAlign(CENTER,CENTER);
    text(pName, cx, height*0.08);
    fill(COL_TEXTDIM); textFont(fontTiny);
    text("score", cx, height*0.14);
    pushMatrix();
    translate(cx, height*0.24); scale(scoreScale);
    fill(0,120); textFont(fontBig); text(score,3,3);
    fill(scoreColorR, scoreColorG, scoreColorB); text(score,0,0);
    popMatrix();
    fill(COL_TEXTDIM); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("High score  " + highScore, cx, height*0.35);
    stroke(COL_EDGE); strokeWeight(1);
    line(cx-80, height*0.38, cx+80, height*0.38); noStroke();
    drawPlayerAnimation(chosenPlayer, animState, animStartMs, cx, height*0.55);
  } else {
    int p2 = (chosenPlayer==MESSI) ? RONALDO : MESSI;
    color col1 = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    color col2 = (chosenPlayer==MESSI) ? COL_ORANGE : COL_ACCENT;
    String name1 = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    String name2 = (chosenPlayer==MESSI) ? "Ronaldo" : "Messi";
    float panelW=width*0.44, panelH=height*0.46;
    float panel1X=cx-panelW-width*0.03, panel2X=cx+width*0.03, panelY=height*0.05;

    fill(COL_PANEL); noStroke(); rect(panel1X, panelY, panelW, panelH, 20);
    fill(red(col1),green(col1),blue(col1),60); noStroke(); rect(panel1X, panelY, panelW, 5, 20,20,0,0);
    fill(col1); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("P1  " + name1, panel1X+panelW/2, panelY+40);
    pushMatrix();
    translate(panel1X+panelW/2, panelY+panelH*0.62); scale(scoreScale);
    fill(0,100); textFont(fontBig); text(score,2,2);
    fill(scoreColorR, scoreColorG, scoreColorB); text(score,0,0);
    popMatrix();

    fill(COL_PANEL); noStroke(); rect(panel2X, panelY, panelW, panelH, 20);
    fill(red(col2),green(col2),blue(col2),60); noStroke(); rect(panel2X, panelY, panelW, 5, 20,20,0,0);
    fill(col2); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("P2  " + name2, panel2X+panelW/2, panelY+40);
    pushMatrix();
    translate(panel2X+panelW/2, panelY+panelH*0.62); scale(score2Scale);
    fill(0,100); textFont(fontBig); text(score2,2,2);
    fill(score2ColorR, score2ColorG, score2ColorB); text(score2,0,0);
    popMatrix();

    fill(COL_TEXTDIM); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("vs", cx, panelY+panelH*0.60);
    drawPlayerAnimation(chosenPlayer, animState,  animStartMs,  cx*0.55, height*0.68);
    drawPlayerAnimation(p2,           animState2, animStart2Ms, cx*1.45, height*0.68);
  }

  fill(COL_PANEL); noStroke(); rect(0, height*0.876, width, height*0.054);
  stroke(COL_EDGE); strokeWeight(1); line(0, height*0.876, width, height*0.876); noStroke();
  float dotPulse = btActive ? 1.0 : (0.6+sin(frameCount*0.08)*0.4);
  fill(btActive?COL_ACCENT:COL_TEXTDIM, 255*dotPulse); ellipse(36, height*0.903, 10, 10);
  fill(btActive?COL_TEXTMID:COL_TEXTDIM); textFont(fontTiny); textAlign(LEFT,CENTER);
  text(btActive?"connected":"no bluetooth", 52, height*0.903);
  fill(COL_TEXTDIM); textAlign(RIGHT,CENTER);
  text(statusMsg, width-28, height*0.903);

  if (stopPending) { fill(COL_GOLD); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("finishing current ball...", cx, height*0.928); }

  float bw=width*0.72, bh=100, bx=cx-bw/2;
  pushMatrix();
  translate(cx,height*0.938+bh/2); scale(btnScale[8]); translate(-cx,-(height*0.938+bh/2));
  if (gameRunning) drawGlowButton(bx,height*0.938,bw,bh,"Stop",COL_RED,COL_TEXTBRT);
  else             drawOutlineButton(bx,height*0.938,bw,bh,"Back",COL_EDGE,COL_TEXTMID);
  popMatrix();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCREEN 7 — END SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
void drawEndScreen() {
  drawBg();
  fill(20,24,28,190); noStroke(); rect(0,0,width,height);

  float cardW=width*0.86, cardH=height*0.70, cardX=cx-cardW/2;
  fill(0,80); noStroke(); rect(cardX+6, endCardY+10, cardW, cardH, 32);
  fill(COL_PANEL); noStroke(); rect(cardX, endCardY, cardW, cardH, 28);
  stroke(COL_EDGE); strokeWeight(1.5); noFill(); rect(cardX, endCardY, cardW, cardH, 28); noStroke();

  if (gameMode == MODE_SINGLE) {
    color pCol = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    fill(pCol); noStroke(); rect(cardX, endCardY, cardW, 6, 28,28,0,0);
    PImage ph = (chosenPlayer==MESSI) ? messiPhoto : ronaldoPhoto;
    if (ph != null) {
      float ps=160;
      PImage cphoto = (ph==messiPhoto) ? messiPhotoCircle : ronaldoPhotoCircle;
      if (cphoto != null) image(cphoto, cx-ps/2, endCardY+30, ps, ps);
      stroke(pCol); strokeWeight(3); noFill(); ellipse(cx, endCardY+30+ps/2, ps+4, ps+4); noStroke();
    }
    float contentY = endCardY + 210;
    String pName = (chosenPlayer==MESSI) ? "Messi" : "Ronaldo";
    fill(pCol); textFont(fontTiny); textAlign(CENTER,CENTER); text(pName, cx, contentY);
    fill(COL_TEXTBRT); textFont(fontMed); text("Game Over", cx, contentY+60);
    fill(COL_TEXTDIM); textFont(fontTiny); text("final score", cx, contentY+120);
    fill(scoreColorR, scoreColorG, scoreColorB); textFont(fontBig); text(score, cx, contentY+200);
    stroke(COL_EDGE); strokeWeight(1);
    line(cardX+40, contentY+250, cardX+cardW-40, contentY+250); noStroke();
    fill(COL_TEXTDIM); textFont(fontTiny); textAlign(LEFT,CENTER);
    text("High Score", cardX+50, contentY+290);
    fill(newHighScore ? COL_GOLD : COL_TEXTMID); textAlign(RIGHT,CENTER);
    text(str(highScore) + (newHighScore ? "  new!" : ""), cardX+cardW-50, contentY+290);
  } else {
    int p2 = (chosenPlayer==MESSI) ? RONALDO : MESSI;
    boolean p1Wins = (score > score2), draw = (score == score2);
    int winner = draw ? -1 : (p1Wins ? chosenPlayer : p2);
    color col1 = (chosenPlayer==MESSI) ? COL_ACCENT : COL_ORANGE;
    color col2 = (chosenPlayer==MESSI) ? COL_ORANGE : COL_ACCENT;
    color topCol = draw ? COL_GOLD : (p1Wins ? col1 : col2);
    fill(topCol); noStroke(); rect(cardX, endCardY, cardW, 6, 28,28,0,0);

    float labelY = endCardY + 52;
    if (draw) {
      fill(COL_GOLD); textFont(fontTiny); textAlign(CENTER,CENTER);
      text("IT'S A DRAW!", cx, labelY);
    } else {
      String wName = (winner==MESSI) ? "Messi" : "Ronaldo";
      String wPlayer = p1Wins ? "P1" : "P2";
      fill(topCol); textFont(fontTiny); textAlign(CENTER,CENTER);
      text(wPlayer + " wins — " + wName + "!", cx, labelY);
    }

    float colW=cardW*0.44, col1X=cardX+20, col2X=cardX+cardW-colW-20;
    float photoY=endCardY+80, ps=110;

    PImage ph1 = (chosenPlayer==MESSI) ? messiPhoto : ronaldoPhoto;
    if (ph1 != null) {
      PImage cp1 = (ph1==messiPhoto) ? messiPhotoCircleSm : ronaldoPhotoCircleSm;
      if (cp1 != null) image(cp1, col1X+colW/2-ps/2, photoY, ps, ps);
      stroke(!draw && p1Wins ? col1 : COL_EDGE); strokeWeight(!draw && p1Wins ? 3 : 1.5);
      noFill(); ellipse(col1X+colW/2, photoY+ps/2, ps+4, ps+4); noStroke();
    }
    PImage ph2 = (chosenPlayer==MESSI) ? ronaldoPhoto : messiPhoto;
    if (ph2 != null) {
      PImage cp2 = (ph2==messiPhoto) ? messiPhotoCircleSm : ronaldoPhotoCircleSm;
      if (cp2 != null) image(cp2, col2X+colW/2-ps/2, photoY, ps, ps);
      stroke(!draw && !p1Wins ? col2 : COL_EDGE); strokeWeight(!draw && !p1Wins ? 3 : 1.5);
      noFill(); ellipse(col2X+colW/2, photoY+ps/2, ps+4, ps+4); noStroke();
    }

    String name1=(chosenPlayer==MESSI)?"Messi":"Ronaldo";
    String name2=(chosenPlayer==MESSI)?"Ronaldo":"Messi";
    fill(col1); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("P1 "+name1, col1X+colW/2, photoY+ps+32);
    fill(scoreColorR, scoreColorG, scoreColorB); textFont(fontMed);
    text(score, col1X+colW/2, photoY+ps+90);
    fill(col2); textFont(fontTiny); textAlign(CENTER,CENTER);
    text("P2 "+name2, col2X+colW/2, photoY+ps+32);
    fill(score2ColorR, score2ColorG, score2ColorB); textFont(fontMed);
    text(score2, col2X+colW/2, photoY+ps+90);
  }

  float bw=width*0.72, bh=108, bx=cx-bw/2;
  float btnY = endCardY + cardH - bh - 32;
  pushMatrix();
  translate(cx, btnY+bh/2); scale(btnScale[9]); translate(-cx, -(btnY+bh/2));
  drawGlowButton(bx, btnY, bw, bh, "Play Again", COL_ORANGE, COL_TEXTBRT);
  popMatrix();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PLAYER ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════
void drawPlayerAnimation(int player, int aState, long aStartMs, float ax, float ay) {
  if (aState == ANIM_NONE) return;
  float progress = (float)(millis() - aStartMs) / ANIM_DUR;
  if (progress >= 1.0) {
    if (player == chosenPlayer) animState  = ANIM_NONE;
    else                        animState2 = ANIM_NONE;
    return;
  }
  float alpha  = progress < 0.75 ? 255 : map(progress, 0.75, 1.0, 255, 0);
  float bounce = sin(progress * PI * 5) * 22 * (1 - progress);
  color pCol   = (player == MESSI) ? COL_ACCENT : COL_ORANGE;
  noFill();
  stroke(red(pCol), green(pCol), blue(pCol), alpha * 0.55); strokeWeight(3);
  ellipse(ax, ay+bounce, 48+sin(progress*PI*4)*8, 48+sin(progress*PI*4)*8);
  noStroke();
  if (gameMode == MODE_MULTI) {
    fill(red(pCol), green(pCol), blue(pCol), alpha * 0.7);
    noStroke(); ellipse(ax, ay+bounce+50, 10, 10);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TOUCH
// ═══════════════════════════════════════════════════════════════════════════════
void mousePressed() {
  if (showPicker) { handlePickerTouch(); return; }
  if (devPanelOpen) { handleDevPanelTouch(); return; }

  if (currentScreen == SCREEN_READY || currentScreen == SCREEN_GAME) {
    float badgeW=260, badgeH=52, badgeX=cx-badgeW/2, badgeY=height*0.64;
    if (currentScreen == SCREEN_GAME) {
      badgeW=width*0.55; badgeH=48; badgeX=cx-badgeW/2; badgeY=height*0.876+(height*0.054-badgeH)/2;
    }
    if (mouseX>=badgeX && mouseX<=badgeX+badgeW && mouseY>=badgeY && mouseY<=badgeY+badgeH) {
      devBadgeHeld=true; devBadgePressStart=millis();
    }
  }

  switch (currentScreen) {
    case SCREEN_START:
      if (mouseY > height*0.84) { openDevicePicker(); return; }
      if (hitBtn(cx-width*0.36, height*0.52, width*0.72, 108)) { pressBtn(0); vibrate(30); goToScreen(SCREEN_MODE); }
      if (hitBtn(cx-width*0.36, height*0.67, width*0.72, 108)) { pressBtn(1); vibrate(30); exit(); }
      break;

    case SCREEN_MODE: {
      float cardW=width*0.80, cardH=height*0.26, cardX=cx-cardW/2;
      if (hitBtn(cardX, height*0.30, cardW, cardH)) {
        pressBtn(10); vibrate(30); gameMode=MODE_SINGLE; sendBT("1"); chosenPlayer=-1; goToScreen(SCREEN_PLAYER);
      }
      if (hitBtn(cardX, height*0.60, cardW, cardH)) {
        pressBtn(11); vibrate(30); gameMode=MODE_MULTI; sendBT("M"); chosenPlayer=-1; goToScreen(SCREEN_PLAYER);
      }
      if (hitBtn(cx-width*0.20, height*0.91, width*0.40, 72)) { pressBtn(5); vibrate(20); goToScreen(SCREEN_START); }
      break;
    }

    case SCREEN_PLAYER:
      if (lockInActive) return;
      float cW=width*0.40, cH=height*0.52, cGap=width*0.08;
      float sX=cx-(cW*2+cGap)/2, cYY=height*0.17;
      if (hitBtn(sX, cYY, cW, cH))         { pressBtn(2); vibrate(30); chosenPlayer=MESSI; }
      if (hitBtn(sX+cW+cGap, cYY, cW, cH)) { pressBtn(3); vibrate(30); chosenPlayer=RONALDO; }
      if (chosenPlayer != -1 && hitBtn(cx-width*0.36, height*0.77, width*0.72, 108)) {
        pressBtn(4); vibrate(60);
        lockInActive=true; lockInStartMs=millis();
      }
      if (hitBtn(cx-width*0.20, height*0.90, width*0.40, 84)) {
        pressBtn(5); vibrate(20); chosenPlayer=-1; goToScreen(SCREEN_MODE);
      }
      break;

    case SCREEN_READY:
      if (hitBtn(cx-width*0.36, height*0.75, width*0.72, 108)) { pressBtn(6); vibrate(40); toggleGame(); }
      if (hitBtn(cx-width*0.36, height*0.88, width*0.72, 108) && !gameRunning) {
        pressBtn(7); vibrate(20); goToScreen(SCREEN_PLAYER);
      }
      break;

    case SCREEN_GAME:
      if (hitBtn(cx-width*0.36, height*0.938, width*0.72, 100)) {
        pressBtn(8); vibrate(40);
        if (gameRunning) stopGame();
        else             goToScreen(SCREEN_READY);
      }
      break;

    case SCREEN_END:
      float bh2=108, btnYY=endCardY+(height*0.70)-bh2-32;
      if (hitBtn(cx-width*0.36, btnYY, width*0.72, bh2)) { pressBtn(9); vibrate(30); restartFromEnd(); }
      break;
  }
}

void mouseReleased() { devBadgeHeld = false; }

// ═══════════════════════════════════════════════════════════════════════════════
//  DEV PANEL
// ═══════════════════════════════════════════════════════════════════════════════
void drawDevPanel() {
  float panelW=width, panelH=height-devPanelY;
  fill(0,180); noStroke(); rect(0,0,width,devPanelY);
  fill(COL_BG2); noStroke(); rect(0,devPanelY,panelW,panelH,28,28,0,0);
  stroke(COL_ACCENT,160); strokeWeight(2); noFill(); rect(1,devPanelY+1,panelW-2,panelH-1,28,28,0,0); noStroke();
  fill(COL_EDGE); noStroke(); rect(cx-36,devPanelY+14,72,8,4);

  float hY=devPanelY+52;
  fill(COL_ACCENT); textFont(fontSm); textAlign(LEFT,CENTER); text("DEV MODE",32,hY);
  fill(COL_RED); noStroke();
  float xBtnX=width-80, xBtnY=devPanelY+18;
  rect(xBtnX,xBtnY,60,60,12);
  fill(COL_TEXTBRT); textFont(fontSm); textAlign(CENTER,CENTER); text("X",xBtnX+30,xBtnY+30);

  fill(btActive?COL_ACCENT:COL_RED,80); noStroke(); rect(28,hY+30,width-56,44,10);
  fill(btActive?COL_ACCENT:COL_RED); textFont(fontTiny); textAlign(CENTER,CENTER);
  text(btActive?"CONNECTED (simulated)":"NOT CONNECTED",cx,hY+52);

  float rowY=devPanelY+160;
  float bW=(width-52)/2.0, bH=88;
  float col1X=18, col2X=18+bW+16;

  devSectionLabel("SCORE EVENTS", rowY-36);
  devBtn(col1X,rowY,bW,bH,"+2  White Right",color(60,180,100),0);
  devBtn(col2X,rowY,bW,bH,"+1  White Left", color(60,160,80), 1);
  rowY+=bH+12;
  devBtn(col1X,rowY,bW,bH,"−2  Black Right",COL_RED,            2);
  devBtn(col2X,rowY,bW,bH,"−1  Black Left", color(180,60,60),   3);
  rowY+=bH+12;
  devBtn(col1X,rowY,bW,bH,"Miss  (white)",  COL_TEXTDIM,        4);
  devBtn(col2X,rowY,bW,bH,"Nice  (black)",  color(80,110,160),  5);
  rowY+=bH+28;

  devSectionLabel("GAME FLOW", rowY-24);
  devBtn(col1X,rowY,bW,bH,gameRunning?"Stop Game":"Start Game",gameRunning?COL_RED:COL_ORANGE,6);
  devBtn(col2X,rowY,bW,bH,"Goal Anim P1",COL_ACCENT,7);
  rowY+=bH+12;
  devBtn(col1X,rowY,bW,bH,"Goal Anim P2",COL_ORANGE,8);
  devBtn(col2X,rowY,bW,bH,"Fake Connect",color(40,140,80),9);
}

void devSectionLabel(String label, float y) {
  fill(COL_TEXTDIM); textFont(fontTiny); textAlign(LEFT,CENTER); text(label,24,y);
}

void devBtn(float x, float y, float w, float h, String label, color bg, int id) {
  float r=14;
  fill(0,50); noStroke(); rect(x+3,y+4,w,h,r);
  fill(red(bg),green(bg),blue(bg),200); noStroke(); rect(x,y,w,h,r);
  fill(255,22); noStroke(); rect(x+3,y+3,w-6,h*0.40,r);
  stroke(red(bg),green(bg),blue(bg),120); strokeWeight(1.5); noFill(); rect(x,y,w,h,r); noStroke();
  fill(COL_TEXTBRT); textFont(fontTiny); textAlign(CENTER,CENTER); text(label,x+w/2,y+h/2+2);
}

boolean hitDevBtn(float x, float y, float w, float h) {
  return mouseX>=x && mouseX<=x+w && mouseY>=y && mouseY<=y+h;
}

void handleDevPanelTouch() {
  float xBtnX=width-80, xBtnY=devPanelY+18;
  if (hitDevBtn(xBtnX,xBtnY,60,60)) { devPanelOpen=false; vibrate(20); return; }
  if (mouseY < devPanelY+80) { devPanelOpen=false; return; }

  float rowY=devPanelY+160;
  float bW=(width-52)/2.0, bH=88;
  float col1X=18, col2X=18+bW+16;

  if (hitDevBtn(col1X,rowY,bW,bH)) { simScore(2,0);  vibrate(30); return; }
  if (hitDevBtn(col2X,rowY,bW,bH)) { simScore(1,0);  vibrate(30); return; }
  rowY+=bH+12;
  if (hitDevBtn(col1X,rowY,bW,bH)) { simScore(-2,0); vibrate(30); return; }
  if (hitDevBtn(col2X,rowY,bW,bH)) { simScore(-1,0); vibrate(30); return; }
  rowY+=bH+12;
  if (hitDevBtn(col1X,rowY,bW,bH)) { simMiss();      vibrate(30); return; }
  if (hitDevBtn(col2X,rowY,bW,bH)) { simMiss();      vibrate(30); return; }
  rowY+=bH+28;
  if (hitDevBtn(col1X,rowY,bW,bH)) {
    vibrate(40);
    if (gameRunning) onGameStopped();
    else { score=0; score2=0; gameRunning=true; duckBgMusic(); goToScreen(SCREEN_GAME); }
    return;
  }
  if (hitDevBtn(col2X,rowY,bW,bH)) {
    triggerGoalAnim((chosenPlayer==MESSI)?COL_ACCENT:COL_ORANGE); vibrate(50); return;
  }
  rowY+=bH+12;
  if (hitDevBtn(col1X,rowY,bW,bH)) {
    int p2=(chosenPlayer==MESSI)?RONALDO:MESSI;
    triggerGoalAnim((p2==MESSI)?COL_ACCENT:COL_ORANGE); vibrate(50); return;
  }
  if (hitDevBtn(col2X,rowY,bW,bH)) {
    btActive=!btActive; statusMsg=btActive?"SIMULATED":"NOT CONNECTED"; vibrate(30); return;
  }
}

void simScore(int deltaP1, int deltaP2) {
  parseArduino("P1:" + (score+deltaP1) + ",P2:" + (score2+deltaP2));
}
void simMiss() { parseArduino("P1:" + score + ",P2:" + score2); }

// ═══════════════════════════════════════════════════════════════════════════════
//  GAME FLOW
// ═══════════════════════════════════════════════════════════════════════════════
void toggleGame() {
  if (!gameRunning) startCountdown();
  else              stopGame();
}

void startCountdown() {
  countdownValue=3; countdownLastMs=millis();
  duckBgMusic(); goToScreen(SCREEN_COUNTDOWN);
}

void stopGame() {
  if (stopPending) return;
  stopPending=true; sendBT("X");
}

void onGameStopped() {
  gameRunning=false; stopPending=false;
  playSfx(sndStopId);
  vibratePattern(new long[]{0,60,60,60});
  newHighScore=false;
  if (gameMode==MODE_SINGLE && score>highScore) { highScore=score; newHighScore=true; }
  endCardY=height;
  restoreBgMusic();
  goToScreen(SCREEN_END);
}

void restartFromEnd() {
  score=0; score2=0;
  animState=ANIM_NONE; animState2=ANIM_NONE;
  scoreColorR=red(COL_TEXTBRT);   scoreColorG=green(COL_TEXTBRT);   scoreColorB=blue(COL_TEXTBRT);
  score2ColorR=red(COL_TEXTBRT);  score2ColorG=green(COL_TEXTBRT);  score2ColorB=blue(COL_TEXTBRT);
  goToScreen(SCREEN_MODE);
}

void goToScreen(int s) {
  if (s==SCREEN_PLAYER_P2) { vsAnimActive=true; vsAnimStartMs=millis(); }
  currentScreen=s;
}

void pressBtn(int id) { btnScale[id]=0.92; btnScaleTgt[id]=1.0; }

// ═══════════════════════════════════════════════════════════════════════════════
//  BLUETOOTH
// ═══════════════════════════════════════════════════════════════════════════════
void sendBT(String msg) {
  if (btOut!=null) {
    try { btOut.write((msg+"\n").getBytes()); btOut.flush(); }
    catch (Exception e) { println("BT send: "+e.getMessage()); }
  }
}

void onBluetoothDataEvent(String who, byte[] data) {
  if (!btActive) { btActive=true; statusMsg="CONNECTED"; }
  lineBuffer += new String(data);
  int idx;
  while ((idx=lineBuffer.indexOf('\n'))!=-1) {
    String line=lineBuffer.substring(0,idx).trim();
    lineBuffer=lineBuffer.substring(idx+1);
    if (line.length()>0) parseArduino(line);
  }
  if (btOut==null) grabBTOutputStream();
}

void onBluetoothDataEvent(String who, String data) {
  onBluetoothDataEvent(who, data.getBytes());
}

void parseArduino(String msg) {
  if (msg.startsWith("P1:")) {
    int commaIdx=msg.indexOf(",P2:");
    if (commaIdx==-1) return;
    int newP1=int(msg.substring(3,commaIdx));
    int newP2=int(msg.substring(commaIdx+4));
    int p2player=(chosenPlayer==MESSI)?RONALDO:MESSI;

    if (gameMode==MODE_SINGLE) {
      int delta=newP1-score;
      score=newP1;
      if (delta>0) {
        scoreScaleTarget=1.5;
        triggerAnim(chosenPlayer, ANIM_CELEBRATE);
        triggerGoalAnim((chosenPlayer==MESSI)?COL_ACCENT:COL_ORANGE);
        PImage celebPhoto = (chosenPlayer==MESSI) ? messiCelebPhoto : ronaldoCelebPhoto;
if (celebPhoto==null) celebPhoto=(chosenPlayer==MESSI)?messiPhoto:ronaldoPhoto;
        triggerTitleCard("SCORED", "+"+delta, COL_GOLD, 0.50, celebPhoto);
        playSfx(sndScoreId); vibrate(80);
      } else if (delta<0) {
        scoreScaleTarget=1.5;
        triggerAnim(chosenPlayer, ANIM_NEGATIVE);
        PImage sadPhoto = (chosenPlayer==MESSI) ? messiSadPhoto : ronaldoSadPhoto;
if (sadPhoto==null) sadPhoto=(chosenPlayer==MESSI)?messiPhoto:ronaldoPhoto;
        triggerTitleCard("PENALTY", ""+delta, COL_RED, 0.50, sadPhoto);
        playSfx(sndNegId); vibratePattern(new long[]{0,80,50,80});
      } else {
        triggerAnim(chosenPlayer, ANIM_SAD);
        PImage sadPhoto = (chosenPlayer==MESSI) ? messiSadPhoto : ronaldoSadPhoto;
        if (sadPhoto==null) sadPhoto = (chosenPlayer==MESSI) ? messiPhotoRounded : ronaldoPhotoRounded;
        triggerTitleCard("MISSED", "", COL_TEXTMID, 0.50, sadPhoto);
        playSfx(sndMissId); vibrate(50);
      }
    } else {
      int deltaP1=newP1-score, deltaP2=newP2-score2;
      score=newP1; score2=newP2;

      if (deltaP1>0) {
        scoreScaleTarget=1.5;
        triggerAnim(chosenPlayer, ANIM_CELEBRATE);
        triggerGoalAnim((chosenPlayer==MESSI)?COL_ACCENT:COL_ORANGE);
        PImage celebPhoto=(chosenPlayer==MESSI)?messiCelebPhoto:ronaldoCelebPhoto;
        if (celebPhoto==null) celebPhoto=(chosenPlayer==MESSI)?messiPhotoRounded:ronaldoPhotoRounded;
        triggerTitleCard("SCORED", "P1 +"+deltaP1, COL_GOLD, 0.44, celebPhoto);
        playSfx(sndScoreId); vibrate(80);
      } else if (deltaP1==0 && deltaP2==0) {
        triggerAnim(chosenPlayer, ANIM_SAD);
        PImage sadPhoto=(chosenPlayer==MESSI)?messiSadPhoto:ronaldoSadPhoto;
        if (sadPhoto==null) sadPhoto=(chosenPlayer==MESSI)?messiPhotoRounded:ronaldoPhotoRounded;
        triggerTitleCard("MISSED", "PLAYER 1", COL_TEXTMID, 0.44, sadPhoto);
        playSfx(sndMissId); vibrate(40);
      }

      if (deltaP2>0) {
        score2ScaleTarget=1.5;
        triggerAnim(p2player, ANIM_CELEBRATE);
        triggerGoalAnim((p2player==MESSI)?COL_ACCENT:COL_ORANGE);
        PImage celebPhoto2=(p2player==MESSI)?messiCelebPhoto:ronaldoCelebPhoto;
        if (celebPhoto2==null) celebPhoto2=(p2player==MESSI)?messiPhotoRounded:ronaldoPhotoRounded;
        triggerTitleCard("SCORED", "P2 +"+deltaP2, COL_ORANGE, 0.56, celebPhoto2);
        playSfx(sndScoreId); vibrate(80);
      }
    }
    return;
  }
  if (msg.equals("STOPPED")) onGameStopped();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GOAL ANIMATION (3D)
// ═══════════════════════════════════════════════════════════════════════════════
void triggerGoalAnim(color c) {
  goalAnimActive=true; goalAnimStartMs=millis(); goalAnimColor=c;
  fireParticles.clear();
  goalBallEndX=random(-60,60); goalBallEndY=random(20,80); goalBallEndZ=-280;
  goalTitleShown=false;
}

void drawGoalScene3D() {
  float elapsed  = millis() - goalAnimStartMs;
  float progress = elapsed / (float)GOAL_ANIM_DUR;

  if (progress >= 1.0) { goalAnimActive=false; fireParticles.clear(); return; }

  float camX=lerp(300,0,progress), camY=lerp(-250,-50,progress), camZ=lerp(300,150,progress);
  camera(camX,camY,camZ, 0,-50,-200, 0,1,0);

  ambientLight(90,95,110);
  directionalLight(255,240,220, 0.5,0.8,-0.5);

  pushMatrix();
  fill(28,115,52); noStroke(); translate(0,0,-200); box(2000,2,2000);
  fill(255,180); translate(0,2,0); box(600,2,10);
  popMatrix();

  float gw=120, gh=110, gd=80, postT=8;
  fill(245,248,255); noStroke();
  pushMatrix(); translate(-gw,-gh/2,-200); box(postT,gh,postT); popMatrix();
  pushMatrix(); translate( gw,-gh/2,-200); box(postT,gh,postT); popMatrix();
  pushMatrix(); translate(0,-gh,-200); box(gw*2+postT,postT,postT); popMatrix();

  stroke(255,100); strokeWeight(1.5);
  int netCols=12, netRows=8;
  float bulge=(progress>0.5 && progress<0.85) ? sin(map(progress,0.5,0.85,0,PI))*45 : 0;
  for (int i=0; i<=netCols; i++) {
    float tx=map(i,0,netCols,-gw,gw);
    float lb=(abs(tx)<gw*0.8) ? bulge : bulge*0.3;
    line(tx,-gh,-200, tx,0,-200-gd-lb);
  }
  for (int i=0; i<=netRows; i++) {
    float ty=map(i,0,netRows,-gh,0);
    line(-gw,ty,-200-gd/2, gw,ty,-200-gd/2-bulge);
  }
  noStroke();

  float ballT=constrain(map(progress,0.05,0.55,0,1),0,1);
  float ballEase=1-pow(1-ballT,2.5);
  float startX=180, startY=-20, startZ=150;
  float endX=goalBallEndX, endY=-goalBallEndY, endZ=goalBallEndZ;
  float bx=lerp(startX,endX,ballEase);
  float bz=lerp(startZ,endZ,ballEase);
  float by=lerp(startY,endY,ballEase)-sin(ballT*PI)*90;
  if (progress>0.55) {
    float dropEase=constrain(map(progress,0.55,0.8,0,1),0,1);
    by=lerp(endY,-12,dropEase); bz=endZ+dropEase*15;
  }

  if (ballT>0.05 && ballT<0.95) {
    for (int i=0; i<4; i++)
      fireParticles.add(new FireParticle(bx+random(-8,8),by+random(-8,8),bz+random(-8,8),1.2));
  }
  for (int i=fireParticles.size()-1; i>=0; i--) {
    FireParticle fp=fireParticles.get(i); fp.update(); fp.display3D();
    if (fp.alpha<=0) fireParticles.remove(i);
  }

  pushMatrix();
  translate(bx,by,bz);
  float spin=ballEase*TWO_PI*5; rotateX(spin); rotateY(spin*0.7);
  fill(250); noStroke(); sphere(14);
  fill(30);
  pushMatrix(); translate(0,0,13); sphere(5); popMatrix();
  pushMatrix(); translate(0,13,0); sphere(5); popMatrix();
  pushMatrix(); translate(13,0,0); sphere(5); popMatrix();
  popMatrix();

  if (progress>0.52 && progress<0.65) {
    float flashA=sin(map(progress,0.52,0.65,0,PI))*140;
    fill(red(goalAnimColor),green(goalAnimColor),blue(goalAnimColor),flashA);
    pushMatrix(); translate(0,-gh/2,-200); box(gw*3,gh*3,200); popMatrix();
  }

  if (progress>0.55 && !goalTitleShown) {
    triggerGoalTitleCard(goalAnimColor);
    goalTitleShown=true;
    vibrate(150);
  }
}

void drawGoalFrame3D(float gx, float top, float bot, float gw, float gd, float progress) {
  float postR=7;
  float appear=constrain(map(progress,0,0.14,0,1),0,1);
  pushMatrix();
  translate(gx,0,0);
  pushMatrix(); translate(0,(top+bot)/2,0); fill(240,245,255); noStroke(); box(postR*2,bot-top,postR*2); popMatrix();
  pushMatrix(); translate(-gw/2,top,0); box(gw,postR*2,postR*2); popMatrix();
  pushMatrix(); translate(-gd,(top+bot)/2,-gd*0.35); fill(210,218,230); box(postR*1.5,bot-top,postR*1.5); popMatrix();
  pushMatrix(); translate(-gd/2,top,-gd*0.35); box(gd,postR*1.5,postR*1.5); popMatrix();
  stroke(255,220*appear); strokeWeight(1.3);
  int nv=8,nh=6;
  for (int v=0; v<=nv; v++) {
    float tx=map(v,0,nv,-gw,0);
    line(tx,top,0, tx-gd,top,-gd*0.35);
    line(tx,bot,0, tx-gd,bot,-gd*0.2);
  }
  for (int h=0; h<=nh; h++) {
    float ty=map(h,0,nh,top,bot);
    line(-gw,ty,0,-gd,ty,-gd*0.28);
    line(0,ty,0,-gd,ty,-gd*0.28);
    line(-gw,ty,0,0,ty,0);
  }
  noStroke();
  if (progress>0.54 && progress<0.76) {
    float bulge=sin(map(progress,0.54,0.76,0,PI))*28;
    float midY=(top+bot)/2;
    stroke(255,180); strokeWeight(2); noFill();
    beginShape();
    for (float t=0; t<=1; t+=0.06) {
      float px=bezierPoint(-gw*0.5,-gw-bulge,-gw-bulge,0,t);
      float py=bezierPoint(midY,midY-35,midY+35,midY,t);
      float pz=bezierPoint(0,-gd*0.2,-gd*0.2,0,t);
      vertex(px,py,pz);
    }
    endShape(); noStroke();
  }
  popMatrix();
}

void drawFireball3D(float x, float y, float z, float r) {
  pushMatrix();
  translate(x,y,z);
  for (int g=5; g>=1; g--) {
    pushMatrix(); scale(1+g*0.12); fill(255,100+g*15,20,40); noStroke(); sphere(r*(1+g*0.08)); popMatrix();
  }
  fill(248,246,238); noStroke(); sphere(r);
  fill(22,22,22);
  pushMatrix(); translate(0,0,r*0.92); sphere(r*0.22); popMatrix();
  for (int p=0; p<5; p++) {
    float a=p*TWO_PI/5-HALF_PI;
    pushMatrix(); translate(cos(a)*r*0.65,sin(a)*r*0.65,0); sphere(r*0.14); popMatrix();
  }
  popMatrix();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GOAL TITLE CARD ("Goal!" slam)
// ═══════════════════════════════════════════════════════════════════════════════
void triggerGoalTitleCard(color accentCol) {
  goalCardActive=true; goalCardStartMs=millis(); goalCardColor=accentCol;
}

void drawGoalTitleCard() {
  if (!goalCardActive) return;
  float p=constrain((millis()-goalCardStartMs)/(float)GOAL_CARD_DUR,0,1);
  if (p>=1.0) { goalCardActive=false; return; }

  float scaleP=constrain(p/0.22,0,1);
  float scaleEase=1-pow(1-scaleP,4);
  float sc=lerp(2.8,1.0,scaleEase)+sin(scaleP*PI)*0.18;
  float alpha=(p>0.75)?map(p,0.75,1.0,255,0):255;

  pushMatrix();
  translate(cx, height*0.38); scale(sc);
  for (int g=6; g>=1; g--) {
    fill(20,10,0,alpha*0.9); textFont(fontBig); textAlign(CENTER,CENTER); text("Goal!",g*1.5,g*1.5);
  }
  fill(210,80,10,alpha); textFont(fontBig); textAlign(CENTER,CENTER); text("Goal!",0,3);
  fill(255,165,20,alpha); text("Goal!",0,0);
  fill(255,240,200,alpha*0.55); text("Goal!",0,-6);
  noFill(); stroke(30,18,0,alpha*0.8); strokeWeight(3); noStroke();
  popMatrix();

  if (p<0.18) {
    float shakeAmt=(1-p/0.18)*11;
    translate(random(-shakeAmt,shakeAmt),random(-shakeAmt,shakeAmt));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DEVICE PICKER
// ═══════════════════════════════════════════════════════════════════════════════
void openDevicePicker() {
  try {
    BluetoothAdapter adapter=BluetoothAdapter.getDefaultAdapter();
    if (adapter==null) { statusMsg="NO BT ADAPTER"; return; }
    Set<BluetoothDevice> bonded=adapter.getBondedDevices();
    pairedDevices.clear();
    for (BluetoothDevice d:bonded) pairedDevices.add(d);
  } catch (Exception e) { statusMsg="PICKER ERROR"; return; }
  if (pairedDevices.size()==0) { statusMsg="NO PAIRED DEVICES"; return; }
  pickerY=height*0.22; showPicker=true;
}

void drawDevicePicker() {
  fill(0,0,0,160); noStroke(); rect(0,0,width,height);
  float rowH=76, hdrH=72, ftrH=56;
  float pH=hdrH+rowH*pairedDevices.size()+ftrH+16;
  float pW=width*0.82, pX=(width-pW)/2.0, pY=cy-pH/2.0;
  fill(COL_BG2); noStroke(); rect(pX,pY,pW,pH,18);
  stroke(COL_ACCENT,100); strokeWeight(1.5); noFill(); rect(pX,pY,pW,pH,18); noStroke();
  fill(COL_ACCENT); textFont(fontTiny); textAlign(CENTER,CENTER);
  text("SELECT DEVICE",pX+pW/2,pY+hdrH/2);
  stroke(COL_EDGE,80); strokeWeight(1); line(pX+16,pY+hdrH,pX+pW-16,pY+hdrH); noStroke();
  for (int i=0; i<pairedDevices.size(); i++) {
    float ry=pY+hdrH+i*rowH;
    fill(COL_PANEL); noStroke(); rect(pX+8,ry+4,pW-16,rowH-8,10);
    fill(COL_TEXTBRT); textFont(fontTiny); textAlign(LEFT,CENTER);
    text(pairedDevices.get(i).getName(),pX+24,ry+rowH*0.38);
    fill(COL_TEXTDIM); text(pairedDevices.get(i).getAddress(),pX+24,ry+rowH*0.72);
    if (i<pairedDevices.size()-1) { stroke(COL_EDGE,50); strokeWeight(1); line(pX+16,ry+rowH,pX+pW-16,ry+rowH); noStroke(); }
  }
  float cancelY=pY+hdrH+rowH*pairedDevices.size()+8;
  fill(COL_RED,200); noStroke(); rect(pX+16,cancelY,pW-32,ftrH-16,10);
  fill(COL_TEXTBRT); textFont(fontTiny); textAlign(CENTER,CENTER);
  text("CANCEL",pX+pW/2,cancelY+(ftrH-16)/2);
}

void handlePickerTouch() {
  float rowH=76, hdrH=72, ftrH=56;
  float pH=hdrH+rowH*pairedDevices.size()+ftrH+16;
  float pW=width*0.82, pX=(width-pW)/2.0, pY=cy-pH/2.0;
  float cancelY=pY+hdrH+rowH*pairedDevices.size()+8;
  if (mouseY>=cancelY && mouseY<=cancelY+ftrH-16 && mouseX>=pX+16 && mouseX<=pX+pW-16) {
    showPicker=false; return;
  }
  for (int i=0; i<pairedDevices.size(); i++) {
    float ry=pY+hdrH+i*rowH;
    if (mouseY>=ry && mouseY<=ry+rowH && mouseX>=pX && mouseX<=pX+pW) {
      connectToDevice(pairedDevices.get(i)); return;
    }
  }
}

void connectToDevice(BluetoothDevice dev) {
  showPicker=false; btOut=null;
  try { bt.connectDevice(dev.getAddress()); statusMsg="CONNECTING..."; }
  catch (Exception e) { statusMsg="CONNECT FAILED"; }
}

void grabBTOutputStream() {
  try {
    java.lang.reflect.Field f=bt.getClass().getDeclaredField("currentConnections");
    f.setAccessible(true);
    java.util.HashMap conns=(java.util.HashMap)f.get(bt);
    if (conns==null||conns.isEmpty()) return;
    Object conn=conns.values().iterator().next();
    Class cls=conn.getClass();
    while (cls!=null) {
      for (java.lang.reflect.Field ff:cls.getDeclaredFields()) {
        ff.setAccessible(true);
        Object val=null;
        try { val=ff.get(conn); } catch (Exception e) { continue; }
        if (val==null) continue;
        if (val instanceof android.bluetooth.BluetoothSocket) {
          btOut=((android.bluetooth.BluetoothSocket)val).getOutputStream(); return;
        }
        if (val instanceof java.io.OutputStream) { btOut=(java.io.OutputStream)val; return; }
      }
      cls=cls.getSuperclass();
    }
  } catch (Exception e) { println("grabBTOut: "+e.getMessage()); }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DRAW HELPERS
// ═══════════════════════════════════════════════════════════════════════════════
void drawGlowButton(float x, float y, float w, float h, String label, color bg, color fg) {
  float r=h/2.0;
  fill(0,60); noStroke(); rect(x+3,y+5,w,h,r);
  fill(bg); noStroke(); rect(x,y,w,h,r);
  fill(255,22); noStroke(); rect(x+4,y+4,w-8,h*0.42,r);
  fill(fg); textFont(fontSm); textAlign(CENTER,CENTER); text(label,x+w/2,y+h/2+2);
}

void drawOutlineButton(float x, float y, float w, float h, String label, color border, color fg) {
  float r=h/2.0;
  fill(0,30); noStroke(); rect(x+2,y+4,w,h,r);
  fill(red(COL_PANEL),green(COL_PANEL),blue(COL_PANEL),200); noStroke(); rect(x,y,w,h,r);
  stroke(border); strokeWeight(2); noFill(); rect(x,y,w,h,r); noStroke();
  fill(fg); textFont(fontSm); textAlign(CENTER,CENTER); text(label,x+w/2,y+h/2+2);
}

boolean hitBtn(float x, float y, float w, float h) {
  return mouseX>=x && mouseX<=x+w && mouseY>=y && mouseY<=y+h;
}

void triggerAnim(int player, int state) {
  if (player==chosenPlayer) { animState=state;  animStartMs=millis(); }
  else                      { animState2=state; animStart2Ms=millis(); }
}

void triggerTitleCard(String main, String sub, color accent, float ySlot, PImage photo) {
  titleCards.add(new BoysTitleCard(main, sub, accent, ySlot, photo));
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TITLE CARDS DRAW
// ═══════════════════════════════════════════════════════════════════════════════
void drawBoysTitleCards() {
  for (int i=titleCards.size()-1; i>=0; i--) {
    BoysTitleCard card=titleCards.get(i);
    float p=card.progress();

    float slideInEnd=0.28, holdEnd=0.78;
    float cardH=height*0.14;
    float targetY=height*card.ySlot-cardH*0.5;
    float startY=-cardH-40;
    float cardY, cardAlpha;

    if (p<slideInEnd) {
      float t=p/slideInEnd, ease=1-pow(1-t,4);
      cardY=lerp(startY,targetY,ease); cardAlpha=ease*255;
    } else if (p<holdEnd) {
      cardY=targetY; cardAlpha=255;
    } else {
      float t=(p-holdEnd)/(1-holdEnd);
      cardY=lerp(targetY,targetY-30,t); cardAlpha=lerp(255,0,t);
    }

    float cardW=width*0.92, cardX=cx-cardW/2;

    pushMatrix();
    translate(0, cardY);

    fill(0,cardAlpha*0.55); noStroke(); rect(cardX+6,8,cardW,cardH,4);
    fill(0,cardAlpha*0.94); rect(cardX,0,cardW,cardH,4);
    fill(196,18,28,cardAlpha);
    rect(cardX,0,cardW,5,4,4,0,0);
    rect(cardX,cardH-5,cardW,5,0,0,4,4);
    fill(red(card.accentCol),green(card.accentCol),blue(card.accentCol),cardAlpha*0.9);
    rect(cardX+14,cardH*0.22,4,cardH*0.56,2);

    // Player photo — uses per-event photo if set
    PImage cardPhoto = card.photo;
if (cardPhoto != null) {
  float photoH = cardH * 0.92;
  float photoW = photoH * 0.60;
  float photoX = cardX + cardW - photoW - 8;
  float photoY2 = cardH * 0.04;
  tint(255, cardAlpha);
  imageMode(CORNER);
  PImage scaled = cropImageCover(cardPhoto, (int)photoW, (int)photoH);
  if (scaled != null) image(scaled, photoX, photoY2, photoW, photoH);
  noTint();
}

    fill(255,cardAlpha); textFont(fontMed); textAlign(CENTER,CENTER);
    float mainY=cardH*0.42;
    if (card.subText!=null && card.subText.length()>0) mainY=cardH*0.36;

    for (int g=4; g>=1; g--) {
      fill(196,18,28,(cardAlpha*0.12)/g);
      text(card.mainText,cx+g,mainY+g);
    }
    fill(255,cardAlpha); text(card.mainText,cx,mainY);

    if (card.subText!=null && card.subText.length()>0) {
      fill(red(card.accentCol),green(card.accentCol),blue(card.accentCol),cardAlpha*0.95);
      textFont(fontTiny); text(card.subText.toUpperCase(),cx,cardH*0.72);
    }

    popMatrix();
    if (card.isDone()) titleCards.remove(i);
  }
}
