Stage stage;

Sprite player1;
Sprite player2;
ArrayList<Sprite> Missiles = new ArrayList<Sprite>();
float laserRange = 0;
float maxSpeed = 0;
float shipTurnSpeed = 7;
float shieldSize = 30;
String gamestate = "title";
String winner = "no winner";
int screenTimer = 3;
ArrayList<Sprite> planets = new ArrayList<Sprite>();
int numberOfPlanets = 0;
float friction = 1;
int quitTimer = -1;
boolean planetsAlsoMove = false;

static int rotationStyle_allAround=0;
static int rotationStyle_leftRight=1;
static int rotationStyle_dontRotate=2;
boolean[] keyIsDown = new boolean[256];
boolean[] arrowDown = new boolean[4];
static int upArrow=0;
static int downArrow=1;
static int leftArrow=2;
static int rightArrow=3;
boolean titleFlipped = false;
int screenSize = 0;
int gameOverTimer = -99;

void setup() {
  size(1800, 1000);
  screenSize = (height+width)/2;
  laserRange = (screenSize/10)*1.25;
  maxSpeed = screenSize/100;
  println("max speed is "+maxSpeed+" for screen size "+screenSize);

  frameRate(35);
  stage = new Stage(this);

  noFill();
  strokeWeight(3);

  stage.addBackdrop("images/spacewar bg.png");
  stage.addBackdrop("images/spacewar instructions.png");
  stage.addBackdrop("images/spacewar keys.png");
  stage.addBackdrop("images/spacewar tiles.png");
  stage.setBackdrop(1);

  player1 = new Sprite(this);
  player2 = new Sprite(this);
  player1.addCostume("images/player1ship.png");
  player2.addCostume("images/player2ship.png");
  player1.isRobot = true;

  initializePlayers();
  shieldSize = player1.size/2.5;
  
  player1.keyLaser = 'q';
  player1.keyEngines = 'w';
  player1.keyMissile ='e';
  player1.keyLeft = 'a';
  player1.keyCloak = 's';
  player1.keyRight = 'd';
  player1.keyShields = 'c';
  player1.keyHyperspace = 'x';
  player1.keyWeapon = 'z';
  player2.keyLaser = '7';
  player2.keyEngines = '8';
  player2.keyMissile ='9';
  player2.keyLeft = '4';
  player2.keyCloak = '5';
  player2.keyRight = '6';
  player2.keyShields = '3';
  player2.keyHyperspace = '2';
  player2.keyWeapon = '1';
}

void draw() {
  if (gamestate=="title") drawTitleScreen();
  if (gamestate=="playing" || gamestate=="demo") gameloop();
  if (gamestate=="gameover") drawGameOverScreen();
}

void gameloop() {
  if (gameOverTimer > 0) gameOverTimer--;
  if (gameOverTimer == 0) gamestate = "gameover";
  //stage.draw();
  stage.tile(3);

  movePlayer(player1);
  movePlayer(player2);
  checkForPlayerCollision();
  moveMissiles();
  if (numberOfPlanets > 0) drawPlanets();

  if (keyIsDown['0']) if (quitTimer<10) quitGame();

  drawLabels();
  coolDownWeapons();
  checkForWinner();

  //if (gamestate=="demo" && stage.timer() > 90) { winner = "Nobody"; endTheGame(); }
}

void quitGame() {
  if (quitTimer > 0) {
    player1.shieldEnergy = -1;
    player2.shieldEnergy = -1;
  } else { 
    quitTimer = 20;
  }
}

void initialize(Sprite player) {
  player.setCostume(0);
  player.rotationStyle = rotationStyle_allAround;
  player.direction = 0;
  player.size = screenSize/15;
  player.shieldEnergy = 25;
  player.weaponsEnergy = 100;
  player.xSpeed=0;
  player.ySpeed=0;
  if (gamestate == "playing" && player==player2) player.isRobot = false;
  if (gamestate == "demo") player.isRobot = true;
  if (player==player1) player.goToXY(20, 20);
  else player.goToXY(width-20, height-20);
}

void initializePlayers() {
  quitTimer = -1;
  for (int i=0; i<Missiles.size (); i++) {
    Missiles.remove(i);
    i--;
  }

  initialize(player1);
  initialize(player2);

  player1.pointToSprite(player2);
  player2.pointToSprite(player1);

  //if (numberOfPlanets > 0) spawnPlanets();
}

