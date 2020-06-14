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

int cursorMemory = 100;
float cursorVelocity = 30.0;
int[][][] cornerDirections = new int[rowCount + 1][colCount + 1][4];

void setup() {
  size(460, 460);
  background(0);
  frameRate(30);
  
  // init monad
  for (int i = 0; i < rowCount; i++) {
    for (int j = 0; j < colCount; j++) {
      int id = i * rowCount + j;
      int x = frameWidth * (j + 1) + monadSize * j + monadSize / 2;
      int y = frameWidth * (i + 1) + monadSize * i + monadSize / 2;
      PVector position = new PVector(float(x), float(y));
      monads[id] = new Monad(id, position);
    }
  }
  
  // init cursor direction
  for (int i = 0; i < rowCount + 1; i++) {
    for (int j = 0; j < colCount + 1; j++) {
      StringList directionList = new StringList("u", "l", "d", "r");
      if (i == 0) {
        int upIndex = findIndex("u", directionList);
        directionList.remove(upIndex);
      } else if (i == rowCount) {
        int downIndex = findIndex("d", directionList);
        directionList.remove(downIndex);
      }
  
      if (j == 0) {
        int leftIndex = findIndex("l", directionList);
        directionList.remove(leftIndex);
      } else if (j == colCount) {
        int rightIndex = findIndex("r", directionList);
        directionList.remove(rightIndex);
      }
  
      for (int k = 0; k < directionList.size(); k++) {
        if (directionList.get(k).equals("u")) {
          cornerDirections[i][j][k] = 1;
        } else if (directionList.get(k).equals("l")) {
          cornerDirections[i][j][k] = 2;
        } else if (directionList.get(k).equals("d")) {
          cornerDirections[i][j][k] = 3;
        } else {
          cornerDirections[i][j][k] = 4;
        }
      }
    }
  }
}

