import codeanticode.syphon.*;
import processing.sound.*;

boolean calibration = true;

PGraphics canvas;
SyphonServer server;

SoundFile bgm;
SoundFile sfx;

int rows = 5;
int cols = 5;

int scale = 4;
int tileSize = 40 * scale;
int frameWidth = 6 * scale;

String tileKeys = "abcdefghijklmnopqrstuvwxy";
int tileCount = tileKeys.length();

StringList activeTileKey = new StringList();
boolean[] activeTile = new boolean[tileCount];

Tile[] tiles = new Tile[tileCount];
boolean[][][] intersections = new boolean[rows + 1][cols + 1][4];
int[] vertical = {0, 2};
int[] horizontal = {1, 3};

color frameColor = color(50);
color[] tileColors = {
  color(200, 200, 255), // a 1
  color(255, 200, 255), // b 2
  color(200, 200, 255), // c 3
  color(255, 200, 255), // d 4
  color(200, 200, 255), // e 5
  color(255, 200, 255), // f 6
  color(200, 255, 200), // g 7
  color(255, 255, 200), // h 8
  color(200, 255, 200), // i 9
  color(255, 200, 255), // j 10
  color(200, 200, 255), // k 11
  color(255, 255, 200), // l 12
  color(200, 255, 255), // m 13
  color(255, 255, 200), // n 14
  color(200, 200, 255), // o 15
  color(255, 200, 255), // p 16
  color(200, 255, 200), // q 17
  color(255, 255, 200), // r 18
  color(200, 255, 200), // s 19
  color(255, 200, 255), // t 20
  color(200, 200, 255), // u 21
  color(255, 200, 255), // v 22
  color(200, 200, 255), // w 23
  color(255, 200, 255), // x 24
  color(200, 200, 255), // y 25
};

int cursorSize = 2;
int cursorMemory = 100;
float cursorVelocity = 30.0;

void setup() {
  size(920, 920, P3D);
  background(0);
  frameRate(30);
  
  canvas = createGraphics(920, 920, P3D);
  server = new SyphonServer(this, "Processing Syphon");
  
  initTile();
  initIntersections();
  loopSound();
}

void draw() {
  canvas.beginDraw();
  canvas.noFill();
  displayFrame();
  for (Tile tile : tiles) {
    tile.checkActivate();
    tile.displayTile();
    tile.displayCursor();
  }
  canvas.endDraw();
  image(canvas, 0, 0);
  server.sendImage(canvas);
}

class Tile {

  int id;
  PVector position;
  Boolean isActivated;
  String tileKey;
  
  color tileColor;
  color cursorColor;

  int[] cursorDirections = new int[tileCount];
  PVector[] cursorPositions = new PVector[tileCount];
  float[][][] cursorHistory = new float[tileCount][cursorMemory][2];

  Tile(int idInput, PVector positionInput) {
    position = positionInput;
    id = idInput;
    isActivated = false;
    tileKey = str(tileKeys.charAt(id));
    tileColor = tileColors[id];
    initializeCursorColor();
    for (int i = 0; i < tileCount; i++) {
      for (int j = 0; j < cursorMemory; j++) {
        cursorHistory[i][j][0] = -float(width);
        cursorHistory[i][j][1] = -float(height);
      }
    }
  }

  void checkActivate() {
    isActivated = activeTile[id];
  }

  void displayTile() {
    float x = position.x;
    float y = position.y;
    float rO = tileSize / 2.0;
    float rI = rO - frameWidth / 4.0;
    
    if (isActivated) {
      canvas.stroke(tileColor);
    } else {
      if (calibration) {
        canvas.stroke(255);
        canvas.textSize(12 * scale);
        canvas.text(tileKey, x - 3 * scale, y + 3 * scale);
      } else {
        canvas.stroke(0);
      }
    }
    
    canvas.strokeWeight(frameWidth / 2);
    canvas.line(x - rO, y - rI, x + rO, y - rI);
    canvas.line(x + rI, y - rO, x + rI, y + rO);
    canvas.line(x + rO, y + rI, x - rO, y + rI);
    canvas.line(x - rI, y + rO, x - rI, y - rO);
  }

  void displayCursor() {
    if (isActivated) {
      int cursorCount = countActiveTileKey() - 1;
      if (cursorCount >= 1) {
        for (int targetIndex = 0; targetIndex < tileCount; targetIndex++) {
          if (targetIndex != id && activeTile[targetIndex]) {
            PVector targetPosition = convertPosition(targetIndex);
            PVector currentPosition = cursorPositions[targetIndex];
            float distance = PVector.dist(targetPosition, currentPosition);
            if (distance > tileSize / 2 + frameWidth / 2 + 1.0) {
              moveCursor(targetIndex, targetPosition);
            }
            drawCursorHistory(targetIndex);
          } else {
            initializeCursor(targetIndex);
          }
        }
      } else {
        for (int i = 0; i < tileCount; i++) {
          initializeCursor(i);
          initializeCursorColor();
        }
      } 
    } else {
      for (int i = 0; i < tileCount; i++) {
        initializeCursor(i);
        initializeCursorColor();
      }
    }
  }
  