void gravity(Sprite player, Sprite planet) {
  float xMod = (0.00035*((width)-(player.distanceToSprite(planet))));
  float yMod = (0.00035*((height)-(player.distanceToSprite(planet))));
  if (player.pos.x > planet.pos.x) player.xSpeed -= ((xMod*xMod))*(planet.size/(100*numberOfPlanets-1));
  if (player.pos.x < planet.pos.x) player.xSpeed += ((xMod*xMod))*(planet.size/(100*numberOfPlanets-1));
  if (player.pos.y > planet.pos.y) player.ySpeed -= ((yMod*yMod))*(planet.size/(100*numberOfPlanets-1));
  if (player.pos.y < planet.pos.y) player.ySpeed += ((yMod*yMod))*(planet.size/(100*numberOfPlanets-1));
}

void removeAll(ArrayList list) {
  while (list.size () > 0)
    list.remove(0);
}

void spawnPlanets() {
  removeAll(planets);
  int maxPlanets = numberOfPlanets;
  float planetMargin = 0;
  for (int currentPlanet = 0; currentPlanet < maxPlanets; currentPlanet++) {
    planets.add(new Sprite(this));
    planets.get(currentPlanet).addCostume("images/planet.png");
    planets.get(currentPlanet).size = random(75, screenSize/5);
    planetMargin = 50+((planets.get(currentPlanet).costumes.get(0).width*(planets.get(currentPlanet).size/100))/2);
    planets.get(currentPlanet).goToXY(random(planetMargin, width-planetMargin), random(planetMargin, height-planetMargin));
    planets.get(currentPlanet).xSpeed = 0;
    planets.get(currentPlanet).ySpeed = 0;
  }
}

void drawPlanets() {
  for (int currentPlanet = 0; currentPlanet < planets.size (); currentPlanet++) {
    if (player1.visible) gravity(player1, planets.get(currentPlanet));
    if (player2.visible) gravity(player2, planets.get(currentPlanet));
    planets.get(currentPlanet).draw();
    if (planets.get(currentPlanet).touchingRoundSprite(player1)) { 
      hurtPlayer(player1, 10); 
      bouncePlayer(player1);
    }
    if (planets.get(currentPlanet).touchingRoundSprite(player2)) { 
      hurtPlayer(player2, 10); 
      bouncePlayer(player2);
    }
    // move plantoids by gravity too?? way too crazy.
    if (planetsAlsoMove) for (int p2 = 0; p2 < planets.size (); p2++) {
      if (currentPlanet != p2) gravity(planets.get(currentPlanet), planets.get(p2));
    }
    if (planetsAlsoMove) {
      planets.get(currentPlanet).pos.x += planets.get(currentPlanet).xSpeed/10;
      planets.get(currentPlanet).pos.y += planets.get(currentPlanet).ySpeed/10;
      planets.get(currentPlanet).wrapAtEdges();
    }
    for (int currentMissile = 0; currentMissile < Missiles.size (); currentMissile++) {
      gravity(Missiles.get(currentMissile), planets.get(currentPlanet));
    }
  }
}

/*
void gravity(Sprite player) {
 float xMod = (width)-(player.distanceToXY(width/2,height/2));
 float yMod = (height)-(player.distanceToXY(width/2,height/2));
 if (player.pos.x > width/2) player.xSpeed -= (0.00015*xMod);
 if (player.pos.x < width/2) player.xSpeed += (0.00015*xMod);
 if (player.pos.y > height/2) player.ySpeed -= (0.00015*yMod);
 if (player.pos.y < height/2) player.ySpeed += (0.00015*yMod);
 }
 */

void checkForWinner() {
  if (gameOverTimer == -99) {
    if (player1.shieldEnergy < 0 && player2.shieldEnergy < 0) {
      winner = "Nobody";
      endTheGame();
    } else if (player1.shieldEnergy < 0) {
      winner = "Player 2";
      if (gamestate=="playing") player2.winCount++;
      endTheGame();
    } else if (player2.shieldEnergy < 0) {
      winner = "Player 1";
      if (gamestate=="playing") player1.winCount++;
      endTheGame();
    }
  }
}

void endTheGame() {
  gameOverTimer = 25;
  screenTimer = 3;
  stage.resetTimer();
}

void fireEngines(Sprite player) {
  if (player.weaponsEnergy >= 1) {
    if (abs(player.xSpeed) < maxSpeed) player.xSpeed += player.vectorForSpeed(0.5).x;
    if (abs(player.ySpeed) < maxSpeed) player.ySpeed += player.vectorForSpeed(0.5).y;
    player.weaponsEnergy -= 0.05;
  }
}