void draw() {
  fill(0, 6);
  noStroke();
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

  int[] cursorDirections = new int[monadCount];
  float[][][] cursorHistory = new float[monadCount][cursorMemory][2];
  PVector[] cursorPositions = new PVector[monadCount];
  //PVector[] initialCursorPositions = new PVector[monadCount];
  int[] verticalDirections = {1, 3};
  int[] horizontalDirections = {2, 4};

  Monad(int idInput, PVector positionInput) {
    position = positionInput;
    id = idInput;
    isActivated = false;
    wasActivated = false;
    monadKey = str(monadKeys.charAt(id));
  }

  void checkActivate() {
    wasActivated = isActivated;
    isActivated = activatedMonad[id];
  }

  void displayMonad() {
    if (isActivated) {
      fill(255, 0, 0, 20);
    } else {
      fill(0, 0, 0);
    }
    stroke(255);
    strokeWeight(1);
    rect(position.x - monadSize / 2, position.y - monadSize / 2, monadSize, monadSize);
  }

  void displayCursor() {
    if (isActivated) {
      int cursorCount = countActivatedMonad() - 1;
      if (cursorCount >= 1) {
        for (int i = 0; i < monadCount; i++) {
          if (!wasActivated) {
            initializeCursor(i);
          }
          if (i != id && activatedMonad[i]) {
            PVector targetPosition = convertPosition(i);
            line(cursorHistory[i][cursorMemory - 1][0], cursorHistory[i][cursorMemory - 1][1], cursorHistory[i][cursorMemory - 2][0], cursorHistory[i][cursorMemory - 2][1]);
            float distance = PVector.dist(targetPosition, cursorPositions[i]);
            if (distance >= monadSize / 2.0 + frameWidth) {
              displayConnection(i);
            } else {
              
              //draw history
              stroke(255, 0, 0);
              strokeWeight(2);
              float[] lastCursor = new float[2];
              for (int j = 0; j < cursorMemory - 1; j ++) {
                
                float[] currentCursor = cursorHistory[i][j];
                float[] nextCursor = cursorHistory[i][j + 1];
                
                if (currentCursor[0] > 0.0 && currentCursor[1] > 0.0 && nextCursor[0] > 0.0 && nextCursor[1] > 0.0) {
                  
                  line(currentCursor[0], currentCursor[1], nextCursor[0], nextCursor[1]);
                }
                lastCursor = nextCursor;
              }
              float lastX = (targetPosition.x - lastCursor[0]) * frameWidth / float(monadSize + frameWidth) + lastCursor[0];
              float lastY = (targetPosition.y - lastCursor[1]) * frameWidth / float(monadSize + frameWidth) + lastCursor[1];
              
              line(lastCursor[0], lastCursor[1], lastX, lastY);
              
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
  
  void displayConnection(int i) {
    
    PVector currentCursorPosition = cursorPositions[i];
    float updateX = currentCursorPosition.x;
    float updateY = currentCursorPosition.y;
    if (cursorDirections[i] == 1) {
      updateY -= cursorVelocity;
    } else if (cursorDirections[i] == 2) {
      updateX -= cursorVelocity;
    } else if (cursorDirections[i] == 3) {
      updateY += cursorVelocity;
    } else {
      updateX += cursorVelocity;
    }
    PVector nextCursorPosition = new PVector(updateX, updateY);
    int[] cornerIndex = convertConerIndex(nextCursorPosition);
    int cornerRow = cornerIndex[0];
    int cornerCol = cornerIndex[1];
    if (cornerRow >= 0 && cornerCol >= 0) {
      nextCursorPosition = convertCornerPosition(cornerIndex);
      IntList candidateList = new IntList();
      for (int k = 0; k < 4; k++) {
        int possibleDirection = cornerDirections[cornerRow][cornerCol][k];
        if (possibleDirection > 0 && possibleDirection != (cursorDirections[i] + 1) % 4 + 1) {
          PVector targetPosition = convertPosition(i);
          
          if (possibleDirection == 1 && targetPosition.y < nextCursorPosition.y) {
            candidateList.append(possibleDirection);
          }
          if (possibleDirection == 2 && targetPosition.x < nextCursorPosition.x) {
            candidateList.append(possibleDirection);
          }
          if (possibleDirection == 3 && targetPosition.y >= nextCursorPosition.y) {
            candidateList.append(possibleDirection);
          }
          if (possibleDirection == 4 && targetPosition.x >= nextCursorPosition.x) {
            candidateList.append(possibleDirection);
          } 
        }
      }
      int[] candidates = candidateList.array();
      cursorDirections[i] = candidates[int(random(candidateList.size()))];
    }
    strokeWeight(2);
    stroke(255, 128, 128);
    line(currentCursorPosition.x, currentCursorPosition.y, nextCursorPosition.x, nextCursorPosition.y);
    cursorPositions[i] = nextCursorPosition;
    
    for (int j = 1; j < cursorMemory; j++) {
      cursorHistory[i][j - 1][0] = cursorHistory[i][j][0];
      cursorHistory[i][j - 1][1] = cursorHistory[i][j][1];
    }
    cursorHistory[i][cursorMemory - 1][0] = nextCursorPosition.x;
    cursorHistory[i][cursorMemory - 1][1] = nextCursorPosition.y;
  }

  void initializeCursor(int targetMonadIndex) {
    int randomPosition = int(random(1, 5));
    int randomDirection = int(random(2));
    int directionIndex;
    float x = position.x;
    float y = position.y;
    float xSecond = position.x;
    float ySecond = position.y;
    if (randomPosition == 1) {
      y -= monadSize / 2.0;
      ySecond -= (monadSize + frameWidth) / 2.0;
      directionIndex = horizontalDirections[randomDirection];
    } else if (randomPosition == 2) {
      x -= monadSize / 2.0;
      xSecond -= (monadSize + frameWidth) / 2.0;
      directionIndex = verticalDirections[randomDirection];
    } else if (randomPosition == 3) {
      y += monadSize / 2.0;
      ySecond += (monadSize + frameWidth) / 2.0;
      directionIndex = horizontalDirections[randomDirection];
    } else {
      x += monadSize / 2.0;
      xSecond += (monadSize + frameWidth) / 2.0;
      directionIndex = verticalDirections[randomDirection];
    }
    //initialCursorPositions[targetMonadIndex] = new PVector(x, y);
    cursorPositions[targetMonadIndex] = new PVector(xSecond, ySecond);
    cursorDirections[targetMonadIndex] = directionIndex;
              
    cursorHistory[targetMonadIndex] = new float[cursorMemory][2];
    
    cursorHistory[targetMonadIndex][cursorMemory - 2][0] = x;
    cursorHistory[targetMonadIndex][cursorMemory - 2][1] = y;
    
    cursorHistory[targetMonadIndex][cursorMemory - 1][0] = xSecond;
    cursorHistory[targetMonadIndex][cursorMemory - 1][1] = ySecond;
    
  }
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

int findIndex(String keyString, StringList targetList) {
  for (int i = 0; i < targetList.size(); i++) {
    if (targetList.get(i).equals(keyString)) {
      return i;
    }
  }
  return -1;
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

int[] convertConerIndex(PVector cursorPosition) {
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

PVector convertCornerPosition(int[] cornerIndex) {
  float x = frameWidth / 2.0 + (monadSize + frameWidth) * cornerIndex[1];
  float y = frameWidth / 2.0 + (monadSize + frameWidth) * cornerIndex[0];
  PVector xy = new PVector(x, y);
  return xy;
}