  void moveCursor(int targetIndex, PVector targetPosition) {
    PVector cursorPosition = cursorPositions[targetIndex];
    int cursorDirection = cursorDirections[targetIndex];
    float updateX = cursorPosition.x;
    float updateY = cursorPosition.y;
    if (cursorDirection == 0) {
      updateY -= cursorVelocity;
    } else if (cursorDirection == 1) {
      updateX -= cursorVelocity;
    } else if (cursorDirection == 2) {
      updateY += cursorVelocity;
    } else {
      updateX += cursorVelocity;
    }
    PVector nextCursorPosition = new PVector(updateX, updateY);
    int[] intersectionIndex = findIntersectionIndex(nextCursorPosition);
    int intersectionRow = intersectionIndex[0];
    int intersectionCol = intersectionIndex[1];
    if (intersectionRow >= 0 && intersectionCol >= 0) {
      nextCursorPosition = convertIntersectionPosition(intersectionIndex);
      IntList candidates = new IntList();
      for (int k = 0; k < 4; k++) {
        if (intersections[intersectionRow][intersectionCol][k]) {
          int reverseDirection = (cursorDirection + 2) % 4;
          if (k != reverseDirection) {
            if (k == 0 && targetPosition.y < nextCursorPosition.y) {
              candidates.append(k);
            }
            if (k == 1 && targetPosition.x < nextCursorPosition.x) {
              candidates.append(k);
            }
            if (k == 2 && targetPosition.y >= nextCursorPosition.y) {
              candidates.append(k);
            }
            if (k == 3 && targetPosition.x >= nextCursorPosition.x) {
              candidates.append(k);
            }
          }
        }
      }
      int candidate = candidates.get(int(random(candidates.size())));
      cursorDirections[targetIndex] = candidate;
    }
    cursorPositions[targetIndex] = nextCursorPosition;
    
    // shift history to left
    for (int j = 1; j < cursorMemory; j++) {
      cursorHistory[targetIndex][j - 1][0] = cursorHistory[targetIndex][j][0];
      cursorHistory[targetIndex][j - 1][1] = cursorHistory[targetIndex][j][1];
    }
    cursorHistory[targetIndex][cursorMemory - 1][0] = nextCursorPosition.x;
    cursorHistory[targetIndex][cursorMemory - 1][1] = nextCursorPosition.y;
    
    // calculate distance
    
    //float frameWidthRatio = frameWidth / float(tileSize + frameWidth);
    //canvas.vertex(
    //  lastCursor[0], 
    //  lastCursor[1]
    //);
    //canvas.vertex(
    //  (targetPosition.x - lastCursor[0]) * frameWidthRatio + lastCursor[0],
    //  (targetPosition.y - lastCursor[1]) * frameWidthRatio + lastCursor[1]
    //);
    
    
  }
  
  void drawCursorHistory(int targetIndex) {
    canvas.stroke(cursorColor, 180);
    canvas.strokeWeight(cursorSize * scale);
    canvas.beginShape();
    for (int j = 0; j < cursorMemory - 1; j ++) {
      float[] cursor = cursorHistory[targetIndex][j];
      if (cursor[0] > -float(width) && cursor[1] > -float(height)) {
        float[] nextCursor = cursorHistory[targetIndex][j + 1];
        if (nextCursor[0] > -float(width) && nextCursor[1] > -float(height)) {
          canvas.vertex(
            cursor[0], 
            cursor[1]
          );
        }
      }
    }
    canvas.endShape();
  }

  void initializeCursor(int targetIndex) {
    int randomEdge = int(random(0, 4));
    int randomDirection = int(random(2));
    int initialDirection;
    float primaryX = position.x;
    float primaryY = position.y;
    float secondaryX = position.x;
    float secondaryY = position.y;
    if (randomEdge == 0) {
      primaryY -= tileSize / 2.0;
      secondaryY -= (tileSize + frameWidth) / 2.0;
      initialDirection = horizontal[randomDirection];
    } else if (randomEdge == 1) {
      primaryX -= tileSize / 2.0;
      secondaryX -= (tileSize + frameWidth) / 2.0;
      initialDirection = vertical[randomDirection];
    } else if (randomEdge == 2) {
      primaryY += tileSize / 2.0;
      secondaryY += (tileSize + frameWidth) / 2.0;
      initialDirection = horizontal[randomDirection];
    } else {
      primaryX += tileSize / 2.0;
      secondaryX += (tileSize + frameWidth) / 2.0;
      initialDirection = vertical[randomDirection];
    }
    
    // reset cursor history
    for (int i = 0; i < cursorMemory; i++) {
      cursorHistory[targetIndex][i][0] = -float(width);
      cursorHistory[targetIndex][i][1] = -float(height);
    }
    cursorHistory[targetIndex][cursorMemory - 2][0] = primaryX;
    cursorHistory[targetIndex][cursorMemory - 2][1] = primaryY;
    cursorHistory[targetIndex][cursorMemory - 1][0] = secondaryX;
    cursorHistory[targetIndex][cursorMemory - 1][1] = secondaryY;
    cursorPositions[targetIndex] = new PVector(secondaryX, secondaryY);
    cursorDirections[targetIndex] = initialDirection;
  }
  