void thinkFor1(Sprite player) {
  Sprite otherPlayer;

  if (player==player1) otherPlayer = player2; 
  else otherPlayer = player1;

  for (int currentPlanet = 0; currentPlanet < planets.size (); currentPlanet++) {
    if (player.distanceToSprite(planets.get(currentPlanet)) < 150) {
      player.pointToSprite(planets.get(currentPlanet));
      player.turn(180);
      fireEngines(player);
    }
  }
  if (player.shieldEnergy < 20 && player.weaponsEnergy > player.shieldEnergy) {
    chargeShields(player);
  } else if (player.distanceToSprite(otherPlayer) > 100 && player.weaponsEnergy < 20) {
    chargeWeapons(player);
  } else {
    if (player.distanceToSprite(otherPlayer) > 200) {
      player.pointToSprite(otherPlayer);
      fireEngines(player);
    }
    if (player.distanceToSprite(otherPlayer) < 200) {
      player.pointToSprite(otherPlayer);
      player.turn(random(-10, 10));
      fireMissile(player);
    }
    if (player.distanceToSprite(otherPlayer) < 100) {
      player.pointToSprite(otherPlayer);
      fireLasers(player);
    }
  }
}
void thinkFor3(Sprite player) {
  Sprite otherPlayer;

  if (player==player1) otherPlayer = player2; 
  else otherPlayer = player1;

  if (player.distanceToSprite(otherPlayer) > 10) {
    player.pointToSprite(otherPlayer);
    fireEngines(player);
  }
  if (player.distanceToSprite(otherPlayer) < laserRange) fireLasers(player);
  if (player.distanceToSprite(otherPlayer) < 300 ) fireMissile(player);
  for (int currentPlanet = 0; currentPlanet < planets.size (); currentPlanet++) {
    if (player.distanceToSprite(planets.get(currentPlanet)) < 250) {
      player.pointToSprite(planets.get(currentPlanet));
      player.turn(180);
      fireEngines(player);
    }
  }
  

}

void thinkFor2(Sprite player) {
  Sprite otherPlayer;

  if (player==player1) otherPlayer = player2; 
  else otherPlayer = player1;

  if (player.lastRoundHealth-player.shieldEnergy > 6) { 
    hyperSpace(player); 
    player.lastRoundHealth = player.shieldEnergy;
  }
  if (frameCount % 6 == 0) player.lastRoundHealth = player.shieldEnergy;

  for (int currentPlanet = 0; currentPlanet < planets.size (); currentPlanet++) {
    if (player.distanceToSprite(planets.get(currentPlanet)) < 150) {
      player.pointToSprite(planets.get(currentPlanet));
      player.turn(180);
      fireEngines(player);
    }
  }
  if (player.shieldEnergy < 20 && player.weaponsEnergy > player.shieldEnergy) {
    chargeShields(player);
  } else if (player.distanceToSprite(otherPlayer) > 50+(100-player.weaponsEnergy) && player.weaponsEnergy < 20+(player.distanceToSprite(otherPlayer)/50)) {
    if (otherPlayer.visible) { 
      player.pointToSprite(otherPlayer);
      player.turn(45);
    } else player.turn(15);
    if (random(0, 2) > 1) fireEngines(player);
    chargeWeapons(player);
  } else {
    // fire a barrage of missiles if close enough, but not too close
    if (otherPlayer.visible && player.distanceToSprite(otherPlayer) < 300 && player.distanceToSprite(otherPlayer) > 125) {
      player.pointToSprite(otherPlayer);
      player.turn(random(-10, 10));
      if (frameCount % 4 == 0) fireMissile(player);
    }
    // if too far away, try to close in
    if (otherPlayer.visible && player.distanceToSprite(otherPlayer) > 250) {
      player.pointToSprite(otherPlayer);
      fireEngines(player);
    }
    // try to keep out of laser range
    if (otherPlayer.visible && player.distanceToSprite(otherPlayer) < 200) {
      player.pointToSprite(otherPlayer);
      player.turn(180);
      fireEngines(player);
    }
    //if too close, fire lasers!
    if (otherPlayer.visible && player.distanceToSprite(otherPlayer) < 150) {
      fireLasers(player);
    }
    // try to shoot down incoming missiles
    for (int currentMissile = 0; currentMissile < Missiles.size (); currentMissile++) {
      if (Missiles.get(currentMissile).distanceToSprite(player) < 150 
        && Missiles.get(currentMissile).facingSprite(player)) {
        fireLasers(player);
      }
    }
  }
}

