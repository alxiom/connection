int scaleFactor = 2;
int tileRow = 5;
int tileCol = 5;
int frameWidth = 5 * scaleFactor;
int tileWidth = 40 * scaleFactor;
int tileHeight = 40 * scaleFactor;
int pressCount = 0;
String tileKey = "abcdefghijklmnopqrstuvwxyz";
int tileCount = tileKey.length();
boolean[] tilePressed = new boolean[tileCount];

void setup() {
  size(460, 460);
  background(0);
  stroke(255);
}

void draw() {
  for (int i = 0; i < tileRow; i++) {
    for (int j = 0; j < tileCol; j++) {
      if (tilePressed[i * tileRow + j]) {
        fill(255, 0, 0);
      } else {
        fill(0);
      }
      int x = frameWidth * (j + 1) + tileWidth * j;
      int y = frameWidth * (i + 1) + tileWidth * i;
      rect(x, y, tileWidth, tileHeight);
    }
  }
}

void keyPressed() {
  setTilePressed(true);
}

void keyReleased() {
  setTilePressed(false);
}

void setTilePressed(boolean isPressed) {
  String keyString = str(key);
  int keyIndex = tileKey.indexOf(keyString); 
  if (keyIndex >= 0) {
    tilePressed[keyIndex] = isPressed;
  }
}
