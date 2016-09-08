import themidibus.*;

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import javax.swing.*;


//ETUDE 4 - Thomas Power
//This etude aims to improve the computer vision part of the project, removes samples to used midi which is sent over different channels. for each grid.


import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

//D Dorian
int[] scale = {
  50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76
};
MidiBus myBus; // The MidiBus

Movie video;
OpenCV opencv;
int numberX = 4;
int numberY = 4;

// Set up the sample grids
MidiRect[][] grid = new MidiRect[numberX][numberY];
MidiRect[][] vibgrid = new MidiRect[numberX][numberY];
MidiRect[][] novaGrid = new MidiRect[numberX][numberY];
MidiRect[][] drumGrid = new MidiRect[numberX][numberY];



//Points array list for contours
ArrayList<PVector> points = new ArrayList<PVector>();




//OPENCV Threshold control
int thresholdValue;

//Contour Bounding Box Threshold Control
int bbSize;

void setup() {
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  myBus = new MidiBus(this, -1, "cloud"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.

  video = new Movie(this, "othercloudchamber.mp4");
  size(1280, 720);

  opencv = new OpenCV(this, 1280, 720);

  //Initialize our threshold
  thresholdValue = 220;
  bbSize = 65;

  //Reduce framerate to control retriggering

  frameRate(4);


  //Start Backsubtraction
  opencv.startBackgroundSubtraction(5, 3, 0.2);


  //Initialize MIDI RECTS
  for (int i = 0; i<numberX*numberY; i++) {
    grid[i%4][i/4] = new MidiRect(int((i%4)*width/(2*numberX)), int(int((i/4))*height/(2*numberY)), width/8, height/8, scale[i]+ 12, 2);
    vibgrid[i%4][i/4] = new MidiRect(int((i%4)*width/(2*numberX) +width/2), int(int((i/4))*height/(2*numberY)), width/8, height/8, scale[i]+12, 3);  
    novaGrid[i%4][i/4] = new MidiRect(int((i%4)*width/(2*numberX)), int(int((i/4))*height/(2*numberY)+height/2), width/8, height/8, scale[i], 4);  
    drumGrid[i%4][i/4] = new MidiRect(int((i%4)*width/(2*numberX) +width/2), int(int((i/4))*height/(2*numberY)+height/2), width/8, height/8, scale[i], 5);  

    println("Rectangle Created Succesfully" + (i%4) + (i/4));
  }



  video.loop();
  video.play();
  background(0);
}

void draw() {
  image(video, 0, 0);  
  //OPENCV methods - load, update, threshold and smooth.
  opencv.loadImage(video);
  opencv.updateBackground();
  opencv.threshold(thresholdValue);
  opencv.dilate();
  opencv.erode();
  noFill();
  stroke(255, 0, 0);
  //Draw the grid overlay
  drawGrid();


  //Contour detection mechanism
  for (Contour contour : opencv.findContours ()) {

    //Find the bounding box to compare with the grid rectangles
    Rectangle cont = contour.getBoundingBox();
    if (cont.width*cont.height > bbSize) {
      // contour.draw();
      stroke(0, 0, 255);
      rect(cont.x, cont.y, cont.width, cont.height);

      //Approximate Centroid of contour - maybe use a better centroid finder!
      float centX = cont.x + 0.5*cont.width;
      float centY = cont.y + 0.5*cont.height;
      float area = cont.width*cont.height;
      int vel = int(map(area, 1, 2000, 100, 127));
      println(vel);


      //Check rectangles if they contain contour centroids. TRIGGER MIDI IF TRUE
      for (int i = 0; i<numberX*numberY; i++) {

        //GRID 1
        if (grid[i%4][i/4].contains(centX, centY)) {
          myBus.sendNoteOn(1, grid[i%4][i/4].note, vel); // Send a Midi noteOn
          delay(50);
          myBus.sendNoteOff(1, grid[i%4][i/4].note, vel); // Send a Midi noteOn
        }
        //GRID 2
        if (vibgrid[i%4][i/4].contains(centX, centY)) {

          myBus.sendNoteOn(2, vibgrid[i%4][i/4].note, vel); // Send a Midi noteOn
          delay(50);
          myBus.sendNoteOff(2, vibgrid[i%4][i/4].note, vel); // Send a Midi noteOn
        }    
        //GRID 3
        if (novaGrid[i%4][i/4].contains(centX, centY)) {
          myBus.sendNoteOn(3, novaGrid[i%4][i/4].note, vel); // Send a Midi noteOn
          delay(50);
          myBus.sendNoteOff(3, novaGrid[i%4][i/4].note, vel); // Send a Midi noteOn
        }

        //GRID 4
        if (drumGrid[i%4][i/4].contains(centX, centY)) {
          myBus.sendNoteOn(5, drumGrid[i%4][i/4].note, vel); // Send a Midi noteOn
          delay(50);
          myBus.sendNoteOff(5, drumGrid[i%4][i/4].note, vel);
        }
      }
    }
  }
}

void movieEvent(Movie m) {
  m.read();
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      bbSize++;
    } else if (keyCode == DOWN) {
      bbSize--;
    } else if (keyCode == ENTER) {
      video.pause();
    }
  }
  println("Boundary Box Threshold = " + bbSize);
}

void mousePressed() {
  video.pause();
}

void mouseReleased() {
  video.play();
}

void stop() {
  super.stop();
}

class MidiRect extends Rectangle {
  int note;
  int channel;
  int velocity;
  MidiRect(int x, int y, int w, int h, int _note, int _channel) {

    super(x, y, w, h);
    note = _note;
    channel = _channel;
  }
}

void drawGrid() {
  for (int i = 0; i<numberX*numberY; i++) {
    noFill();
    stroke(0, 255, 0);
    // strokeWeight(1);
    Rectangle currentRect = grid[i%4][i/4];
    Rectangle currentRect2 = vibgrid[i%4][i/4];
    Rectangle currentRect3 = novaGrid[i%4][i/4];

    Rectangle currentRect4 = drumGrid[i%4][i/4];
    strokeWeight(0.1);
    rect(currentRect.x, currentRect.y, currentRect.width, currentRect.height);
    stroke(255, 0, 255);
    rect(currentRect2.x, currentRect2.y, currentRect2.width, currentRect2.height);
    stroke(255, 255, 0);
    rect(currentRect3.x, currentRect3.y, currentRect3.width, currentRect3.height);
    stroke(0, 255, 255);
    rect(currentRect4.x, currentRect4.y, currentRect4.width, currentRect4.height);
  }
}





public class PFrame extends JFrame {
  public PFrame(int width, int height) {
    setBounds(100, 100, width, height);
    s = new secondApplet();
    add(s);
    s.init();
    show();
  }
}

public class secondApplet extends PApplet {

  public void setup() {
    size(600, 900);
    noLoop();
  }
  public void draw() {
    fill(0);
    ellipse(400, 60, 20, 20);
  }
  /*
   * TODO: something like on Close set f to null, this is important if you need to 
   * open more secondapplet when click on button, and none secondapplet is open.
   */
}

