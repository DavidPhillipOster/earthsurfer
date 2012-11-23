// surfer1.js
/*
Copyright 2008 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Code from Monster Milktruck demo, using Earth Plugin.

window.truck = null;

// Pull the models from the earthsurfer website.
var MODEL_URL0 = 'http://earthsurfer.googlecode.com/svn/html/data/silvertoy_new.kmz';
var MODEL_URL1 = 'http://earthsurfer.googlecode.com/svn/html/data/sub.kmz';


var TICK_MS = 66;


var STEER_ROLL = -1.0;
var ROLL_SPRING = 0.5;
var ROLL_DAMP = -0.16;
var xLevel;
var yLevel;

// Surfer can slightly float this much above the ground and still
// steer.  This makes snowboarding more fun.
var GROUND_SLOP = 1.0;

function Truck() {
  var me = this;

  me.doTick = true;

  // We do all our motion relative to a local coordinate frame that is
  // anchored not too far from us.  In this frame, the x axis points
  // east, the y axis points north, and the z axis points straight up
  // towards the sky.
  //
  // We periodically change the anchor point of this frame and
  // recompute the local coordinates.
  me.localAnchorLla = [0, 0, 0];
  me.localAnchorCartesian = V3.latLonAltToCartesian(me.localAnchorLla);
  me.localFrame = M33.identity();

  // Position, in local cartesian coords.
  me.pos = [0, 0, 0];

  // Velocity, in local cartesian coords.
  me.vel = [0, 0, 0];

  // Orientation matrix, transforming model-relative coords into local
  // coords.
  me.modelFrame = M33.identity();

  me.subMode = false;

  me.roll = 0;
  me.rollSpeed = 0;

  me.idleTimer = 0;
  me.fastTimer = 0;
  me.popupTimer = 0;

  // Used after teleports.
  me.pinToGroundTimer = 0;

  ge.getOptions().setFlyToSpeed(100);  // don't filter camera motion

  window.google.earth.fetchKml(ge, MODEL_URL0,
                               function(obj) { me.finishInit0(obj); });
  window.google.earth.fetchKml(ge, MODEL_URL1,
                               function(obj) { window.setTimeout(function() { me.finishInit1(obj); }, 0); });//xxxxxxx
}

Truck.prototype.finishInit0 = function(kml) {
  var me = this;

  // The model zip file is actually a kmz, containing a KmlFolder with
  // a camera KmlPlacemark (we don't care) and a model KmlPlacemark
  // (our milktruck).
  me.placemark = kml.getFeatures().getChildNodes().item(1);
  me.model_surfer = me.placemark.getGeometry();
  me.model = me.model_surfer;
  me.orientation = me.model.getOrientation();
  //me.location = me.model.getLocation();

  me.model.setAltitudeMode(ge.ALTITUDE_ABSOLUTE);
  me.orientation.setHeading(90);
  me.model.setOrientation(me.orientation);

  ge.getFeatures().appendChild(me.placemark);

  me.balloon = ge.createHtmlStringBalloon('');
  me.balloon.setFeature(me.placemark);
  me.balloon.setMaxWidth(200);

  me.teleportTo(19.912811, -155.892137, 180);  // Hawaii

  me.lastMillis = (new Date()).getTime();

  var href = window.location.href;
  var pagePath = href.substring(0, href.lastIndexOf('/')) + '/';

  me.shadow = ge.createGroundOverlay('');
  me.shadow.setVisibility(false);
  me.shadow.setIcon(ge.createIcon(''));
  me.shadow.setLatLonBox(ge.createLatLonBox(''));
  me.shadow.setAltitudeMode(ge.ALTITUDE_CLAMP_TO_SEA_FLOOR);
  me.shadow.getIcon().setHref(pagePath + 'images/shadowrect1.png');
  me.shadow.setVisibility(true);
  ge.getFeatures().appendChild(me.shadow);

  google.earth.addEventListener(ge, "frameend", function() { me.tick(); });

  me.cameraCut();
}

Truck.prototype.finishInit1 = function(kml) {
  var me = this;

  // The model zip file is actually a kmz, containing a KmlFolder with
  // a camera KmlPlacemark (we don't care) and a model KmlPlacemark
  // (our milktruck).
  window.kml = kml;//xxxxxx
  me.placemark_sub = kml.getFeatures().getChildNodes().item(1);
  me.model_sub = me.placemark_sub.getGeometry();
  me.model_sub.setAltitudeMode(ge.ALTITUDE_ABSOLUTE);
  //  me.orientation.setHeading(90);
//   me.model.setOrientation(me.orientation);

//   ge.getFeatures().appendChild(me.placemark);

//   me.balloon = ge.createHtmlStringBalloon('');
//   me.balloon.setFeature(me.placemark);
//   me.balloon.setMaxWidth(200);

//   me.teleportTo(19.912811, -155.892137, 180);  // Hawaii

//   me.lastMillis = (new Date()).getTime();

//   var href = window.location.href;
//   var pagePath = href.substring(0, href.lastIndexOf('/')) + '/';

//   me.shadow = ge.createGroundOverlay('');
//   me.shadow.setVisibility(false);
//   me.shadow.setIcon(ge.createIcon(''));
//   me.shadow.setLatLonBox(ge.createLatLonBox(''));
//   me.shadow.setAltitudeMode(ge.ALTITUDE_CLAMP_TO_GROUND);
//   me.shadow.getIcon().setHref(pagePath + 'shadowrect.png');
//   me.shadow.setVisibility(true);
//   ge.getFeatures().appendChild(me.shadow);

//   google.earth.addEventListener(ge, "frameend", function() { me.tick(); });

//   me.cameraCut();
  me.teleportTo(41.7229, -49.9503, 0);  // Titanic.
  me.setSubMode(true);
}


var leftButtonDown = false;
var rightButtonDown = false;
var gasButtonDown = false;
var reverseButtonDown = false;
var jumpButtonDown = false;
var jumpButtonSignalled = false;

function keyDown(event) {
  if (!event) {
    event = window.event;
  }
  if (event.keyCode == 37) {  // Left.
    leftButtonDown = true;
    event.returnValue = false;
  } else if (event.keyCode == 39) {  // Right.
    rightButtonDown = true;
    event.returnValue = false;
  } else if (event.keyCode == 38) {  // Up.
    gasButtonDown = true;
    event.returnValue = false;
  } else if (event.keyCode == 40) {  // Down.
    reverseButtonDown = true;
    event.returnValue = false;
  } else if (event.keyCode == 32) {  // Jump.
    if (!jumpButtonDown) {
      jumpButtonSignalled = true;
    }
    jumpButtonDown = true;
    event.returnValue = false;
  } else {
    return true;
  }
  return false;
}

function keyUp(event) {
  if (!event) {
    event = window.event;
  }
  if (event.keyCode == 37) {  // Left.
    leftButtonDown = false;
    event.returnValue = false;
  } else if (event.keyCode == 39) {  // Right.
    rightButtonDown = false;
    event.returnValue = false;
  } else if (event.keyCode == 38) {  // Up.
    gasButtonDown = false;
    event.returnValue = false;
  } else if (event.keyCode == 40) {  // Down.
    reverseButtonDown = false;
    event.returnValue = false;
  } else if (event.keyCode == 32) {  // Jump.
    jumpButtonDown = false;
    event.returnValue = false;
  }
  return false;
}

function clamp(val, min, max) {
  if (val < min) {
    return min;
  } else if (val > max) {
    return max;
  }
  return val;
}

function lerp(val, min, max) {
  return min + (max - min) * val;
}

Truck.prototype.setSubMode = function(newmode) {
  var me = this;
  if (newmode != me.subMode) {
    var new_model = newmode ? me.model_sub : me.model_surfer;

    var new_orientation = new_model.getOrientation();
    var old_o = me.orientation;
    new_orientation.set(old_o.getHeading(), old_o.getTilt(), old_o.getRoll());

    var new_location = new_model.getLocation();
    var old_l = me.model.getLocation();
    new_location.setLatLngAlt(old_l.getLatitude(),
                              old_l.getLongitude(),
                              old_l.getAltitude());

    // Do the swap.
    me.model = new_model;
    me.orientation = new_orientation;
    me.placemark.setGeometry(me.model);

    me.subMode = newmode;
  }
};

Truck.prototype.tick = function() {
  var me = this;

  var now = (new Date()).getTime();
  // dt is the delta-time since last tick, in seconds
  var dt = (now - me.lastMillis) / 1000.0;
  if (dt > 0.25) {
    dt = 0.25;
  }
  me.lastMillis = now;

  var c0 = 1;
  var c1 = 0;

  var gpos = V3.add(me.localAnchorCartesian,
                    M33.transform(me.localFrame, me.pos));
  var lla = V3.cartesianToLatLonAlt(gpos);

  if (V3.length([me.pos[0], me.pos[1], 0]) > 100) {
    // Re-anchor our local coordinate frame whenever we've strayed a
    // bit away from it.  This is necessary because the earth is not
    // flat!
    me.adjustAnchor();
  }

  var dir = me.modelFrame[1];
  var up = me.modelFrame[2];

  var absSpeed = V3.length(me.vel);

  var groundAlt = ge.getGlobe().getGroundAltitude(lla[0], lla[1]);
  // TODO(tulrich): we're assuming water level is 0 -- can we query
  // for true water height?
  var overWater = groundAlt < 0;
  var underWater = me.pos[2] < 0;
  var onGround = (groundAlt + GROUND_SLOP > me.pos[2]);
  var steerAngle = 0;
  var underWaterFactor = clamp(0 - me.pos[2], 0, 1);

  // Morph between surfer and sub.
  if (jumpButtonSignalled) {
    jumpButtonSignalled = false;
    if (me.subMode == false) {
      // I'm the surfer.
      if (overWater) {
        // Only allow change to sub when we're over the ocean.
        me.setSubMode(true);
      }
    } else {
      // I'm the sub.
      me.setSubMode(false);
    }
  }
  if (me.subMode && onGround && !overWater && me.pinToGroundTimer == 0) {
    // If we're the sub and we've landed on the ground, automatically
    // switch to the surfer.
    me.setSubMode(false);
  }

  // Steering.
  if (leftButtonDown || rightButtonDown) {
    var TURN_SPEED_MIN = 6.0;  // radians/sec
    var TURN_SPEED_MAX = 70.0;  // radians/sec

    var turnSpeed;

    // Degrade turning at higher speeds.
    //
    //           angular turn speed vs. vehicle speed
    //    |     -------
    //    |    /       \-------
    //    |   /                 \-------
    //    |--/                           \---------------
    //    |
    //    +-----+-------------------------+-------------- speed
    //    0    SPEED_MAX_TURN           SPEED_MIN_TURN
    var SPEED_MAX_TURN = 25.0;
    var SPEED_MIN_TURN = 120.0;
    if (absSpeed < SPEED_MAX_TURN) {
      turnSpeed = TURN_SPEED_MIN + (TURN_SPEED_MAX - TURN_SPEED_MIN)
                   * (SPEED_MAX_TURN - absSpeed) / SPEED_MAX_TURN;
      turnSpeed *= (absSpeed / SPEED_MAX_TURN);  // Less turn as truck slows
    } else if (absSpeed < SPEED_MIN_TURN) {
      turnSpeed = TURN_SPEED_MIN + (TURN_SPEED_MAX - TURN_SPEED_MIN)
                  * (SPEED_MIN_TURN - absSpeed)
                  / (SPEED_MIN_TURN - SPEED_MAX_TURN);
    } else {
      turnSpeed = TURN_SPEED_MIN;
    }
    if (leftButtonDown) {
      steerAngle = turnSpeed * dt * Math.PI / 180.0;
    }
    if (rightButtonDown) {
      steerAngle = -turnSpeed * dt * Math.PI / 180.0;
    }
  }

// Steering always works
//  var newdir = (underWater || onGround) ? V3.rotate(dir, up, steerAngle) : dir ;
  var newdir = V3.rotate(dir, up, steerAngle);
  me.modelFrame = M33.makeOrthonormalFrame(newdir, up);
  dir = me.modelFrame[1];
  up = me.modelFrame[2];

  var forwardSpeed = 0;

  if (onGround || underWater) {
    // TODO: if we're slipping, transfer some of the slip
    // velocity into forward velocity.

    // Damp sideways slip.  Ad-hoc frictiony hack.
    //
    // I'm using a damped exponential filter here, like:
    // val = val * c0 + val_new * (1 - c0)
    //
    // For a variable time step:
    //  c0 = exp(-dt / TIME_CONSTANT)
    var right = me.modelFrame[0];
    var slip = V3.dot(me.vel, right);
    c0 = Math.exp(-dt / 0.5);
    me.vel = V3.sub(me.vel, V3.scale(right, slip * (1 - c0)));

    // Apply engine/reverse accelerations.
    var ACCEL = 50.0;
    var DECEL = 80.0;
    var MAX_REVERSE_SPEED = 40.0;
    forwardSpeed = V3.dot(dir, me.vel);
    if (gasButtonDown) {
      // Accelerate forwards.
      me.vel = V3.add(me.vel, V3.scale(dir, ACCEL * dt));
    } else if (reverseButtonDown) {
      if (forwardSpeed > -MAX_REVERSE_SPEED)
        me.vel = V3.add(me.vel, V3.scale(dir, -DECEL * dt));
    }
  }

  // Air drag.
  //
  // Fd = 1/2 * rho * v^2 * Cd * A.
  // rho ~= 1.2 (typical conditions)
  // Cd * A = 3 m^2 ("drag area")
  //
  // I'm simplifying to:
  //
  // accel due to drag = 1/Mass * Fd
  // with Milktruck mass ~= 2000 kg
  // so:
  // accel = 0.6 / 2000 * 3 * v^2
  // accel = 0.0009 * v^2
  absSpeed = V3.length(me.vel);
  if (absSpeed > 0.01) {
    var veldir = V3.normalize(me.vel);
    var DRAG_FACTOR = 0.00090;
    var UNDERWATER_DRAG_FACTOR = 0.005;
    var dragFactor = DRAG_FACTOR * (1 - underWaterFactor) +
        UNDERWATER_DRAG_FACTOR * underWaterFactor;
    var drag = absSpeed * absSpeed * dragFactor;

    // Some extra constant drag (rolling resistance etc) to make sure
    // we eventually come to a stop.
    var CONSTANT_DRAG = 2.0;
    drag += CONSTANT_DRAG;

    if (drag > absSpeed) {
      drag = absSpeed;
    }

    me.vel = V3.sub(me.vel, V3.scale(veldir, drag * dt));
  }

  // Gravity
  me.vel[2] -= 9.8 * dt;
  if (me.subMode == false && underWater) {
    // Surfer is mildly bouyant when under water.
    me.vel[2] += (9.8 + 5) * dt * underWaterFactor;
  }
  if (me.subMode == true && me.pos[2] < 0) {
    // Sub gets more bouyant when it approaches the seafloor.
    var aboveFloorFactor = Math.max(0, 1 - (me.pos[2] - groundAlt) / 30);
    var belowSurfaceFactor = Math.min((-me.pos[2] / 10), 1);
    me.vel[2] += (9.8 + 2) * dt * aboveFloorFactor * belowSurfaceFactor;
  }

  // Move.
  var deltaPos = V3.scale(me.vel, dt);
  me.pos = V3.add(me.pos, deltaPos);

  gpos = V3.add(me.localAnchorCartesian,
                M33.transform(me.localFrame, me.pos));
  lla = V3.cartesianToLatLonAlt(gpos);

  // Don't go underground.
  groundAlt = ge.getGlobe().getGroundAltitude(lla[0], lla[1]);
  if (me.pos[2] < groundAlt) {
    me.pos[2] = groundAlt;
  }

  if (me.pinToGroundTimer > 0) {
    me.pinToGroundTimer = Math.max(0, me.pinToGroundTimer - dt);
    // Force the player to be on the ground; we use this because after
    // teleporting, the ground often moves around a lot due to terrain
    // paging in.
    me.pos[2] = groundAlt;
  }

  var normal = estimateGroundNormal(gpos, me.localFrame);

  if (onGround) {
    if (jumpButtonDown) {
      var JUMP_IMPULSE = 5;
      me.vel = V3.add(me.vel, V3.scale(normal, JUMP_IMPULSE));
    }

    // Cancel velocity into the ground.
    //
    // TODO: would be fun to add a springy suspension here so
    // the truck bobs & bounces a little.
    var speedOutOfGround = V3.dot(normal, me.vel);
    if (speedOutOfGround < 0 && me.pos[2] <= groundAlt + 0.1) {
      me.vel = V3.add(me.vel,
                      V3.scale(normal, -speedOutOfGround));
    }

    // Make our orientation follow the ground.
    c0 = Math.exp(-dt / 0.25);
    c1 = 1 - c0;
    var blendedUp = V3.normalize(V3.add(V3.scale(up, c0),
                                        V3.scale(normal, c1)));
    me.modelFrame = M33.makeOrthonormalFrame(dir, blendedUp);
  }

  // Propagate our state into Earth.
  gpos = V3.add(me.localAnchorCartesian,
                M33.transform(me.localFrame, me.pos));
  lla = V3.cartesianToLatLonAlt(gpos);
  me.model.getLocation().setLatLngAlt(lla[0], lla[1], lla[2]);

  var newhtr = M33.localOrientationMatrixToHeadingTiltRoll(me.modelFrame);

  // Compute roll according to steering.
  // TODO: this would be even more cool in 3d.
  var absRoll = newhtr[2];
  me.rollSpeed += steerAngle * forwardSpeed * STEER_ROLL;
  // Spring back to center, with damping.
  me.rollSpeed += (ROLL_SPRING * -me.roll + ROLL_DAMP * me.rollSpeed);
  me.roll += me.rollSpeed * dt;
  me.roll = clamp(me.roll, -30, 30);
  absRoll += me.roll;

  me.orientation.set(newhtr[0], newhtr[1], absRoll);

  var latLonBox = me.shadow.getLatLonBox();
  var radius = .00010;
  latLonBox.setNorth(lla[0] - radius);
  latLonBox.setSouth(lla[0] + radius);
  latLonBox.setEast(lla[1] - radius);
  latLonBox.setWest(lla[1] + radius);
  latLonBox.setRotation(180 - newhtr[0]);

  me.tickPopups(dt);

  me.cameraFollow(dt, gpos, me.localFrame, me.pos[2]);

  // Hack to work around focus bug
  // TODO: fix that bug and remove this hack.
  ge.getWindow().blur();
};

// TODO: would be nice to have globe.getGroundNormal() in the API.
function estimateGroundNormal(pos, frame) {
  // Take four height samples around the given position, and use it to
  // estimate the ground normal at that position.
  //  (North)
  //     0
  //     *
  //  2* + *3
  //     *
  //     1
  var pos0 = V3.add(pos, frame[0]);
  var pos1 = V3.sub(pos, frame[0]);
  var pos2 = V3.add(pos, frame[1]);
  var pos3 = V3.sub(pos, frame[1]);
  var globe = ge.getGlobe();
  function getAlt(p) {
    var lla = V3.cartesianToLatLonAlt(p);
    return globe.getGroundAltitude(lla[0], lla[1]);
  }
  var dx = getAlt(pos1) - getAlt(pos0);
  var dy = getAlt(pos3) - getAlt(pos2);
  var normal = V3.normalize([dx, dy, 2]);
  return normal;
}

// Decide when to open & close popup messages.
Truck.prototype.tickPopups = function(dt) {
  var me = this;
  var speed = V3.length(me.vel);
  if (me.popupTimer > 0) {
    me.popupTimer -= dt;
    me.idleTimer = 0;
    me.fastTimer = 0;
    if (me.popupTimer <= 0) {
      me.popupTimer = 0;
      ge.setBalloon(null);
    }
  } else {
    if (speed < 20) {
      me.idleTimer += dt;
      if (me.idleTimer > 10.0) {
        me.showIdlePopup();
      }
      me.fastTimer = 0;
    } else {
      me.idleTimer = 0;
      if (speed > 80) {
        me.fastTimer += dt;
        if (me.fastTimer > 7.0) {
          me.showFastPopup();
        }
      } else {
        me.fastTimer = 0;
      }
    }
  }
};

var IDLE_MESSAGES = [
    "Let's ride some waves!",
    "Hello?",
    "Dude, <font color=red><i>step on it!</i></font>",
    "I'm sitting here getting soggy!",
    "We got customers waiting!",
    "Zzzzzzz",
    "Sometimes I wish I had a boat."
                     ];
Truck.prototype.showIdlePopup = function() {
  var me = this;
  me.popupTimer = 2.0;
  var rand = Math.random();
  var index = Math.floor(rand * IDLE_MESSAGES.length)
    % IDLE_MESSAGES.length;
  var message = "<center>" + IDLE_MESSAGES[index] + "</center>";
  me.balloon.setContentString(message);
  ge.setBalloon(me.balloon);
};

var FAST_MESSAGES = [
    "Whoah there, cowboy!",
    "Wheeeeeeeeee!",
    "<font size=+5 color=#8080FF>Cowabunga!</font>",
    "Totally Tubular!"
                     ];
Truck.prototype.showFastPopup = function() {
  var me = this;
  me.popupTimer = 2.0;
  var rand = Math.random();
  var index = Math.floor(rand * FAST_MESSAGES.length)
    % FAST_MESSAGES.length;
  var message = "<center>" + FAST_MESSAGES[index] + "</center>";
  me.balloon.setContentString(message);
  ge.setBalloon(me.balloon);
};

Truck.prototype.scheduleTick = function() {
  var me = this;
  if (me.doTick) {
    setTimeout(function() { me.tick(); }, TICK_MS);
  }
};

// Cut the camera to look at me.
Truck.prototype.cameraCut = function() {
  var me = this;
  var lo = me.model.getLocation();
  var la = ge.createLookAt('');
  la.set(lo.getLatitude(), lo.getLongitude(),
         10 /* altitude */,
         ge.ALTITUDE_RELATIVE_TO_SEA_FLOOR,
         fixAngle(180 + me.model.getOrientation().getHeading() + 45),
         80, /* tilt */
         50 /* range */
         );
  ge.getView().setAbstractView(la);
};

