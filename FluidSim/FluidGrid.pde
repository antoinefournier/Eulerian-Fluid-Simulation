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

// Eulerian smoke simulation.
// The fuild is simulated inside of a grid. At each step the velocity and density of the fluid is updated.
//
// Papers, sources, thesis, documentation :
// - GPU Gems
// - GPU Gems 3
// - Stable Fluids - Jos Stam - SIGGRAPH 2000
// - Real-Time Fluid Dynamics for Games - Jos Stam - GDC 2003
// - Eulerian Smoke Simulation on the GPU - Nikolaos Verigakis - Thesis 2011
// - Real-Time Smoke Simulation - Eren Algan - Thesis 2010
// - Interactive Real-Time Smoke Rendering - Robert Larsson - Thesis 2010
// - Compressible Subsonic Flow on a Staggered Grid - Michael Patrick Bonner - Thesis 2002

class FluidGrid
{
  // Number of cell on each side of the grid
  int mSizeGrid;

  // Diffusion value of the fluid
  float mDiffusion;

  // Number of iteration fo the diffusion step
  int mFidelity;

  float[] mGravity;

  // Velocity field
  float[][] mCellVelocityX_Array2D;
  float[][] mCellVelocityY_Array2D;

  // Density of each cell
  float[][] mCellDensity_Array2D;
  
  // Sources used to add forces and density to the simulation
  float[][] mSourceDensity_Array2D;
  float[][] mSourceVelocityX_Array2D;
  float[][] mSourceVelocityY_Array2D;


  // Constructor.
  FluidGrid(int _sizeGrid, boolean _initWithRandomDensity, boolean _initWithForce, int _initForcePower)
  {
    mSizeGrid = _sizeGrid;

    mDiffusion = 5;
    mFidelity = 20;

    mGravity = new float[2];

    mCellVelocityX_Array2D   = new float[mSizeGrid + 2][mSizeGrid + 2];
    mCellVelocityY_Array2D   = new float[mSizeGrid + 2][mSizeGrid + 2];
    mCellDensity_Array2D     = new float[mSizeGrid + 2][mSizeGrid + 2];
    
    mSourceDensity_Array2D   = new float[mSizeGrid + 2][mSizeGrid + 2];
    mSourceVelocityX_Array2D = new float[mSizeGrid + 2][mSizeGrid + 2];
    mSourceVelocityY_Array2D = new float[mSizeGrid + 2][mSizeGrid + 2];
    
    // Initial system state
    for (int x = 1; x <= mSizeGrid; ++x)
    {
      for (int y = 1; y <= mSizeGrid; ++y)
      {
        if (_initWithRandomDensity)
          if (x > mSizeGrid * 0.2f && x < mSizeGrid * 0.8f &&
            y > mSizeGrid * 0.2f && y < mSizeGrid * 0.8f)
            mCellDensity_Array2D[x][y] = random(0.0f, 0.5f);
        
        if (_initWithForce)
          if (x > mSizeGrid * 0.3f && x < mSizeGrid * 0.4f &&
            y > mSizeGrid * 0.3f && y < mSizeGrid * 0.4f)
            mCellVelocityX_Array2D[x][y] = _initForcePower;
      }
    }
  }

  // Return the number of cell on one side of the grid.
  int getSizeGrid()
  {
    return mSizeGrid;
  }

  // Return the array of cell velocity.
  float[][] getVelocityX()
  {
    return mCellVelocityX_Array2D;
  }

  // Return the array of cell velocity.
  float[][] getVelocityY()
  {
    return mCellVelocityY_Array2D;
  }

  // Return the array of cell density.
  float[][] getDensity()
  {
    return mCellDensity_Array2D;
  }

  // Gravity force applied to the system
  void setGravity(float _x, float _y)
  {
    mGravity[0] = _x;
    mGravity[1] = _y;
  }

  // Gravity force applied to the system
  float[] getGravity()
  {
    return mGravity;
  }

  // Diffusion value of the fluid
  void setDiffusion(float _diffusion)
  {
    mDiffusion = _diffusion;
  }

  // Diffusion value of the fluid
  float getDiffusion()
  {
    return mDiffusion;
  }

  // Number of iteration of the linear solver.
  // Higher value means higher precision of the simulation.
  void setFidelity(int _fidelity)
  {
    mFidelity = _fidelity;
  }

  // Number of iteration of the linear solver.
  // Higher value means higher precision of the simulation.
  float getFidelity()
  {
    return mFidelity;
  }
  
