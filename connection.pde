int scaleFactor = 2;
int tileRow = 5;
int tileCol = 5;
int frameWidth = 5 * scaleFactor;
int tileWidth = 40 * scaleFactor;
int tileHeight = 40 * scaleFactor;
String tileKey = "abcdefghijklmnopqrstuvwxy";
int tileCount = tileKey.length();
StringList currentPressed = new StringList();
boolean[] tilePressed = new boolean[tileCount];
int[] cursorPosition = new int[tileCount];
int cursorSize = 5;

void setup() {
  size(460, 460);
}

void draw() {
  background(0);
  fillTile();
}

void fillTile() {
  for (int i = 0; i < tileRow; i++) {
    for (int j = 0; j < tileCol; j++) {
      int tileIndex = i * tileRow + j;
      stroke(255);    
      if (tilePressed[tileIndex]) {
        fill(255, 0, 0);
      } else {
        fill(0);
      }
      
      int x = frameWidth * (j + 1) + tileWidth * j;
      int y = frameWidth * (i + 1) + tileWidth * i;
      rect(x, y, tileWidth, tileHeight);
      
      if (tilePressed[tileIndex] && countPressedTile() >= 2) {
        noStroke();
        fill(255, 200, 200);
        int cursorX;
        int cursorY;
        if (cursorPosition[tileIndex] == 1) {
          cursorX = x + tileWidth / 2;
          cursorY = y;
        } else if (cursorPosition[i * tileRow + j] == 2) {
          cursorX = x + tileWidth;
          cursorY = y + tileHeight / 2;
        } else if (cursorPosition[i * tileRow + j] == 3) {
          cursorX = x + tileWidth / 2;
          cursorY = y + tileHeight;
        } else if (cursorPosition[i * tileRow + j] == 4) {
          cursorX = x;
          cursorY = y + tileHeight / 2;
        } else {
          cursorX = x + tileWidth / 2;
          cursorY = y + tileHeight / 2;
        }
        ellipse(cursorX, cursorY, cursorSize, cursorSize);
      }

    }
  }
}

void keyPressed() {
  if (!currentPressed.hasValue(str(key))) {
    setTilePressed(true);
    currentPressed.append(str(key));
  }
}

void keyReleased() {
  setTilePressed(false);
  int popIndex = findIndex(currentPressed, str(key));
  currentPressed.remove(popIndex);
}

void setTilePressed(boolean isPressed) {
  String keyString = str(key);
  int keyIndex = tileKey.indexOf(keyString);
  if (keyIndex >= 0) {
    tilePressed[keyIndex] = isPressed;
    if (isPressed) {
      cursorPosition[keyIndex] = int(random(4)) + 1;
    } else {
      cursorPosition[keyIndex] = 0;
    }
  }
}

int countPressedTile() {
  int countPressed = 0;
  for (int i = 0; i < tileCount; i++) {
    if (tilePressed[i]) {
      countPressed += 1;
    }
  }
  return countPressed;
}

int findIndex(StringList keyList, String keyString) {
  for (int i = 0; i < keyList.size(); i++) {
    if (keyList.get(i).equals(keyString)) {
      return i;
    }
  }
  return -1;
}
