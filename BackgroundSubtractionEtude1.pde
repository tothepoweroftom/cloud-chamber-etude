import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;


//First STep!!!
//This piece of code implements the background subtraction and draws the contours of the moving objects. The bounding box of each of the contours is
//found and an intersection between the contour boundary and the detection zone is determined.


import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;


Movie video;
OpenCV opencv;
Rectangle dZ;
Rectangle dZ1;
Rectangle dZ2;


ArrayList<PVector> points = new ArrayList<PVector>();

Minim minim;
AudioSample note1;
AudioSample note2;
AudioSample note3;

void setup() {

  video = new Movie(this, "cloudchamber.mp4");
    size(1280, 720);
  opencv = new OpenCV(this, 1280, 720);
  
  opencv.startBackgroundSubtraction(5, 3, 0.2);
  
  dZ = new Rectangle(int(width/2.5), int(height/3), 100, 100);
    dZ1 = new Rectangle(int(width/4), int(height/3), 100, 100);
        dZ2 = new Rectangle(int(width/4), int(height/2), 100, 100);


  
  minim = new Minim(this);
  note1 = minim.loadSample("c5.wav");
    note2 = minim.loadSample("eb5.wav");
  note3 = minim.loadSample("g5.wav");

  
  video.loop();
  video.play();
}

void draw() {
  image(video, 0, 0);  
  opencv.loadImage(video);
  
  opencv.updateBackground();
  
  rectMode(CENTER);
  noFill();
  stroke(255, 0, 0);
  rect(dZ.x, dZ.y, dZ.width, dZ.height);
    stroke(0, 255, 0);
    rect(dZ1.x, dZ1.y, dZ1.width, dZ1.height);
        stroke(0, 0, 255);
        rect(dZ2.x, dZ2.y, dZ2.width, dZ2.height);

  
  
  opencv.dilate();
  opencv.erode();

  noFill();
  stroke(255, 0, 0);
  strokeWeight(3);
  
  //Contour detection
  for (Contour contour : opencv.findContours()) {
    //contour.draw();
    Rectangle cont = contour.getBoundingBox();
    //rect(cont.x, cont.y, cont.width, cont.height);
    
    if(dZ.contains(cont.x+cont.width/2, cont.y+cont.height/2)){
      note1.trigger();    
     
     }
         if(dZ1.contains(cont.x+cont.width/2, cont.y+cont.height/2)){
      note2.trigger();    
     
     }
     
              if(dZ2.contains(cont.x+cont.width/2, cont.y+cont.height/2)){
      note3.trigger();    
     
     }
     
    
    


      
    
    
   
  }
}

void movieEvent(Movie m) {
  m.read();
}