void movePlayer(Sprite player) {
  if (player.weaponsEnergy < 100) player.weaponsEnergy += 0.1;
  // do nothing if in hyperspace
  if (player.shieldEnergy < 0) {
    fill(shieldColor(random(0, 50)));
    noStroke();
    float splodeSize = random(10, 60);
    ellipse(player.pos.x+random(-10, 10), player.pos.y+random(-10, 10), splodeSize, splodeSize);
  } else
    if (player.hyperSpaceCooldown < 0) {
    player.hyperSpaceCooldown++;
    player.hide();
  } else 
    if (player.ghostEffect > 0) { 
    player.show(); 
    player.ghostEffect -= 4; 
    player.draw();
  } else {
    // show player & check keys
    player.show();
    if (player.isRobot) { 
      if (player == player1) thinkFor2(player);
      if (player == player2) thinkFor3(player);
    }
    else if (keyIsDown[player.keyShields]) { 
      if (player.weaponsEnergy >= 1) chargeShields(player);
    } else if (keyIsDown[player.keyWeapon]) chargeWeapons(player);
    else {
      if (keyIsDown[player.keyLeft]) player.turn(shipTurnSpeed);
      if (keyIsDown[player.keyRight]) player.turn(-shipTurnSpeed);
      if (keyIsDown[player.keyEngines]) if (player.weaponsEnergy >= 1) {
        player.xSpeed += player.vectorForSpeed(0.5).x;
        player.ySpeed += player.vectorForSpeed(0.5).y;
        player.weaponsEnergy -= 0.05;
        if (abs(player.speedForVector(player.xSpeed, player.ySpeed)) > maxSpeed) player.weaponsEnergy -= 0.1;
      }
      if (keyIsDown[player.keyCloak] && player.weaponsEnergy >= 1) { 
        player.hide(); 
        player.weaponsEnergy -= 0.05;
      } else player.show();
      if (keyIsDown[player.keyMissile]) if (player.weaponsEnergy >= 1) fireMissile(player);
      if (keyIsDown[player.keyLaser]) if (player.weaponsEnergy >= 1) fireLasers(player);
      if (keyIsDown[player.keyHyperspace]) if (player.weaponsEnergy >= 1) hyperSpace(player);
    }
    // update player position
    if (abs(player.speedForVector(player.xSpeed, player.ySpeed)) > maxSpeed) {
      player.xSpeed = player.xSpeed*0.98;
      player.ySpeed = player.ySpeed*0.98;
      player.draw(); // double draw trails?
    }
    player.xSpeed = player.xSpeed * friction;
    player.ySpeed = player.ySpeed * friction;
    player.pos.x += player.xSpeed;
    player.pos.y += player.ySpeed;
    player.wrapAtEdges();

    // draw player and always-on shields when low energy    
    player.draw();
    if (player.shieldEnergy < 40 && player.visible) {
      stroke(shieldColor(player.shieldEnergy));
      noFill();
      ellipse(player.pos.x, player.pos.y, shieldSize, shieldSize);
    }
  }
}
void movePlayer1() {
  // do nothing if in hyperspace
  if (player1.shieldEnergy < 0) {
    fill(shieldColor(random(0, 50)));
    noStroke();
    float splodeSize = random(10, 60);
    ellipse(player1.pos.x+random(-10, 10), player1.pos.y+random(-10, 10), splodeSize, splodeSize);
  } else
    if (player1.hyperSpaceCooldown < 0) {
    player1.hyperSpaceCooldown++;
    player1.hide();
  } else 
    if (player1.ghostEffect > 0) { 
    player1.show(); 
    player1.ghostEffect -= 4; 
    player1.draw();
  } else {
    // show player & check keys
    player1.show();
    if (player1.isRobot) thinkFor2(player1);
    else if (keyIsDown['c']) { 
      if (player1.weaponsEnergy >= 1) chargeShields(player1);
    } else if (keyIsDown['z']) chargeWeapons(player1);
    else {
      if (abs(player1.speedForVector(player1.xSpeed, player1.ySpeed)) > maxSpeed) {
        player1.xSpeed = player1.xSpeed*0.99;
        player1.ySpeed = player1.ySpeed*0.99;
      }
      if (keyIsDown['a']) player1.turn(shipTurnSpeed);
      if (keyIsDown['d']) player1.turn(-shipTurnSpeed);
      if (keyIsDown['w']) if (player1.weaponsEnergy >= 1) {
        player1.xSpeed += player1.vectorForSpeed(0.5).x;
        player1.ySpeed += player1.vectorForSpeed(0.5).y;
        player1.weaponsEnergy -= 0.05;
      }
      if (keyIsDown['s'] && player1.weaponsEnergy >= 1) { 
        player1.hide(); 
        player1.weaponsEnergy -= 0.05;
      } else player1.show();
      if (keyIsDown['e']) if (player1.weaponsEnergy >= 1) fireMissile(player1);
      if (keyIsDown['q']) if (player1.weaponsEnergy >= 1) fireLasers(player1);
      if (keyIsDown['x']) if (player1.weaponsEnergy >= 1) hyperSpace(player1);
    }
    // update player position
    player1.xSpeed = player1.xSpeed * friction;
    player1.ySpeed = player1.ySpeed * friction;
    player1.pos.x += player1.xSpeed;
    player1.pos.y += player1.ySpeed;
    player1.wrapAtEdges();

    // draw player and always-on shields when low energy    
    player1.draw();
    if (player1.shieldEnergy < 40 && player1.visible) {
      stroke(shieldColor(player1.shieldEnergy));
      ellipse(player1.pos.x, player1.pos.y, shieldSize, shieldSize);
    }
  }
}