  // Add a force and density to the simulation
  void addForceAndDensity(int _x, int _y, float _powerX, float _powerY, float _density)
  {
    // % of the cell affected
    float brushSize = 0.10f;
    
    // Add the forces and density to every cell next to the one given
    int size = (int)(mSizeGrid * brushSize * 0.5f);
    
    for (int i = -size; i < size; ++i)
    {
      for (int j = -size; j < size; ++j)
      {
        int posX = _x + i;
        int posY = _y + j;
        
        if (posX < 0 || posX > mSizeGrid || posY < 0 || posY > mSizeGrid)
          continue;
        
        int deltaX = (i < 0) ? -i : i;
        int deltaY = (j < 0) ? -j : j;
        
        if (deltaX + deltaY < size)
        {
          mSourceDensity_Array2D[posX][posY] += _density / (1 + deltaX + deltaY);
          mSourceVelocityX_Array2D[posX][posY] += _powerX / (1 + deltaX + deltaY);
          mSourceVelocityY_Array2D[posX][posY] += _powerY / (1 + deltaX + deltaY);
        }
      }
    }
  }

  // Update the fluid simulation
  void update(float _deltaTime)
  {
    updateVelocity(_deltaTime);
    updateDensity(_deltaTime);

    /*
    float sum = 0.0f;
     for (int x = 1; x <= mSizeGrid; ++x)
     for (int y = 1; y <= mSizeGrid; ++y)
     sum += mCellDensity_Array2D[x][y];
     print("Density: " + sum + "\n");
     */
  }

  void updateDensity(float _deltaTime)
  {
    float[][] tempDensity_Array2D = new float[mSizeGrid + 2][mSizeGrid + 2];
    float[][] t;
    
    // New fluid added
    addSource(mCellDensity_Array2D, mSourceDensity_Array2D, _deltaTime);

    // Diffusion of the fluid
    diffuse(0, tempDensity_Array2D, mCellDensity_Array2D, _deltaTime);

    // Switch arrays
    t = mCellDensity_Array2D;
    mCellDensity_Array2D = tempDensity_Array2D;
    tempDensity_Array2D = t;

    // Move the fuild along the velocity field
    advect(0, tempDensity_Array2D, mCellDensity_Array2D, mCellVelocityX_Array2D, mCellVelocityY_Array2D, _deltaTime);

    // Switch arrays
    t = mCellDensity_Array2D;
    mCellDensity_Array2D = tempDensity_Array2D;
    tempDensity_Array2D = t;
  }

  void updateVelocity(float _deltaTime)
  {
    float[][] tempVelocityX_Array2D = new float[mSizeGrid + 2][mSizeGrid + 2];
    float[][] tempVelocityY_Array2D = new float[mSizeGrid + 2][mSizeGrid + 2];
    float[][] t;

    // New forces added
    addSource(mCellVelocityX_Array2D, mSourceVelocityX_Array2D, _deltaTime);
    addSource(mCellVelocityY_Array2D, mSourceVelocityY_Array2D, _deltaTime);

    // Diffusion of the velocity
    diffuse(1, tempVelocityX_Array2D, mCellVelocityX_Array2D, _deltaTime);
    diffuse(2, tempVelocityY_Array2D, mCellVelocityY_Array2D, _deltaTime);

    // Switch arrays
    t = mCellVelocityX_Array2D;
    mCellVelocityX_Array2D = tempVelocityX_Array2D;
    tempVelocityX_Array2D = t;
    t = mCellVelocityY_Array2D;
    mCellVelocityY_Array2D = tempVelocityY_Array2D;
    tempVelocityY_Array2D = t;

    // Mass conservation of the velocity
    project(mCellVelocityX_Array2D, mCellVelocityY_Array2D, tempVelocityX_Array2D, tempVelocityY_Array2D);

    // Move the velocity field along itself
    advect(1, tempVelocityX_Array2D, mCellVelocityX_Array2D, mCellVelocityX_Array2D, mCellVelocityY_Array2D, _deltaTime);
    advect(2, tempVelocityY_Array2D, mCellVelocityY_Array2D, mCellVelocityX_Array2D, mCellVelocityY_Array2D, _deltaTime);

    // Switch arrays
    t = mCellVelocityX_Array2D;
    mCellVelocityX_Array2D = tempVelocityX_Array2D;
    tempVelocityX_Array2D = t;
    t = mCellVelocityY_Array2D;
    mCellVelocityY_Array2D = tempVelocityY_Array2D;
    tempVelocityY_Array2D = t;

    // Mass conservation of the velocity
    project(mCellVelocityX_Array2D, mCellVelocityY_Array2D, tempVelocityX_Array2D, tempVelocityY_Array2D);
  }

  // Add source of density or velocity
  void addSource(float[][] _x, float[][] _s, float _deltaTime)
  {
    for (int i = 0; i < mSizeGrid + 2 ; ++i)
      for (int j = 0; j < mSizeGrid + 2 ; ++j)
      {
        _x[i][j] += _deltaTime * _s[i][j];
        _s[i][j] -= _deltaTime * _s[i][j];
      }
  }

