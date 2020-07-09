import codeanticode.syphon.*;

int rowCount = 5;
int colCount = 5;

int scaleFactor = 4;
int monadSize = 40 * scaleFactor;
int frameWidth = 6 * scaleFactor;

String monadKeys = "abcdefghijklmnopqrstuvwxy";
int monadCount = monadKeys.length();

StringList activatedMonadKey = new StringList();
boolean[] activatedMonad = new boolean[monadCount];

Monad[] monads = new Monad[monadCount];
boolean[][][] intersections = new boolean[rowCount + 1][colCount + 1][4];
int[] verticalDirections = {0, 2};
int[] horizontalDirections = {1, 3};

int cursorMemory = 100;
float cursorVelocity = 30.0;

color[] monadColors = {
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

PGraphics canvas;
SyphonServer server;

void setup() {
  size(920, 920, P3D);
  background(0);
  frameRate(30);
    
  canvas = createGraphics(920, 920, P3D);
  server = new SyphonServer(this, "Processing Syphon");
  
  initMonad();
  initIntersections();
}

void draw() {
  canvas.beginDraw();
  canvas.stroke(0, 6);
  canvas.strokeWeight(frameWidth);
  for (int i = 0; i <= rowCount; i++) {
    canvas.line(
      0, 
      i * (monadSize + frameWidth),
      width, 
      i * (monadSize + frameWidth)
    );
  }
  
  for (int i = 0; i <= colCount; i++) {
    canvas.line( 
      i * (monadSize + frameWidth),
      0,
      i * (monadSize + frameWidth),
      height
    );
  }
  
  
  for (Monad monad : monads) {
    monad.checkActivate();
    monad.displayMonad();
    monad.displayCursor();
  }
  
  canvas.endDraw();
  image(canvas, 0, 0);
  server.sendImage(canvas);
}

class Monad {

  int id;
  PVector position;
  Boolean isActivated;
  Boolean wasActivated;
  String monadKey;
  
  color monadColor;
  color cursorColor;

  int[] currentCursorDirections = new int[monadCount];
  PVector[] currentCursorPositions = new PVector[monadCount];
  float[][][] cursorHistory = new float[monadCount][cursorMemory][2];

  Monad(int idInput, PVector positionInput) {
    position = positionInput;
    id = idInput;
    isActivated = false;
    wasActivated = false;
    monadKey = str(monadKeys.charAt(id));
    monadColor = monadColors[id];
    cursorColor = color(random(100, 255), random(100, 255), random(100, 255));
  }

  void checkActivate() {
    wasActivated = isActivated;
    isActivated = activatedMonad[id];
  }

  void displayMonad() {
    if (isActivated) {
      canvas.fill(monadColor);
    } else {
      canvas.fill(0);
    }
    canvas.stroke(255);
    canvas.strokeWeight(1);
    canvas.rect(
      position.x - monadSize / 2, 
      position.y - monadSize / 2, 
      monadSize, 
      monadSize
    );
  }

  void displayCursor() {
    if (isActivated) {
      int cursorCount = countActivatedMonad() - 1;
      if (cursorCount >= 1) {
        for (int targetIndex = 0; targetIndex < monadCount; targetIndex++) {
          if (!wasActivated) {
            initializeCursor(targetIndex);
          }
          if (targetIndex != id && activatedMonad[targetIndex]) {
            canvas.line(
              cursorHistory[targetIndex][cursorMemory - 1][0], 
              cursorHistory[targetIndex][cursorMemory - 1][1], 
              cursorHistory[targetIndex][cursorMemory - 2][0], 
              cursorHistory[targetIndex][cursorMemory - 2][1]
            );
            PVector targetPosition = convertPosition(targetIndex);
            PVector currentPosition = currentCursorPositions[targetIndex];
            float distance = PVector.dist(targetPosition, currentPosition);
            if (distance >= monadSize / 2.0 + frameWidth) {
              displayConnection(targetIndex, targetPosition);
            } else {
              displayCursorHistory(targetIndex, targetPosition);
            }
          }
        }
      } else {
        for (int i = 0; i < monadCount; i++) {
          initializeCursor(i);
        }
      } 
    } else {
        for (int i = 0; i < monadCount; i++) {
          initializeCursor(i);
        } 
    }
  }
  
  void displayConnection(int targetIndex, PVector targetPosition) {
    PVector currentCursorPosition = currentCursorPositions[targetIndex];
    int currentCursorDirection = currentCursorDirections[targetIndex];
    float updateX = currentCursorPosition.x;
    float updateY = currentCursorPosition.y;
    if (currentCursorDirection == 0) {
      updateY -= cursorVelocity;
    } else if (currentCursorDirection == 1) {
      updateX -= cursorVelocity;
    } else if (currentCursorDirection == 2) {
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
          int reverseDirection = (currentCursorDirection + 2) % 4;
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
      currentCursorDirections[targetIndex] = candidate;
    }
    canvas.stroke(cursorColor);
    canvas.strokeCap(ROUND);
    canvas.strokeWeight(2 * scaleFactor);
    canvas.line(
      currentCursorPosition.x, 
      currentCursorPosition.y, 
      nextCursorPosition.x, 
      nextCursorPosition.y
    );
    currentCursorPositions[targetIndex] = nextCursorPosition;
    
    // shift history to left
    for (int j = 1; j < cursorMemory; j++) {
      cursorHistory[targetIndex][j - 1][0] = cursorHistory[targetIndex][j][0];
      cursorHistory[targetIndex][j - 1][1] = cursorHistory[targetIndex][j][1];
    }
    cursorHistory[targetIndex][cursorMemory - 1][0] = nextCursorPosition.x;
    cursorHistory[targetIndex][cursorMemory - 1][1] = nextCursorPosition.y;
  }
  
  void displayCursorHistory(int targetIndex, PVector targetPosition) {
    canvas.stroke(cursorColor);
    canvas.strokeCap(ROUND);
    canvas.strokeWeight(2 * scaleFactor);
    float[] lastCursor = new float[2];
    for (int j = 0; j < cursorMemory - 1; j ++) {
      float[] currentCursor = cursorHistory[targetIndex][j];
      if (currentCursor[0] > 0.0 && currentCursor[1] > 0.0) {
        float[] nextCursor = cursorHistory[targetIndex][j + 1];
        if (nextCursor[0] > 0.0 && nextCursor[1] > 0.0) {
          canvas.line(
            currentCursor[0], 
            currentCursor[1], 
            nextCursor[0], 
            nextCursor[1]
          );
          lastCursor = nextCursor;
        }
      }
    }
    
    float frameWidthRatio = frameWidth / float(monadSize + frameWidth);
    canvas.line(
      lastCursor[0], 
      lastCursor[1], 
      (targetPosition.x - lastCursor[0]) * frameWidthRatio + lastCursor[0],
      (targetPosition.y - lastCursor[1]) * frameWidthRatio + lastCursor[1]
    );
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
      primaryY -= monadSize / 2.0;
      secondaryY -= (monadSize + frameWidth) / 2.0;
      initialDirection = horizontalDirections[randomDirection];
    } else if (randomEdge == 1) {
      primaryX -= monadSize / 2.0;
      secondaryX -= (monadSize + frameWidth) / 2.0;
      initialDirection = verticalDirections[randomDirection];
    } else if (randomEdge == 2) {
      primaryY += monadSize / 2.0;
      secondaryY += (monadSize + frameWidth) / 2.0;
      initialDirection = horizontalDirections[randomDirection];
    } else {
      primaryX += monadSize / 2.0;
      secondaryX += (monadSize + frameWidth) / 2.0;
      initialDirection = verticalDirections[randomDirection];
    }
              
    cursorColor = color(random(100, 255), random(100, 255), random(100, 255));
    cursorHistory[targetIndex] = new float[cursorMemory][2];    
    cursorHistory[targetIndex][cursorMemory - 2][0] = primaryX;
    cursorHistory[targetIndex][cursorMemory - 2][1] = primaryY;
    cursorHistory[targetIndex][cursorMemory - 1][0] = secondaryX;
    cursorHistory[targetIndex][cursorMemory - 1][1] = secondaryY;
    currentCursorPositions[targetIndex] = new PVector(secondaryX, secondaryY);
    currentCursorDirections[targetIndex] = initialDirection;
  }
}