void movePlayer2() {
  if (player2.shieldEnergy < 0) {
    fill(shieldColor(random(0, 50)));
    noStroke();
    float splodeSize = random(20, 50);
    ellipse(player2.pos.x+random(-10, 10), player2.pos.y+random(-10, 10), splodeSize, splodeSize);
  } else
    if (player2.hyperSpaceCooldown < 0) {
    player2.hyperSpaceCooldown++;
    player2.hide();
  } else 
    if (player2.ghostEffect > 0) { 
    player2.show(); 
    player2.ghostEffect -= 4; 
    player2.draw();
  } else {
    if (player2.isRobot) { 
      player2.show(); 
      thinkFor1(player2);
    } else if (keyIsDown['3']) { 
      if (player2.weaponsEnergy >= 1) chargeShields(player2);
    } else if (keyIsDown['1']) chargeWeapons(player2);
    else {
      if (keyIsDown['4']) player2.turn(shipTurnSpeed);
      if (keyIsDown['6']) player2.turn(-shipTurnSpeed);
      if (keyIsDown['8']) if (player2.weaponsEnergy >= 1) {
        player2.xSpeed += player2.vectorForSpeed(0.5).x;
        player2.ySpeed += player2.vectorForSpeed(0.5).y;
        if (player2.speedForVector(player2.xSpeed, player2.ySpeed) > maxSpeed) {
          player2.xSpeed *= 0.99;
          player2.ySpeed *= 0.99;
        }
        player2.weaponsEnergy -= 0.05;
      }
      if (keyIsDown['5'] && player2.weaponsEnergy >= 1) { 
        player2.hide(); 
        player2.weaponsEnergy -= 0.05;
      } else player2.show();
      if (keyIsDown['9']) if (player2.weaponsEnergy >= 1) fireMissile(player2);
      if (keyIsDown['7']) if (player2.weaponsEnergy >= 1) fireLasers(player2);
      if (keyIsDown['2']) if (player2.weaponsEnergy >= 1) hyperSpace(player2);
    }
    player2.xSpeed = player2.xSpeed * friction;
    player2.ySpeed = player2.ySpeed * friction;
    player2.pos.x += player2.xSpeed;
    player2.pos.y += player2.ySpeed;

    player2.wrapAtEdges();
    player2.draw();
    if (player2.shieldEnergy < 40 && player2.visible) {
      stroke(shieldColor(player2.shieldEnergy));
      ellipse(player2.pos.x, player2.pos.y, shieldSize, shieldSize);
    }
  }
}

void chargeShields(Sprite player) {
  if (player.shieldEnergy < 100) {
    player.shieldEnergy += 1; //0.1;
    player.weaponsEnergy -= 1; // 0.25;
  }
}

void chargeWeapons(Sprite player) {
  /*int planetModifier = 1;
  float weaponsCharge = 0.05;
  if (player.weaponsEnergy < 10) weaponsCharge = 2;
  if (numberOfPlanets > 0) planetModifier = planets.size()/2;
  if (player.weaponsEnergy < 100) player.weaponsEnergy += weaponsCharge*(planetModifier);
  */
  if (player.weaponsEnergy < 100 && player.shieldEnergy > 1) {
    player.weaponsEnergy += 1;
    player.shieldEnergy -= 1;
  }
}