Truck.prototype.cameraFollow = function(dt, truckPos, localToGlobalFrame,
                                        truckAlt) {
  var me = this;

  var c0 = Math.exp(-dt / 0.5);
  var c1 = 1 - c0;

  var la = ge.getView().copyAsLookAt(ge.ALTITUDE_RELATIVE_TO_SEA_FLOOR);

  var truckHeading = me.model.getOrientation().getHeading();
  var camHeading = la.getHeading();

  var deltaHeading = fixAngle(truckHeading - camHeading);
  var heading = camHeading + c1 * deltaHeading;
  heading = fixAngle(heading);

  var TRAILING_DISTANCE = 50;
  var headingRadians = heading / 180 * Math.PI;

  var CAM_HEIGHT = 10;

  var headingDir = V3.rotate(localToGlobalFrame[1], localToGlobalFrame[2],
                             -headingRadians);
  var camPos = V3.add(truckPos, V3.scale(localToGlobalFrame[2], CAM_HEIGHT));
  camPos = V3.add(camPos, V3.scale(headingDir, -TRAILING_DISTANCE));
  var camLla = V3.cartesianToLatLonAlt(camPos);
  var camLat = camLla[0];
  var camLon = camLla[1];
  var groundUnderCam = ge.getGlobe().getGroundAltitude(camLat, camLon);
  var camAlt = camLla[2] - groundUnderCam;
  var tilt = 80;

  // Keep camera above the ground.
  if (camAlt < 8) {
    // This crazy formula moves the camera higher according to how far
    // underground it wants to be.  The goal is to prevent Earth from
    // forcing the camera above some notional lower limit, because
    // earth does this very crudely with a lot of annoying jitter.
    camAlt = 8 + clamp(8 - camAlt, 0, 16);
  }

  // Try to keep the surfer vaguely in frame.
  var absCamAlt = camAlt + groundUnderCam;
  tilt = 90 - 180 * Math.atan2(absCamAlt - (truckAlt + 8), TRAILING_DISTANCE) / Math.PI;

  la.set(camLat, camLon, camAlt, ge.ALTITUDE_RELATIVE_TO_SEA_FLOOR,
        heading, tilt, 0 /*range*/);
  ge.getView().setAbstractView(la);
};