void initMonad() {
  for (int i = 0; i < rowCount; i++) {
    for (int j = 0; j < colCount; j++) {
      int id = i * rowCount + j;
      float x = frameWidth * (j + 0.5) + monadSize * j + monadSize / 2;
      float y = frameWidth * (i + 0.5) + monadSize * i + monadSize / 2;
      PVector position = new PVector(x, y);
      monads[id] = new Monad(id, position);
    }
  }
}

void initIntersections() {
  for (int i = 0; i < rowCount + 1; i++) {
    for (int j = 0; j < colCount + 1; j++) {
      if (i == 0) {
        intersections[i][j][2] = true;
      } else if (i == rowCount) {
        intersections[i][j][0] = true;
      } else {
        intersections[i][j][0] = true;
        intersections[i][j][2] = true;
      }
  
      if (j == 0) {
        intersections[i][j][3] = true;
      } else if (j == colCount) {
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
  if (monadKeys.indexOf(key) >= 0) {
    if (!activatedMonadKey.hasValue(str(key))) {
      setMonadStatus(true);
      activatedMonadKey.append(str(key));
    }
  }
}

void keyReleased() {
  if (monadKeys.indexOf(key) >= 0) {
    setMonadStatus(false);
    int popKeyIndex = findIndex(str(key), activatedMonadKey);
    activatedMonadKey.remove(popKeyIndex);
  }
}

void setMonadStatus(boolean isActivated) {
  String keyString = str(key);
  int keyIndex = monadKeys.indexOf(keyString);
  if (keyIndex >= 0) {
    activatedMonad[keyIndex] = isActivated;
  }
}

int countActivatedMonad() {
  int count = 0;
  for (int i = 0; i < monadCount; i++) {
    if (activatedMonad[i]) {
      count += 1;
    }
  }
  return count;
}

PVector convertPosition(int index) {
  int j = index % rowCount;
  int i = index / rowCount;
  float x = frameWidth * (j + 0.5) + monadSize * j + monadSize / 2;
  float y = frameWidth * (i + 0.5) + monadSize * i + monadSize / 2;
  PVector xy = new PVector(x, y);
  return xy;
}

PVector convertIntersectionPosition(int[] intersectionIndex) {
  float x = (monadSize + frameWidth) * intersectionIndex[1];
  float y = (monadSize + frameWidth) * intersectionIndex[0];
  PVector xy = new PVector(x, y);
  return xy;
}

int[] findIntersectionIndex(PVector cursorPosition) {
  int[] cornerIndex = {-1, -1};
  for (int i = 0; i < rowCount + 1; i++) {
    float cornerY = (monadSize + frameWidth) * i;
    float distanceY = abs(cornerY - cursorPosition.y);
    
    if (distanceY < cursorVelocity) {
      
      for (int j = 0; j < colCount + 1; j++) {
        float cornerX = (monadSize + frameWidth) * j;
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
