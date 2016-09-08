import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;






//////////////////////////////////////////////////////////////////////////////////////////
//
//        ////ETUDE 4 - THOMAS POWER
//        //This piece of code implements the background subtraction and draws the contours of the moving objects.
//        //The bounding box of each of the contours is found and the intersection
//        // between the contour boundary and the detection zone is determined.
//        // This triggers the corresponding sample in the grid
//  
//
//
///////////////////////////////////////////////////////////////////////////////////////////


// IMPORT COMPUTER VISION AND VIDEO LIBRARIES
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;


Movie video;
OpenCV opencv;
Rectangle dZ;
int numberX = 4;
int numberY = 4;

//CREATE 4 GRID GROUPS  
Rectangle[][] grid = new Rectangle[numberX][numberY];
Rectangle[][] vibgrid = new Rectangle[numberX][numberY];
Rectangle[][] novaGrid = new Rectangle[numberX][numberY];
Rectangle[][] drumGrid = new Rectangle[numberX][numberY];



// STORES CONTOUR POINTS
ArrayList<PVector> points = new ArrayList<PVector>();


//AUDIO - SOME INEFFICIENT REPETITION OF CODE
Minim minim;
AudioSample note1;
Sampler samples[];
Sampler samples2[];
Sampler samples3[];
Sampler samples4[];



AudioOutput out;
AudioOutput out2;
AudioOutput out3;
AudioOutput out4;



Constant attack;
Constant attack2;
Constant attack3;
Constant attack4;


Constant amp;
Constant amp2;
Constant amp3;
Constant amp4;



//OPENCV Threshold control
int thresholdValue;

//Contour Bounding Box Threshold Control
int bbSize;

void setup() {
  size(1280, 720);
  video = new Movie(this, "OtherCloudChamber.mp4");

  //INITIALIZE OPEN CV
  opencv = new OpenCV(this, 1280, 720);

  //Initialize our threshold
  thresholdValue = 220;

  //Initialize the min size
  bbSize = 150;


  //START THE BACKGROUND SUBTRACTION
  opencv.startBackgroundSubtraction(5, 3, 0.2);


  // INITIALIZE THE RECTANGLE GRID SYSTEM
  for (int i = 0; i<numberX*numberY; i++) {
    grid[i%4][i/4] = new Rectangle(int((i%4)*width/(2*numberX)), int(int((i/4))*height/(2*numberY)), width/8, height/8);
    vibgrid[i%4][i/4] = new Rectangle(int((i%4)*width/(2*numberX) +width/2), int(int((i/4))*height/(2*numberY)), width/8, height/8);  
    novaGrid[i%4][i/4] = new Rectangle(int((i%4)*width/(2*numberX)), int(int((i/4))*height/(2*numberY)+height/2), width/8, height/8);  
    drumGrid[i%4][i/4] = new Rectangle(int((i%4)*width/(2*numberX) +width/2), int(int((i/4))*height/(2*numberY)+height/2), width/8, height/8);  

    println("Rectangle Created Succesfully" + (i%4) + (i/4));
  }



  //  INITIALIZE AUDIO 
  minim = new Minim(this);
  samples = new Sampler[16];
  samples2 = new Sampler[16];
  samples3 = new Sampler[16];
  samples4 = new Sampler[16];



  out = minim.getLineOut(minim.STEREO);
  out2 = minim.getLineOut(minim.STEREO);
  out3 = minim.getLineOut(minim.STEREO);
  out4 = minim.getLineOut(minim.STEREO);



  attack = new Constant(0.05);
  attack2 = new Constant(0.01);
  attack3 = new Constant(0.1);
  attack4 = new Constant(0.1);


  amp = new Constant(0.3);
  amp2 = new Constant(0.2);
  amp3 = new Constant(0.4);
  amp4 = new Constant(0.05);




  // LOAD SAMPLES INTO MINIM SAMPLERS
  for (int i = 0; i<samples.length; i++) {

    samples[i] = new Sampler(str(i+1)+".wav", 32, minim);
    samples[i].patch(out);
    println(str(i+1)+".wav"); 
    attack.patch(samples[i].attack);
    amp.patch(samples[i].amplitude);


    samples2[i] = new Sampler(str(i+1)+"a.wav", 16, minim);
    samples2[i].patch(out2);
    println(str(i+1)+"a.wav");
    attack2.patch(samples2[i].attack);
    amp2.patch(samples2[i].amplitude);


    samples3[i] = new Sampler(str((i%4)+1)+"b.wav", 4, minim);
    samples3[i].patch(out3);
    println(str((i%4)+1)+"b.wav");
    attack3.patch(samples3[i].attack);
    amp3.patch(samples3[i].amplitude);

    samples4[i] = new Sampler(str((i%8)+1)+"d.wav", 16, minim);
    samples4[i].patch(out4);
    println(str((i%4)+1)+"cpu.wav");
    attack4.patch(samples4[i].attack);
    amp4.patch(samples4[i].amplitude);
  }


  video.loop();
  video.play();
  //background(0);
}

void draw() {

  //DRAW FRAME FROM VIDEO
  image(video, 0, 0);  

  //LOAD FRAME INTO OPENCV  
  opencv.loadImage(video);
  //COMPARE FRAME TO BACKGROUND FRAME  
  opencv.updateBackground();
  //APPLY THRESHOLD TO DATA
  opencv.threshold(thresholdValue);

  //THIS SMOOTHES OUT THE PIXEL DATA REMOVING ANY HOLES
  opencv.dilate();
  opencv.erode();

  noFill();
  stroke(255, 0, 0);
  strokeWeight(3);


  //Contour detection mechanism
  for (Contour contour : opencv.findContours ()) {


    //Find the bounding box to compare with the grid rectangles
    Rectangle cont = contour.getBoundingBox();
    if (cont.width*cont.height > bbSize) {
      //contour.draw();
      stroke(0, 0, 255);
      rect(cont.x, cont.y, cont.width, cont.height);

      //Approximate Centroid of contour - maybe use a better centroid finder!
      float centX = cont.x + 0.5*cont.width;
      float centY = cont.y + 0.5*cont.height;


      //Check rectangles if they contain contour centroids. TRIGGER SAMPLE IF TRUE
      for (int i = 0; i<numberX*numberY; i++) {
        float alpha = random(100, 255);
        float radius = random(15);
        noStroke();
        //  fill(random(255), alpha);

        if (grid[i%4][i/4].contains(centX, centY)) {
          samples[i].trigger();

          ellipse(centX, centY, radius, radius);

        }

        if (vibgrid[i%4][i/4].contains(centX, centY)) {
          samples2[i].trigger();
          rect(centX, centY, radius, radius);


          // samples[i].stop();
        }

        if (novaGrid[i%4][i/4].contains(centX, centY)) {
          samples3[i].trigger();
          triangle(centX, centY, centX+ radius, centY+radius, centX-radius, centY+radius);


          // samples[i].stop();
        }

        if (drumGrid[i%4][i/4].contains(centX, centY)) {
          samples4[i].trigger();
          ellipse(centX, centY, radius, radius);


          // samples[i].stop();
        }
      }
    }
  }
}

void movieEvent(Movie m) {
  m.read();
}

void stop() {
  super.stop();
  minim.stop();
}