void checkForPlayerCollision() {
  if (player1.distanceToSprite(player2) < 40 && player1.visible && player2.visible ) {
    float avgX = (player1.xSpeed + player2.xSpeed) / 2;
    float avgY = (player1.ySpeed + player2.ySpeed) / 2;
    float p1x = player1.xSpeed;
    float p1y = player1.xSpeed;
    float p2x = player2.ySpeed;
    float p2y = player2.ySpeed;
    float p1d = player1.direction;
    float p2d = player2.direction;
    player1.xSpeed = p2x;
    player1.ySpeed = p2y;
    player2.xSpeed = p1x;
    player2.ySpeed = p1y;
    player1.direction = p2d;
    player2.direction = p1d;
    player1.pos.x += player1.xSpeed;
    player1.pos.y += player1.ySpeed;
    player2.pos.x += player2.xSpeed;
    player2.pos.y += player2.ySpeed;
  }
}

void bouncePlayer(Sprite player) {
  player.xSpeed *= -1;
  player.ySpeed *= -1;
  player.direction = player.directionForSpeed(player.xSpeed, player.ySpeed);
}

void hyperSpace(Sprite player) {
  if (player.hyperSpaceCooldown == 0) {
    player.hide();
    boolean touchingPlanet = true;
    while (touchingPlanet == true) {
      touchingPlanet = false;
      player.pos.x = random(0, width);
      player.pos.y = random(0, height);
      for (int currentPlanet = 0; currentPlanet < planets.size (); currentPlanet++) {
        if (player.distanceToSprite(planets.get(currentPlanet)) < 100) touchingPlanet = true;
      }
    }
    player.xSpeed = 0;
    player.ySpeed = 0;
    player.weaponsEnergy -= 8;
    player.hyperSpaceCooldown = -25;
    player.ghostEffect = 100;
  }
}

void fireMissile(Sprite player) {
  if (player.missileTimeout < 1) {
    player.missileTimeout = 4;
    player.weaponsEnergy -= 1;

    int newMissile = Missiles.size();
    Missiles.add(new Sprite(this));
    Missiles.get(newMissile).addCostume("images/missile.png");
    Missiles.get(newMissile).size = 50+(screenSize/20);
    Missiles.get(newMissile).direction = player.direction;
    Missiles.get(newMissile).pos.x = player.pos.x;
    Missiles.get(newMissile).pos.y = player.pos.y;
    while (Missiles.get (newMissile).touchingRoundSprite(player))
      Missiles.get(newMissile).move(5);
    Missiles.get(newMissile).xSpeed = Missiles.get(newMissile).vectorForSpeed(10).x+player.xSpeed/2;
    Missiles.get(newMissile).ySpeed = Missiles.get(newMissile).vectorForSpeed(10).y+player.ySpeed/2;
    Missiles.get(newMissile).rotationStyle = rotationStyle_allAround;
  }
}

