int rowCount = 5;
int colCount = 5;

int scaleFactor = 2;
int monadWidth = 40 * scaleFactor;
int monadHeight = 40 * scaleFactor;
int frameWidth = 5 * scaleFactor;
int cursorSize = 10;
int cursorVelocity = 4;

String monadKeys = "abcdefghijklmnopqrstuvwxy";
int monadCount = monadKeys.length();
StringList activatedMonadKey = new StringList();
boolean[] activatedMonad = new boolean[monadCount];

Monad[] monads = new Monad[monadCount];

void setup() {
  size(460, 460, P3D);
  for (int i = 0; i < rowCount; i++) {
    for (int j = 0; j < colCount; j++) {
      int monadIndex = i * rowCount + j;
      int x = frameWidth * (j + 1) + monadWidth * j + monadWidth / 2;
      int y = frameWidth * (i + 1) + monadHeight * i + monadHeight / 2;
      PVector position = new PVector(float(x), float(y));
      monads[monadIndex] = new Monad(position, monadIndex);
    }
  }
}

void draw() {
  background(0);
  for (Monad monad : monads) {
    monad.checkActivate();
    monad.display();
    monad.createCursor();
  }
}

class Monad {
  
  PVector position;
  int monadIndex;
  Boolean isActivated;
  String monadKey;
  PVector[] cursorPositions = new PVector[monadCount - 1];
  
  Monad(PVector positionInput, int monadIndexInput) {
    position = positionInput;
    monadIndex = monadIndexInput;
    isActivated = false;
    monadKey = str(monadKeys.charAt(monadIndex));
    for (int i = 0; i < monadCount - 1; i++) {
      cursorPositions[i] = new PVector(position.x, position.y);
    }
  }
  
  void checkActivate() {
    isActivated = activatedMonad[monadIndex];
  }
  
  void createCursor() {
    int cursorCount = countActivatedMonad() - 1;
    if (isActivated && cursorCount >= 1) {
      for (int i = 0; i < cursorCount + 1; i++) {
        String targetMonadKey = activatedMonadKey.get(i);
        if (!targetMonadKey.equals(monadKey)) {
          int targetMonadIndex = monadKeys.indexOf(targetMonadKey);
          if (targetMonadIndex >= 0) {
            PVector targetPosition = convertCoordinate(targetMonadIndex);
            PVector direction = PVector.sub(targetPosition, position).normalize();
            PVector currentCursorPosition = cursorPositions[targetMonadIndex];
            PVector updateCursorPosition = PVector.add(currentCursorPosition, direction.mult(1));
            float distance = PVector.sub(targetPosition, updateCursorPosition).mag();
            if (distance > 5.0) {
              cursorPositions[targetMonadIndex] = updateCursorPosition;
            }
            strokeWeight(2);
            line(position.x, position.y, updateCursorPosition.x, updateCursorPosition.y);
          }
        }
      }
    } else {
      for (int i = 0; i < monadCount - 1; i++) {
        cursorPositions[i] = new PVector(position.x, position.y);
      }
    }
  }
  
  void display() {
    if (isActivated) {
      fill(255, 0, 0);
    } else {
      fill(0, 0, 0);
    }
    stroke(255);
    strokeWeight(1);
    rect(position.x - monadWidth / 2, position.y - monadHeight / 2, monadWidth, monadHeight);
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

int countActivatedMonad() {
  int count = 0;
  for (int i = 0; i < monadCount; i++) {
    if (activatedMonad[i]) {
      count += 1;
    }
  }
  return count;
}

int findIndex(String keyString, StringList targetList) {
  for (int i = 0; i < targetList.size(); i++) {
    if (targetList.get(i).equals(keyString)) {
      return i;
    }
  }
  return -1;
}

PVector convertCoordinate(int index) {
  int j = index % rowCount;
  int i = index / rowCount;
  int x = frameWidth * (j + 1) + monadWidth * j + monadWidth / 2;
  int y = frameWidth * (i + 1) + monadHeight * i + monadHeight / 2;
  PVector xy = new PVector(float(x), float(y));
  return xy;
}
