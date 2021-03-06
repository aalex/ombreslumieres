class Undo
{
  // Number of currently available undo and redo snapshots
  int undoSteps = 0;
  int redoSteps = 0;
  StackOfImages images;
 
  Undo(int levels, int images_width, int images_height)
  {
    this.images = new StackOfImages(levels, images_width, images_height);
  }
 
  public void takeSnapshot(PGraphics screen)
  {
    this.undoSteps = min(this.undoSteps + 1, this.images.amount - 1);
    // each time we draw we disable redo
    this.redoSteps = 0;
    this.images.next();
    this.images.capture(screen);
  }
  
  public void undo(PGraphics screen)
  {
    int LAST_UNDO_STEP = 1;  // used to be 0
    // but it was causing a blank grey image at the last undo level
    if (this.undoSteps > LAST_UNDO_STEP)
    {
      this.undoSteps --;
      this.redoSteps ++;
      this.images.prev();
      this.images.show(screen);
    }
  }
  
  public void redo(PGraphics screen)
  {
    if (this.redoSteps > 0)
    {
      this.undoSteps ++;
      this.redoSteps --;
      this.images.next();
      this.images.show(screen);
    }
  }
}