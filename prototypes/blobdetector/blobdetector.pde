/**
 * Blob detector.
 * Super Fast Blur v1.1 by Mario Klingemann <http://incubator.quasimondo.com>
 * Started from an example from the BlobDetection library for Processing.
 */

import processing.video.Capture;
import blobDetection.BlobDetection;
import blobDetection.Blob;
import blobDetection.EdgeVertex;

Capture cam;
BlobDetection theBlobDetection;
PImage img;
boolean newFrame = false;
int CAMERA_INDEX = 0;
final int VIDEO_OUTPUT_WIDTH = 640;
final int VIDEO_OUTPUT_HEIGHT = 480;
final int VIDEO_INPUT_WIDTH = 320;
final int VIDEO_INPUT_HEIGHT = 240;
final int VIDEO_INPUT_FPS = 30;
final int DEFAULT_CAMERA_INDEX = 59;
final float BLOB_BRIGHTNESS_THRESHOLD = 0.2f; // will detect bright areas whose luminosity if greater than this value
final String VIDEO_CAMERA_NAME_PATTERN = "/dev/video[0-9]*,size=320x240,fps=30"; // play station 3 eye (linux)

void settings()
{
  size(VIDEO_OUTPUT_WIDTH, VIDEO_OUTPUT_HEIGHT);
}

void setup()
{
  println("Guess video camera name...");
  String camera_name = guess_video_camera_name(VIDEO_CAMERA_NAME_PATTERN);
  println("create new catpure");
  cam = new Capture(this, VIDEO_INPUT_WIDTH, VIDEO_INPUT_HEIGHT, camera_name, VIDEO_INPUT_FPS);
  println("start capture " + cam);
  cam.start();
  println("capture started");
  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame);
  img = new PImage(VIDEO_INPUT_WIDTH, VIDEO_INPUT_HEIGHT); 
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(BLOB_BRIGHTNESS_THRESHOLD);
  // will detect bright areas whose luminosity > BLOB_BRIGHTNESS_THRESHOLD;
}

/**
 * For the name pattern, see http://docs.oracle.com/javase/6/docs/api/java/util/regex/Pattern.html
 */
String guess_video_camera_name(String name_pattern)
{
  //return "/dev/video0,size=320x240,fps=30";
  print("Listing caputre devices...");
  String[] cameras = Capture.list();
  println("Done listing devices.");
  String camera_name = "";
  int camera_index = DEFAULT_CAMERA_INDEX;
  
  if (cameras.length == 0)
  {
    println("There are no cameras available for capture.");
    exit();
  }
  else
  {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++)
    {
      println("Camera index: " + i + ", name: " + cameras[i]);
      if (match(cameras[i], name_pattern) != null)
      {
        camera_index = i;
      }
    }
    if (cameras.length <= camera_index)
    {
      camera_index = 0;
    }
    println("Choosing camera index: " + camera_index + ", name: " + cameras[camera_index]);
    camera_name = cameras[camera_index];
  }
  return camera_name;
}

/**
 * captureEvent()
 */
void captureEvent(Capture cam)
{
  //println("capture event!");
  cam.read();
  newFrame = true;
}

/**
 * draw()
 */
void draw()
{
  if (newFrame)
  {
    newFrame = false;
    image(cam, 0, 0, width, height);
    //println("copy image " + cam.width + "x" + cam.height + " to " + img.width + "x" + img.height);
    img.copy(cam, 0, 0, cam.width, cam.height, 0, 0, img.width, img.height);
    fastblur(img, 2);
    theBlobDetection.computeBlobs(img.pixels);
    drawBlobsAndEdges(true, true);
  }
}

/**
 * draw blobs and edges
 */
void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges)
{
  noFill();
  Blob b;
  EdgeVertex eA,eB;
  for (int n = 0; n < theBlobDetection.getBlobNb(); n++)
  {
    b = theBlobDetection.getBlob(n);
    if (b != null)
    {
      // Edges
      if (drawEdges)
      {
        strokeWeight(3);
        stroke(0, 255, 0);
        for (int m = 0; m < b.getEdgeNb(); m++)
        {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA != null && eB != null)
          {
            line(eA.x * width, eA.y * height, eB.x * width, eB.y * height);
          }
        }
      }
      // Blobs
      if (drawBlobs)
      {
        strokeWeight(1);
        stroke(255, 0, 0);
        rect(b.xMin * width, b.yMin * height, b.w * width, b.h * height);
      }
    }
  }
}

/**
* Super Fast Blur v1.1
* by Mario Klingemann 
* <http://incubator.quasimondo.com>
*/
void fastblur(PImage img, int radius)
{
  if (radius < 1)
  {
    return;
  }
  int w = img.width;
  int h = img.height;
  int wm = w - 1;
  int hm = h - 1;
  int wh = w * h;
  int div = radius + radius + 1;
  int r[] = new int[wh];
  int g[] = new int[wh];
  int b[] = new int[wh];
  int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
  int vmin[] = new int[max(w, h)];
  int vmax[] = new int[max(w, h)];
  int[] pix = img.pixels;
  int dv[] = new int[256 * div];
  for (i = 0; i < 256 * div; i++)
  {
    dv[i] = (i / div);
  }

  yw = yi = 0;

  for (y = 0; y < h; y++)
  {
    rsum = gsum = bsum = 0;
    for(i = -radius; i <= radius; i++)
    {
      p = pix[yi + min(wm, max(i, 0))];
      rsum += (p & 0xff0000) >> 16;
      gsum += (p & 0x00ff00) >> 8;
      bsum += p & 0x0000ff;
    }
    for (x=0; x < w; x++)
    {
      r[yi] = dv[rsum];
      g[yi] = dv[gsum];
      b[yi] = dv[bsum];

      if (y == 0)
      {
        vmin[x] = min(x + radius + 1, wm);
        vmax[x] = max(x - radius, 0);
      }
      p1 = pix[yw + vmin[x]];
      p2 = pix[yw + vmax[x]];

      rsum += ((p1 & 0xff0000) - (p2 & 0xff0000)) >> 16;
      gsum += ((p1 & 0x00ff00) - (p2 & 0x00ff00)) >> 8;
      bsum += (p1 & 0x0000ff) - (p2 & 0x0000ff);
      yi++;
    }
    yw += w;
  }

  for (x = 0; x < w; x++)
  {
    rsum = gsum = bsum = 0;
    yp = -radius * w;
    for(i = -radius; i <= radius; i++)
    {
      yi = max(0, yp) + x;
      rsum += r[yi];
      gsum += g[yi];
      bsum += b[yi];
      yp += w;
    }
    yi = x;
    for (y = 0; y < h; y++)
    {
      pix[yi] = 0xff000000 | (dv[rsum] << 16) | (dv[gsum] << 8) | dv[bsum];
      if(x==0)
      {
        vmin[y] = min(y + radius + 1, hm) * w;
        vmax[y] = max(y - radius, 0) * w;
      }
      p1 = x + vmin[y];
      p2 = x + vmax[y];
      rsum += r[p1] - r[p2];
      gsum += g[p1] - g[p2];
      bsum += b[p1] - b[p2];
      yi += w;
    }
  }
}