  // Stable method for the diffusion of the density.
  // Each cell exchange density with its neighbors.
  // Use an iterative method (a linear solver) to find wich density particle end up in each cell.
  void diffuse(int _type, float[][] _x, float[][] _x0, float _deltaTime)
  {
    float a = (mDiffusion / 100000.0f) * _deltaTime * mSizeGrid * mSizeGrid;

    for (int n = 0; n < mFidelity; ++n)
      for (int i = 1; i <= mSizeGrid; ++i)
        for (int j = 1; j <= mSizeGrid; ++j)
          _x[i][j] = (_x0[i][j] + a * (_x[i - 1][j] + _x[i + 1][j] + _x[i][j - 1] + _x[i][j + 1])) / (1 + 4 * a);

    setBondaries(_type, _x0);
  }

  // Move the density as if it was particles, we want to know which particle end up in the cell center.
  // Each particle carry a quantity of density given by an linear interpolation of the 4 closest cell in the density array.
  // A linear backtrack is used to find the particles which end up in the cell center following the cell velocity.
  void advect(int _type, float[][] _d, float[][] _d0, float[][] _u, float[][] _v, float _deltaTime)
  {
    int i0, j0, i1, j1;
    float x, y, s0, t0, s1, t1, dt0;
    dt0 = _deltaTime * mSizeGrid;

    for (int i = 1; i <= mSizeGrid; ++i)
    {
      for (int j = 1 ; j <= mSizeGrid; ++j)
      {
        // Find the previous location of the particle
        x = i - dt0 * _u[i][j];
        y = j - dt0 * _v[i][j];

        // Make sure we are not going out of bound
        if (x < 0.5) x = 0.5; 
        if (x > mSizeGrid + 0.5) x = mSizeGrid + 0.5;
        if (y < 0.5) y = 0.5; 
        if (y > mSizeGrid + 0.5) y = mSizeGrid + 0.5;

        // Position of the closest 4 cells
        i0 = (int)x; 
        i1 = i0 + 1;
        j0 = (int)y;
        j1 = j0 + 1;

        // Ratio of the linear interpolation
        s1 = x - i0;
        s0 = 1 - s1;
        t1 = y - j0;
        t0 = 1 - t1;

        // New density
        _d[i][j] = s0 * (t0 * _d0[i0][j0] + t1 * _d0[i0][j1]) + s1 * (t0 * _d0[i1][j0] + t1 * _d0[i1][j1]);
      }
    }

    setBondaries(_type, _d);
  }

  // Reinject forces to the velocity field in order to conserve the forces lost due to the approximation of the simulation
  void project(float[][] _u, float[][] _v, float[][] _p, float[][] _div)
  {
    float h = 1.0 / mSizeGrid;

    for (int i = 1; i <= mSizeGrid; ++i)
    {
      for (int j = 1; j <= mSizeGrid; ++j)
      {
        _div[i][j] = -0.5 * h * (_u[i + 1][j] - _u[i - 1][j]+ _v[i][j + 1] - _v[i][j - 1]);
        _p[i][j] = 0;
      }
    }

    setBondaries(0, _div);
    setBondaries(0, _p);

    for (int k = 0; k < mFidelity; ++k)
    {
      for (int i = 1; i <= mSizeGrid; ++i)
      {
        for (int j = 1; j <= mSizeGrid; ++j)
        {
          _p[i][j] = (_div[i][j] + _p[i - 1][j]+ _p[i + 1][j] + _p[i][j - 1] + _p[i][j + 1]) / 4;
        }
      }
      setBondaries(0, _p);
    }

    for (int i = 1; i <= mSizeGrid; ++i)
    {
      for (int j = 1; j <= mSizeGrid; ++j)
      {
        _u[i][j] -= 0.5 * (_p[i + 1][j] - _p[i - 1][j]) / h;
        _v[i][j] -= 0.5 * (_p[i][j + 1] - _p[i][j - 1]) / h;
      }
    }

    setBondaries(1, _u);
    setBondaries(2, _v);
  }

  // Keep the forces and density inside the box of the simulation
  void setBondaries(int _type, float[][] _x)
  {
    for (int i = 1; i <= mSizeGrid; ++i)
    {
      _x[0][i]             = (_type == 1) ? -_x[1][i] : _x[1][i];
      _x[mSizeGrid + 1][i] = (_type == 1) ? -_x[mSizeGrid][i] : _x[mSizeGrid][i];
      _x[i][0]             = (_type == 2) ? -_x[i][1] : _x[i][1];
      _x[i][mSizeGrid + 1] = (_type == 2) ? -_x[i][mSizeGrid] : _x[i][mSizeGrid];
    }

    _x[0][0]                         = 0.5 * (_x[1][0] + _x[0][1]);
    _x[0][mSizeGrid + 1]             = 0.5 * (_x[1][mSizeGrid + 1] + _x[0][mSizeGrid]);
    _x[mSizeGrid + 1][0]             = 0.5 * (_x[mSizeGrid][0] + _x[mSizeGrid + 1][1]);
    _x[mSizeGrid + 1][mSizeGrid + 1] = 0.5 * (_x[mSizeGrid][mSizeGrid + 1] + _x[mSizeGrid + 1][mSizeGrid]);
  }
}
