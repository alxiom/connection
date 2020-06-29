int rowCount = 5;
int colCount = 5;

int scaleFactor = 2;
int monadSize = 40 * scaleFactor;
int frameWidth = 5 * scaleFactor;

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

void setup() {
  size(460, 460);
  background(0);
  frameRate(30);
  initMonad();
  initIntersections();  
}

void draw() {
  noStroke();
  fill(0, 6);
  rect(0, 0, width, height);
  for (Monad monad : monads) {
    monad.checkActivate();
    monad.displayMonad();
    monad.displayCursor();
  }
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
    monadColor = color(255 - id * 10, 0, id * 10 + 5, 20);
    cursorColor = color(255 - id * 10, 128, id * 10 + 5);
  }

  void checkActivate() {
    wasActivated = isActivated;
    isActivated = activatedMonad[id];
  }

  void displayMonad() {
    if (isActivated) {
      fill(monadColor);
    } else {
      fill(0);
    }
    stroke(255);
    strokeWeight(1);
    rect(
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
            line(
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
    stroke(cursorColor);
    strokeCap(ROUND);
    strokeWeight(2 * scaleFactor);
    line(
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
    stroke(cursorColor);
    strokeCap(ROUND);
    strokeWeight(2 * scaleFactor);
    float[] lastCursor = new float[2];
    for (int j = 0; j < cursorMemory - 1; j ++) {
      float[] currentCursor = cursorHistory[targetIndex][j];
      if (currentCursor[0] > 0.0 && currentCursor[1] > 0.0) {
        float[] nextCursor = cursorHistory[targetIndex][j + 1];
        if (nextCursor[0] > 0.0 && nextCursor[1] > 0.0) {
          line(
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
    line(
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
      int x = frameWidth * (j + 1) + monadSize * j + monadSize / 2;
      int y = frameWidth * (i + 1) + monadSize * i + monadSize / 2;
      PVector position = new PVector(float(x), float(y));
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
  int x = frameWidth * (j + 1) + monadSize * j + monadSize / 2;
  int y = frameWidth * (i + 1) + monadSize * i + monadSize / 2;
  PVector xy = new PVector(float(x), float(y));
  return xy;
}

PVector convertIntersectionPosition(int[] intersectionIndex) {
  float x = frameWidth / 2.0 + (monadSize + frameWidth) * intersectionIndex[1];
  float y = frameWidth / 2.0 + (monadSize + frameWidth) * intersectionIndex[0];
  PVector xy = new PVector(x, y);
  return xy;
}

int[] findIntersectionIndex(PVector cursorPosition) {
  int[] cornerIndex = {-1, -1};
  for (int i = 0; i < rowCount + 1; i++) {
    float cornerY = frameWidth / 2.0 + (monadSize + frameWidth) * i;
    float distanceY = abs(cornerY - cursorPosition.y);
    
    if (distanceY < cursorVelocity) {
      
      for (int j = 0; j < colCount + 1; j++) {
        float cornerX = frameWidth / 2.0 + (monadSize + frameWidth) * j;
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