void fireLasers(Sprite player) {
  Sprite otherPlayer = new Sprite(this);
  strokeWeight(3);
  stroke(#ffff00);
  int missilesHit = 0;
  if (player.laserTimeout < 1) {
    if (player == player1) otherPlayer = player2;
    if (player == player2) otherPlayer = player1;
    player.laserTimeout = 4;
    for (int currentMissile = 0; currentMissile < Missiles.size (); currentMissile++) {
      if (player.distanceToSprite(Missiles.get(currentMissile)) < laserRange-50 && 
        missilesHit < 1 &&
        player.withinSightRange(Missiles.get(currentMissile), 90)) {
        line(player.pos.x, player.pos.y, Missiles.get(currentMissile).pos.x, Missiles.get(currentMissile).pos.y);
        missilesHit++;
        player.weaponsEnergy -= 1;
        Missiles.remove(currentMissile);
        currentMissile--;
      }
    }
    if (otherPlayer.visible 
      && player.distanceToSprite(otherPlayer) < laserRange 
      && missilesHit == 0 
      && player.withinSightRange(otherPlayer, 90) ) {
      line(player.pos.x, player.pos.y, otherPlayer.pos.x, otherPlayer.pos.y);
      player.weaponsEnergy -= 1;
      hurtPlayer(otherPlayer, 2);
    }
  }
}

void coolDownWeapons() {
  if (player1.missileTimeout > 0) player1.missileTimeout--;
  if (player2.missileTimeout > 0) player2.missileTimeout--;
  if (player1.laserTimeout > 0) player1.laserTimeout--;
  if (player2.laserTimeout > 0) player2.laserTimeout--;
  if (player1.hyperSpaceCooldown > 0) player1.hyperSpaceCooldown--;
  if (player2.hyperSpaceCooldown > 0) player2.hyperSpaceCooldown--;
  if (frameCount % 100 == 0) {
    if (player1.weaponsEnergy < 100) player1.weaponsEnergy++;
    if (player2.weaponsEnergy < 100) player2.weaponsEnergy++;
  }
}

void hurtPlayer(Sprite player, int damage) {
  player.shieldEnergy -= 4;
  stroke(shieldColor(player.shieldEnergy));
  noFill();
  ellipse(player.pos.x, player.pos.y, shieldSize, shieldSize);
}

void moveMissiles() {
  for (int currentMissile = 0; currentMissile < Missiles.size (); currentMissile++) {
    boolean removeThis = false;
    float oldX, oldY;
    oldX = Missiles.get(currentMissile).pos.x;
    oldY = Missiles.get(currentMissile).pos.y;
    Missiles.get(currentMissile).pos.x += Missiles.get(currentMissile).xSpeed;
    Missiles.get(currentMissile).pos.y += Missiles.get(currentMissile).ySpeed;
    Missiles.get(currentMissile).wrapAtEdges();
    Missiles.get(currentMissile).ghostEffect += 0.25; 
    if (Missiles.get(currentMissile).ghostEffect > 25) removeThis = true;
    if (Missiles.get(currentMissile).pos.x > width
      || Missiles.get(currentMissile).pos.x < 0
      || Missiles.get(currentMissile).pos.y > height 
      || Missiles.get(currentMissile).pos.y < 0) removeThis = true;
    // home in?
    /* this requires "speedForVector" which is incomplete
     if (Missiles.get(currentMissile).distanceToSprite(player1) < 50) {
     float speed = Missiles.get(currentMissile).speedForVector(Missiles.get(currentMissile).xSpeed,Missiles.get(currentMissile).ySpeed);
     Missiles.get(currentMissile).direction = (Missiles.get(currentMissile).direction+Missiles.get(currentMissile).directionToSprite(player1))/2;
     Missiles.get(currentMissile).xSpeed = Missiles.get(currentMissile).vectorForSpeed(speed).x;
     Missiles.get(currentMissile).ySpeed = Missiles.get(currentMissile).vectorForSpeed(speed).y;
     }
     */
    for (int currentPlanet = 0; currentPlanet < planets.size (); currentPlanet++) {
      if (Missiles.get(currentMissile).touchingRoundSprite(planets.get(currentPlanet))) {
        removeThis = true;
        planets.get(currentPlanet).ghostEffect += 3;
        if (planets.get(currentPlanet).ghostEffect > 80) {
          planets.remove(currentPlanet);
          currentPlanet--;
        }
      }
    }
    if (Missiles.get(currentMissile).touchingRoundSprite(player1)) {
      removeThis = true;
      hurtPlayer(player1, 4);
    }
    if (Missiles.get(currentMissile).touchingRoundSprite(player2)) {
      removeThis = true;
      hurtPlayer(player2, 4);
    }
    if (removeThis) {
      Missiles.remove(currentMissile);
      currentMissile--;
    } else Missiles.get(currentMissile).draw();
  }
}

void drawLabels() {
  pushStyle();
  if (gamestate=="playing" || gamestate=="demo") {
    textSize(16);
    fill(200);
    text("W", 10, height-40);
    text("S", 10, height-20);
    text("W", width-20, height-40);
    text("S", width-20, height-20);
    stroke(shieldColor(player1.weaponsEnergy));
    line (30, height-45, 30+player1.weaponsEnergy, height-45);
    stroke(shieldColor(player1.shieldEnergy));
    line (30, height-25, 30+player1.shieldEnergy, height-25);
    stroke(shieldColor(player2.weaponsEnergy));
    line (width-30, height-45, width-30-player2.weaponsEnergy, height-45);
    stroke(shieldColor(player2.shieldEnergy));
    line (width-30, height-25, width-30-player2.shieldEnergy, height-25);
    if (gamestate == "demo") {
      textAlign(CENTER);
      text("Press 0 to exit Demo Mode",width/2,height-10);
    }
    if (quitTimer > 0) {
      quitTimer--;
      textSize(20);
      fill(255);
      textAlign(CENTER);
      text("Press 0 again to return to title.", width/2, height/2);
    }
  }
  if (gamestate=="title" || gamestate=="gameover") {
    textSize(16);
    fill(255);
    int players = 0;
    if (player1.isRobot) players = 1; 
    else players = 2;
    text("P1 Wins: "+player1.winCount, 10, height-10);
    text("P2 Wins: "+player2.winCount, width-100, height-10);
    text("Players: "+players, 10, 20);
    if (planetsAlsoMove) text("Moving Planets: "+numberOfPlanets, width-161, 20);
    else text("Planets: "+numberOfPlanets, width-100, 20);
  }
  popStyle();
}

void togglePlayerNumber() {
  if (player1.isRobot == false) player1.isRobot = true; 
  else player1.isRobot = false;
  screenTimer = 3;
}

void toggleMovingPlanets() {
  if (planetsAlsoMove == false) planetsAlsoMove = true; 
  else planetsAlsoMove = false;
  screenTimer = 3;
}

void resetPlanets(int newMax) {
  numberOfPlanets = newMax;
  spawnPlanets();
  screenTimer = 2;
}

void drawTitleScreen() {
  if (screenTimer > 0) screenTimer--; 
  else {
    if (keyIsDown['0']) resetPlanets(0);
    if (keyIsDown['1']) resetPlanets(1);
    if (keyIsDown['2']) resetPlanets(2);
    if (keyIsDown['3']) resetPlanets(3);
    if (keyIsDown['4']) resetPlanets(4);
    if (keyIsDown['5']) resetPlanets(5);
    if (keyIsDown['6']) resetPlanets(6);
    if (keyIsDown['7']) resetPlanets(7);
    if (keyIsDown['8']) resetPlanets(8);
    if (keyIsDown['9']) resetPlanets(9);

    if (keyIsDown[' ']) startTheGame();
    if (keyIsDown['d']) startDemoMode();
    if (keyIsDown['p']) togglePlayerNumber();
    if (keyIsDown['m']) toggleMovingPlanets();
  }
  if (stage.timer() % 5 == 0) {
    if (!titleFlipped) {
      titleFlipped = true;
      if (stage.backdropNumber==2) stage.setBackdrop(1); 
      else stage.setBackdrop(2);
    }    
    if (stage.timer() > 30) { 
      startDemoMode(); 
      stage.resetTimer();
    }
  }
  if (stage.timer() % 5 == 1) titleFlipped = false;
  stage.tile(3);
  stage.draw();
  if (numberOfPlanets > 0) drawPlanets();
  drawLabels();
}

void startDemoMode() {
  gamestate = "demo"; 
  winner = "Nobody";
  initializePlayers();
  gameOverTimer = -99;
  player1.isRobot = true;
  player2.isRobot = true;
  if (random(0, 4) > 3) planetsAlsoMove = true; 
  else planetsAlsoMove = false;
  resetPlanets((int)random(1, 9)); 
  stage.setBackdrop(0);
}

void startTheGame() {
  gamestate = "playing"; 
  gameOverTimer = -99;
  winner = "Nobody";
  stage.setBackdrop(0);
  initializePlayers();
}

void drawGameOverScreen() {
  stage.tile(3);
  stage.draw();
  drawLabels();
  fill(255);
  textSize(32);
  text(""+winner+" wins!", (width/2)-125, height/2);
  if (stage.timer() > 1) {
    if (keyIsDown[' ']) returnToTitle();
    if (stage.timer() > 5) returnToTitle();
  }
}

void returnToTitle() {
  stage.setBackdrop(1); 
  stage.draw(); 
  gamestate = "title"; 
  initializePlayers();
  screenTimer = 3;
  stage.resetTimer();
}

color shieldColor(float power) {
  if (power>80) return #00FF00;
  if (power>70) return #44FF00;
  if (power>60) return #88FF00;
  if (power>50) return #bbFF00;
  if (power>40) return #FFFF00;
  if (power>30) return #FFbb00;
  if (power>20) return #FF8800;
  if (power>10) return #FF4400;
  if (power>00) return #FF0000;
  return #000000;
}

void keyPressed() {
  if (key<256) {
    keyIsDown[key] = true;
  }
  if (key==CODED) {
    //cat.nextCostume();
    switch (keyCode) {
    case UP: 
      arrowDown[upArrow]=true; 
      break;
    case DOWN: 
      arrowDown[downArrow]=true; 
      break;
    case LEFT: 
      arrowDown[leftArrow]=true;  
      break;
    case RIGHT: 
      arrowDown[rightArrow]=true; 
      break;
    }
  }
}

void keyReleased() {
  if (key<256) {
    keyIsDown[key] = false;
  }
  if (key==CODED) {
    switch (keyCode) {
    case UP: 
      arrowDown[upArrow]=false; 
      break;
    case DOWN: 
      arrowDown[downArrow]=false; 
      break;
    case LEFT: 
      arrowDown[leftArrow]=false;  
      break;
    case RIGHT: 
      arrowDown[rightArrow]=false; 
      break;
    }
  }
}