  void initializeCursorColor() {
    cursorColor = color(random(100, 255), random(100, 255), random(100, 255));
  }
}

void initTile() {
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      int id = i * rows + j;
      float x = frameWidth * (j + 0.5) + tileSize * j + tileSize / 2;
      float y = frameWidth * (i + 0.5) + tileSize * i + tileSize / 2;
      PVector position = new PVector(x, y);
      tiles[id] = new Tile(id, position);
    }
  }
}

void initIntersections() {
  for (int i = 0; i < rows + 1; i++) {
    for (int j = 0; j < cols + 1; j++) {
      if (i == 0) {
        intersections[i][j][2] = true;
      } else if (i == rows) {
        intersections[i][j][0] = true;
      } else {
        intersections[i][j][0] = true;
        intersections[i][j][2] = true;
      }
  
      if (j == 0) {
        intersections[i][j][3] = true;
      } else if (j == cols) {
        intersections[i][j][1] = true;
      } else {
        intersections[i][j][1] = true;
        intersections[i][j][3] = true;
      }
    }
  }
}

int findIndex(String keyString, StringList targetList) {
  for (int i = 0; i < targetList.size(); i++) {
    if (targetList.get(i).equals(keyString)) {
      return i;
    }
  }
  return -1;
}

void keyPressed() {
  if (tileKeys.indexOf(key) >= 0) {
    if (!activeTileKey.hasValue(str(key))) {
      setTileStatus(true);
      activeTileKey.append(str(key));
      
      sfx = new SoundFile(this, "connection effect.wav");
      sfx.play();
    }
  }
}

void keyReleased() {
  if (tileKeys.indexOf(key) >= 0) {
    setTileStatus(false);
    int popKeyIndex = findIndex(str(key), activeTileKey);
    activeTileKey.remove(popKeyIndex);
  }
}

void setTileStatus(boolean isActivated) {
  String keyString = str(key);
  int keyIndex = tileKeys.indexOf(keyString);
  if (keyIndex >= 0) {
    activeTile[keyIndex] = isActivated;
  }
}

int countActiveTileKey() {
  int count = 0;
  for (int i = 0; i < tileCount; i++) {
    if (activeTile[i]) {
      count += 1;
    }
  }
  return count;
}

PVector convertPosition(int index) {
  int j = index % rows;
  int i = index / rows;
  float x = frameWidth * (j + 0.5) + tileSize * j + tileSize / 2;
  float y = frameWidth * (i + 0.5) + tileSize * i + tileSize / 2;
  PVector xy = new PVector(x, y);
  return xy;
}

PVector convertIntersectionPosition(int[] intersectionIndex) {
  float x = (tileSize + frameWidth) * intersectionIndex[1];
  float y = (tileSize + frameWidth) * intersectionIndex[0];
  PVector xy = new PVector(x, y);
  return xy;
}

int[] findIntersectionIndex(PVector cursorPosition) {
  int[] cornerIndex = {-1, -1};
  for (int i = 0; i < rows + 1; i++) {
    float cornerY = (tileSize + frameWidth) * i;
    float distanceY = abs(cornerY - cursorPosition.y);
    if (distanceY < cursorVelocity) {
      for (int j = 0; j < cols + 1; j++) {
        float cornerX = (tileSize + frameWidth) * j;
        float distanceX = abs(cornerX - cursorPosition.x);
        if (distanceX < cursorVelocity) {
          cornerIndex[0] = i;
          cornerIndex[1] = j;
          return cornerIndex;
        }
      }
      return cornerIndex;
    }
  }
  return cornerIndex;
}

void loopSound() {
  bgm = new SoundFile(this, "connection bgm.wav");
  bgm.loop();
}

void displayFrame() {
  canvas.stroke(frameColor);
  canvas.strokeWeight(frameWidth);
  canvas.beginShape(LINES);
  for (int i = 0; i <= rows; i++) {
    canvas.vertex(0, i * (tileSize + frameWidth));
    canvas.vertex(width, i * (tileSize + frameWidth));
  }
  for (int i = 0; i <= cols; i++) {
    canvas.vertex(i * (tileSize + frameWidth), 0);
    canvas.vertex(i * (tileSize + frameWidth), height);
  }
  canvas.endShape();
}
