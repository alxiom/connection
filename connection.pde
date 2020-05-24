int scaleFactor = 2;
int tileRow = 5;
int tileCol = 5;
int frameWidth = 5 * scaleFactor;
int tileWidth = 40 * scaleFactor;
int tileHeight = 40 * scaleFactor;
int pressCount = 0;
StringList rowKey = new StringList("q", "w", "e", "r", "t");
StringList colKey = new StringList("1", "2", "3", "4", "5");
boolean[] rowKeyPressed = new boolean[tileRow];
boolean[] colKeyPressed = new boolean[tileCol];

void setup() {
  size(460, 460);
  background(0);
  stroke(255);
}

void draw() {
  println(pressCount);
  for (int i = 0; i < tileRow; i++) {
    for (int j = 0; j < tileCol; j++) {
      if (rowKeyPressed[i] && colKeyPressed[j]) {
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
  String keyString = str(key);
  if (rowKey.hasValue(keyString)) {
    int keyIndex = findIndex(rowKey, keyString);
    if (keyIndex >= 0) {
      rowKeyPressed[keyIndex] = true;
    }
  }
  else if (colKey.hasValue(keyString)) {
    int keyIndex = findIndex(colKey, keyString);
    if (keyIndex >= 0) {
      colKeyPressed[keyIndex] = true;
    }
  }
}

void keyReleased() {
  String keyString = str(key);
  if (rowKey.hasValue(keyString)) {
    int keyIndex = findIndex(rowKey, keyString);
    if (keyIndex >= 0) {
      rowKeyPressed[keyIndex] = false;
    }
  }
  else if (colKey.hasValue(keyString)) {
    int keyIndex = findIndex(colKey, keyString);
    if (keyIndex >= 0) {
      colKeyPressed[keyIndex] = false;
    }
  }
}

int findIndex(StringList keyList, String keyString) {
  for (int i = 0; i < keyList.size(); i++) {
    if (keyList.get(i).equals(keyString)) {
      return i;
    }
  }
  return -1;
}

//int countPress() {
  
//}
