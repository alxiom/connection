void setup() {
  size(640, 480);
  background(0);
}

void draw() {
  line(120, 240, 520, 240);
  strokeWeight(5);
  strokeCap(ROUND);
  stroke(255, 0, 0);
  filter(BLUR, 1);
  
  line(120, 240, 520, 240);
  strokeWeight(5);
  strokeCap(ROUND);
  stroke(255, 100, 50);
}