// heading is optional.
Truck.prototype.teleportTo = function(lat, lon, heading) {
  var me = this;
  me.model.getLocation().setLatitude(lat);
  me.model.getLocation().setLongitude(lon);
  me.model.getLocation().setAltitude(ge.getGlobe().getGroundAltitude(lat, lon));
  if (heading == null) {
    heading = 0;
  }
  var heading_radians = heading * Math.PI / 180;
  me.vel = [0, 0, 0];

  me.localAnchorLla = [lat, lon, 0];
  me.localAnchorCartesian = V3.latLonAltToCartesian(me.localAnchorLla);
  me.localFrame = M33.makeLocalToGlobalFrame(me.localAnchorLla);
  me.modelFrame = M33.identity();
  me.modelFrame[0] = V3.rotate(me.modelFrame[0], me.modelFrame[2],
                               -heading_radians);
  me.modelFrame[1] = V3.rotate(me.modelFrame[1], me.modelFrame[2],
                               -heading_radians);
  me.pos = [0, 0, ge.getGlobe().getGroundAltitude(lat, lon)];

  me.cameraCut();

  me.pinToGroundTimer = 0.500;
};

// Move our anchor closer to our current position.  Retain our global
// motion state (position, orientation, velocity).
Truck.prototype.adjustAnchor = function() {
  var me = this;
  var oldLocalFrame = me.localFrame;

  var globalPos = V3.add(me.localAnchorCartesian,
                         M33.transform(oldLocalFrame, me.pos));
  var newAnchorLla = V3.cartesianToLatLonAlt(globalPos);
  newAnchorLla[2] = 0;  // For convenience, anchor always has 0 altitude.

  var newAnchorCartesian = V3.latLonAltToCartesian(newAnchorLla);
  var newLocalFrame = M33.makeLocalToGlobalFrame(newAnchorLla);

  var oldFrameToNewFrame = M33.transpose(newLocalFrame);
  oldFrameToNewFrame = M33.multiply(oldFrameToNewFrame, oldLocalFrame);

  var newVelocity = M33.transform(oldFrameToNewFrame, me.vel);
  var newModelFrame = M33.multiply(oldFrameToNewFrame, me.modelFrame);
  var newPosition = M33.transformByTranspose(
      newLocalFrame,
      V3.sub(globalPos, newAnchorCartesian));

  me.localAnchorLla = newAnchorLla;
  me.localAnchorCartesian = newAnchorCartesian;
  me.localFrame = newLocalFrame;
  me.modelFrame = newModelFrame;
  me.pos = newPosition;
  me.vel = newVelocity;
}

// Keep an angle in [-180,180]
function fixAngle(a) {
  while (a < -180) {
    a += 360;
  }
  while (a > 180) {
    a -= 360;
  }
  return a;
}

truck = new Truck();

