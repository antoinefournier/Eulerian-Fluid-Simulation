/*
The MIT License (MIT)

Copyright (c) 2014-2018 Fournier Antoine - https://github.com/antoinefournier

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Manage the drawing of one FluidGrid

class FluidGridVisualizer
{
  // Reference to the represented FluidGrid
  FluidGrid mFluidGrid;

  // Position of the grid on the screen in pixel
  int mPositionX;
  int mPositionY;

  // Size of one cell in pixel
  int mCellSize;

  // Size of the grid in pixel
  int mPixelSizeX;
  int mPixelSizeY;

  // Is a square drawn for each cell ?
  boolean mDrawCellGrid;

  // Is a representation of the velocity vector drawn for each cell ?
  boolean mDrawVelocityField;

  // Is the fluid density drawn ?
  boolean mDrawDensity;

  // Brightness of the density rendering
  int mDensityBrightness;


  // Constructor
  //
  // _fluidGrid : FluidGrid to draw.
  // _posX : Position in pixel of the left border of the grid.
  // _posY : Position in pixel of the top border of the grid.
  // _sizeX : Size in pixel of one cell of the grid.
  FluidGridVisualizer(FluidGrid _fluidGrid, int _posX, int _posY, int _cellSize)
  {
    mFluidGrid = _fluidGrid;

    mPositionX = _posX;
    mPositionY = _posY;

    mCellSize = _cellSize;
    if (mCellSize < 1)
      mCellSize = 1;

    mPixelSizeX = mFluidGrid.getSizeGrid() * mCellSize;
    mPixelSizeY = mFluidGrid.getSizeGrid() * mCellSize;

    mDrawCellGrid       = false;
    mDrawVelocityField  = false;
    mDrawDensity        = true;
  }

  // Change the brightness of the density
  void setDensityBrightness(int _value)
  {
    if (_value < 0)
      _value = 0;
    if (_value > 750)
      _value = 750;

    mDensityBrightness = _value;
  }

  // Indicate if each cell of the FluidGrid is represented by a square.
  void drawCellGrid(boolean _drawCellGrid)
  {
    mDrawCellGrid = _drawCellGrid;
  }

  // Indicate if each cell of the FluidGrid is represented by a suqare.
  boolean drawCellGrid()
  {
    return mDrawCellGrid;
  }

  // Indicate if the vector of the velocity of each cell of the FluidGrid is drawn.
  void drawVelocityField(boolean _drawVelocityField)
  {
    mDrawVelocityField = _drawVelocityField;
  }

  // Indicate if the vector of the velocity of each cell of the FluidGrid is drawn.
  boolean drawVelocityField()
  {
    return mDrawVelocityField;
  }

  // Indicate if the fluid density is drawn
  void drawDensity(boolean _drawDensity)
  {
    mDrawDensity = _drawDensity;
  }

  // Indicate if the fluid density is drawn
  boolean drawDensity()
  {
    return mDrawDensity;
  }

  // Indicate if the given point is inside the simulation box
  boolean isInside(int _x, int _y)
  {
    if (_x >= mPositionX && _x <= (mPositionX + mCellSize * mFluidGrid.getSizeGrid()) &&
      _y >= mPositionY && _y <= (mPositionY + mCellSize * mFluidGrid.getSizeGrid()))
      return true;
    return false;
  }

  // Return the cell at the given position
  // If there is no cell, [-1, -1] is returned
  int[] getCell(int _x, int _y)
  {
    int[] cell = new int[2];

    if (isInside(_x, _y) == false)
    {
      cell[0] = -1;
      cell[1] = -1;
      return cell;
    }

    cell[0] = (int)((_x - mPositionX) / mCellSize) + 1;
    cell[1] = (int)((_y - mPositionY) / mCellSize) + 1;

    if (cell[0] < 1 || cell[0] > mFluidGrid.getSizeGrid() ||
      cell[1] < 1 || cell[1] > mFluidGrid.getSizeGrid())
    {
      cell[0] = -1;
      cell[1] = -1;
    }

    return cell;
  }

  // Draw the grid on the screen
  void render()
  {
    int sizeGrid = mFluidGrid.getSizeGrid();

    // Draw the density
    if (mDrawDensity)
    {
      float[][] densityArray = mFluidGrid.getDensity();

      for (int x = 0; x < sizeGrid; ++x)
      {
        for (int y = 0; y < sizeGrid; ++y)
        {
          int densityColor = (int)((255 + mDensityBrightness) * densityArray[x + 1][y + 1]);
          if (densityColor > 255)
            densityColor = 255;

          // Draw the grid
          if (mDrawCellGrid)
            stroke(0);
          else
            stroke(255 - densityColor);

          fill(255 - densityColor);

          rect(mPositionX + x * mCellSize, mPositionY + y * mCellSize, mCellSize, mCellSize);
        }
      }
    }

    // Draw the grid if the density is not drawn
    if (!mDrawDensity && mDrawCellGrid)
    {
      stroke(0);
      fill(255);

      for (int x = 0; x < sizeGrid; ++x)
        line(mPositionX + x * mCellSize, mPositionY, mPositionX + x * mCellSize, mPositionY + mPixelSizeY);
      line(mPositionX + mPixelSizeX, mPositionY, mPositionX + mPixelSizeX, mPositionY + mPixelSizeY);

      for (int y = 0; y < sizeGrid; ++y)
        line(mPositionX, mPositionY + y * mCellSize, mPositionX + mPixelSizeX, mPositionY + y * mCellSize);
      line(mPositionX, mPositionY + mPixelSizeY, mPositionX + mPixelSizeX, mPositionY + mPixelSizeY);
    }

    // Draw the velocity vectors
    if (mDrawVelocityField)
    {
      stroke(255, 0, 0);
      fill(255);

      float[][] velocityXArray = mFluidGrid.getVelocityX();
      float[][] velocityYArray = mFluidGrid.getVelocityY();

      for (int x = 0; x < sizeGrid; ++x)
      {
        for (int y = 0; y < sizeGrid; ++y)
        {
          float velocity[] = new float[2];
          velocity[0] = velocityXArray[x + 1][y + 1] * 10;
          velocity[1] = velocityYArray[x + 1][y + 1] * 10;

          if (velocity[0] == 0 && velocity[1] == 0)
            continue;

          int originX = mPositionX + x * mCellSize + (int)(mCellSize * 0.5f);
          int originY = mPositionY + y * mCellSize + (int)(mCellSize * 0.5f);
          int destX = originX + (int)(velocity[0] * mCellSize * 0.5f) * 2;
          int destY = originY + (int)(velocity[1] * mCellSize * 0.5f) * 2;

          if (originX == destX && originY == destY)
            continue;

          line(originX, originY, destX, destY);
        }
      }
    }

    // Draw the border of the box
    stroke(255, 0, 0);
    line(mPositionX, mPositionY, mPositionX + sizeGrid * mCellSize, mPositionY);
    line(mPositionX + sizeGrid * mCellSize, mPositionY, mPositionX + sizeGrid * mCellSize, mPositionY + sizeGrid * mCellSize);
    line(mPositionX + sizeGrid * mCellSize, mPositionY + sizeGrid * mCellSize, mPositionX, mPositionY + sizeGrid * mCellSize);
    line(mPositionX, mPositionY + sizeGrid * mCellSize, mPositionX, mPositionY);
  }
}
