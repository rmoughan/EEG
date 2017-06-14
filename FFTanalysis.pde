import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import java.util.*;

int windowLength = 800;
int windowHeight = 500;

Float[] freqArray = null;
String freqString;
final int waveCenter = 15;
final int waveBandwidth = 5;
final float alphaLow = 7.5;
final float alphaHigh = 12.5;
final float betaLow = 12.6;
final float betaHigh = 25.0;

boolean setThreshold = true;
Float[] freqThreshArray;
Float[] ampThreshArray;
int timedAverage = 50; //deprecated in current version of code
Timer timer = new Timer();

Minim minim;
AudioInput audioIn;
FFT fft;
BandPass waveFilter;
LowPassFS lowFilter;
HighPassSP highFilter;

void setup(){
   //Runs on initial load, think of ViewDidLoad() in Swift
  
  size(800,500);
  background(0);
  stroke(255);
 
  minim = new Minim(this);
  minim.debugOn();
  
  audioIn = minim.getLineIn(Minim.MONO, 32768, 48000);
  lowFilter = new LowPassFS(60, audioIn.sampleRate());
  audioIn.addEffect(lowFilter);
  highFilter = new HighPassSP(6.5, audioIn.sampleRate());
  audioIn.addEffect(highFilter);
  waveFilter = new BandPass(waveCenter, waveBandwidth, audioIn.bufferSize());
  audioIn.addEffect(waveFilter); // BE CAREFUL, addEffect() IS DEPRECATED
  
  fft = new FFT(audioIn.bufferSize(), audioIn.sampleRate());
  fft.window(FFT.HAMMING); //This is a big point of contention and may need to be tested with quite a few different windowing techniques. Change this if data needs improvement
}

void draw() {
     
  background(0);
  fft.forward(audioIn.mix);
  drawTimeDomain();
  line(0, 100, width, 100);
  drawFreqDomain();
  
  textSize(24);
  fill(100, 110, 255);
  text("Frequencies (Hz):", width-250, height-375);

  trackHighestFreqs();
  freqString = "";
  for (int i = 0; i<freqArray.length; i++) {
    String string = String.format("%.2f", freqArray[i]);
    freqString += string + "   ";
  }
     
  textSize(16);
  text(freqString, width-250, height-350, 200, 100);
 
  //println("alpha: " + fft.calcAvg(alphaLow, alphaHigh) + "beta: " fft.calcAvg(betaLow, betaHigh));
  
  if (keyPressed == true) {
    if (setThreshold == true) {
      //timer.scheduleAtFixedRate(task, 0, 100);
      setFreqThreshold();
      println("THRESHOLD OUTPUT");
      for (int i = 0; i<ampThreshArray.length; i++) {
        println("Freq: " + freqThreshArray[i] + " Amp: " + ampThreshArray[i]);
      }
      setThreshold = false;
    }
  }
  scan();
}

void drawTimeDomain() {
 
  for (int i = 0; i < width; i++) {
    //Blue Streak: 
    stroke(i/3, i/3, i);
    //pink-violet-white: stroke(i*2,i/2,i);
    line(i, 50 + audioIn.left.get(i*round(audioIn.bufferSize()/windowLength))*100, 
         i+1, 50 + audioIn.left.get((i+1)*round(audioIn.bufferSize()/windowLength))*100);
  }
}

void drawFreqDomain() {
 
  for (int i = 0; i < fft.specSize(); i++) {
   stroke(i, (255-i)/2, 2*(255-i));
   line(i, height, i, height - fft.getBand(i));
   }
}

void trackHighestFreqs() {

  freqArray = null;
  float ampSum = 0;
  for (int i = 0; i < fft.specSize(); i++) {
      ampSum += fft.getBand(i);
  }
  float ampAverage = ampSum/(60/fft.getBandWidth());
  
  ArrayList<Integer> indexList = new ArrayList<Integer>();
  for (int i = 0; i < fft.specSize(); i++)  {
    if (fft.getBand(i) > ampAverage && fft.getBand(i) > 2) {
      indexList.add(i);
    }
  }
 Integer[] indexArray = indexList.toArray(new Integer[indexList.size()]);
 
 ArrayList<Float> freqList = new ArrayList<Float>();
 for (int i = 0; i < indexArray.length; i++) {
   freqList.add(fft.indexToFreq(indexArray[i]));
 }
 
 freqArray = freqList.toArray(new Float[freqList.size()]);
}


//Not yet working
void setFreqThreshold() {
  //Start with simplest possible use case, take snapshot of current freqs
  freqThreshArray = freqArray; //this should later be changed after taking into account X amount of freqArrays in timer
  
  ArrayList<Float> ampThreshList = new ArrayList<Float>();
  for (int i = 0; i<freqThreshArray.length; i++) {
    ampThreshList.add(fft.getFreq(freqThreshArray[i]));
  }
  
  ampThreshArray = ampThreshList.toArray(new Float[ampThreshList.size()]);
}

TimerTask task = new TimerTask() {
   public void run() {
     //body of the code
   }  
};

void scan() {
  if (setThreshold == false) {
    //already have data from freqThreshArray and ampThreshArray
    //use tHF() and segregate sFT() from tracking the highest amplitudes
    
  }  
}











/* JUNK CODE
FROM original sFT() {

    trackHighestFreqs();
    ArrayList<Float> freqList = new ArrayList<Float>();
    for (int i = 0; i<freqArray.length; i++) {
       freqList.add(freqArray[i]); 
    }  
    
    //setup list for average amplitudes
    ArrayList<Float> avgList = new ArrayList<Float>();
    for (int i=0; i<=30; i++) {
      avgList.add(0.0);
    }

    //On to testing this fun iterations of loops...
    ListIterator itr = avgList.listIterator();
    int fLSize = freqList.size();
    for(int i = 0; i<timedAverage; i++) {
      trackHighestFreqs();
      for (int j = 0; j<freqList.size(); j++) {
        for (int k =0; k<freqArray.length; k++) {
          //Start by making sure k is iterating correctly here
          if (freqList.contains(freqArray[k])) { 
            Float element = (Float) itr.next();
            println(element);
            itr.set((element + fft.getFreq(freqArray[k]))/(timedAverage*fLSize));
          } else {
          freqList.remove(j); 
          //TESTING println("check " + j);
          }
          itr.previous();
        }
        
      }
    }
    
    while(itr.hasNext()) {
      Float element = (Float) itr.next();
      if (element == 0.0) {
        itr.remove();
      }
    } 
    
    for (int i = 0; i<freqList.size(); i++) {
     if (freqList.get(i) > 30 || freqList.get(i) < 7) {
       freqList.remove(i);
     }  
    }
    freqThreshArray = freqList.toArray(new Float[freqList.size()]);
    ampThreshArray = avgList.toArray(new Float[avgList.size()]);
    
    for (int i=0; i<ampThreshArray.length; i++) {
      println(ampThreshArray[i]);
    }
    
    //setThreshold = false;
    println("Threshold set at...");
} //compare freqList against X amount of freqArrays to help get rid of noise. Remove any values over 30 and then get amplitudes of remaining
 */