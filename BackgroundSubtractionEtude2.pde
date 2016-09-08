import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;


//ETUDE II
//This piece of code implements the background subtraction and draws the contours of the moving objects. The bounding box of each of the contours is
//found and an intersection between the contour boundary and the detection zone is determined.


import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;


Movie video;
OpenCV opencv;
Rectangle dZ;
int numberX = 4;
int numberY = 4;
Rectangle[][] grid = new Rectangle[numberX][numberY];

ArrayList<PVector> points = new ArrayList<PVector>();


//Audio stuff - will eventually replace with osc to MAX/MSP
Minim minim;
AudioSample note1;
Sampler samples[];
AudioOutput out;
Constant attack;
Constant amp;

//OPENCV Threshold control
int thresholdValue;

//Contour Bounding Box Threshold Control
int bbSize;

void setup() {
    size(1280, 720);
  video = new Movie(this, "cloudchamber.mp4");

  opencv = new OpenCV(this, 1280, 720);
  
  //Initialize our threshold
  thresholdValue = 220;
  bbSize = 50;
  
  //frameRate(10);
  
  //Not sure what the values here do yet.
  opencv.startBackgroundSubtraction(5, 3, 0.2);
  
  dZ = new Rectangle(int(width/2.5), int(height/3), 100, 100);

  
  for(int i = 0; i<numberX*numberY; i++) {
     grid[i%4][i/4] = new Rectangle(int((i%4)*width/(2*numberX)), int(int((i/4))*height/(2*numberY)), width/8, height/8);  
    println("Rectangle Created Succesfully" + (i%4) + (i/4)); 
   
  }



  
  minim = new Minim(this);
  samples = new Sampler[16];
  out = minim.getLineOut(minim.STEREO);
              attack = new Constant(0.02);
              amp = new Constant(0.2);


  
  for(int i = 0; i<samples.length; i++){

   samples[i] = new Sampler(str(i+1)+".wav", 32, minim);
   samples[i].patch(out);
   println(str(i+1)+".wav");
                 attack.patch(samples[i].attack);
                 amp.patch(samples[i].amplitude);
  }

  
  video.loop();
  video.play();
}

void draw() {
 // image(video, 0, 0);  
  background(0);
  opencv.loadImage(video);
  
  opencv.updateBackground();
    opencv.threshold(thresholdValue);

  
  //rectMode(CENTER);
  noFill();
  stroke(255, 0, 0);

  for(int i = 0; i<numberX*numberY; i++) {
   noFill();
   stroke(0, 255, 0);
   Rectangle currentRect = grid[i%4][i/4];
   rect(currentRect.x, currentRect.y, currentRect.width, currentRect.height);

  }



  
  
  opencv.dilate();
  opencv.erode();

  noFill();
  stroke(255, 0, 0);
  strokeWeight(3);
  
  
  //Contour detection
  for (Contour contour : opencv.findContours()) {

    Rectangle cont = contour.getBoundingBox();
    if (cont.width*cont.height > bbSize){
      contour.draw();
    stroke(0,0,255);
    rect(cont.x, cont.y, cont.width, cont.height);
    
    //Approximate Centroid of contour - maybe use a better centroid finder!
    float centX = cont.x + 0.5*cont.width;
    float centY = cont.y + 0.5*cont.height;
    
    
    //Check rectangles if they contain contour centroids.
    for(int i = 0; i<numberX*numberY; i++) {

    
        if(grid[i%4][i/4].contains(centX, centY)){
          samples[i].trigger();

         // samples[i].stop();
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
    } 
  }
  println("Boundary Box Threshold = " + bbSize);
}


